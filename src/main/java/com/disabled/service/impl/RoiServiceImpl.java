package com.disabled.service.impl;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import com.disabled.mapper.DeviceListMapper;
import com.disabled.mapper.RoiMapper;
import com.disabled.roi.RoiActor;
import com.disabled.roi.RoiCodec;
import com.disabled.roi.RoiModuleCClient;
import com.disabled.roi.RoiModuleCClient.Failure;
import com.disabled.roi.RoiModuleCClient.Reply;
import com.disabled.roi.RoiPaths;
import com.disabled.roi.RoiResult;
import com.disabled.roi.RoiValidator;
import com.disabled.service.RoiService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * 웹 ROI 설정 서비스 구현(34번 작업계획서).
 *
 * 참고 — 이 프로젝트에는 트랜잭션 매니저가 설정되어 있지 않다(다른 서비스의 @Transactional 은 동작하지 않는다).
 * 그래서 여기서도 @Transactional 에 기대지 않고, 각 이력 행을 한 문장(INSERT/UPDATE)으로 기록하며
 * "PENDING 일 때만 확정" 조건과 장치별 JVM 락(SYNC 중복 방지)으로 일관성을 지킨다. WAS 를 여러 대로 늘리면
 * SYNC 중복 방지는 DB 쪽(유니크 키 등)으로 옮겨야 한다.
 */
@Service
public class RoiServiceImpl implements RoiService {
	private static final Logger logger = LoggerFactory.getLogger(RoiServiceImpl.class);

	private static final Pattern HASH = Pattern.compile("^[0-9a-f]{64}$");
	private static final Pattern DEVICE_PROBLEM = Pattern.compile("^(Cam[12])/(\\w*)\\[(\\d+)\\]:(\\w+)$");
	/** 시간 초과 뒤 확인되지 않은 PENDING 을 FAIL 로 정리하는 기준(분). */
	private static final int PENDING_EXPIRE_MIN = 30;
	private static final int SNAPSHOT_W = RoiValidator.WIDTH;
	private static final int SNAPSHOT_H = RoiValidator.HEIGHT;

	private final RoiMapper roiMapper;
	private final DeviceListMapper deviceMapper;
	private final RoiModuleCClient client;
	private final boolean includeName;
	private final String mediaBaseConfig;
	private final String imageDecPath;
	private final ConcurrentHashMap<Integer, Object> deviceLocks = new ConcurrentHashMap<>();
	private final SecureRandom random = new SecureRandom();

	public RoiServiceImpl(RoiMapper roiMapper, DeviceListMapper deviceMapper, RoiModuleCClient client,
			@Value("${roi.file.include-name:true}") boolean includeName,
			@Value("${roi.media.base:}") String mediaBaseConfig,
			@Value("${image.dec.path:}") String imageDecPath) {
		this.roiMapper = roiMapper;
		this.deviceMapper = deviceMapper;
		this.client = client;
		this.includeName = includeName;
		this.mediaBaseConfig = mediaBaseConfig == null ? "" : mediaBaseConfig.trim();
		this.imageDecPath = imageDecPath == null ? "" : imageDecPath.trim();
	}

	// ------------------------------------------------------------------ 공통

	private static final class Device {
		final int id;
		final String name;
		final String serial;

		Device(int id, String name, String serial) {
			this.id = id;
			this.name = name;
			this.serial = serial;
		}
	}

	/** 등록된 장비를 읽는다. 없으면 null(호출부가 404). 시리얼 형식이 아니면 IllegalArgumentException. */
	private Device findDevice(int deviceId) {
		if (deviceId <= 0) return null;
		Map<String, Object> row;
		try {
			row = deviceMapper.getOneDeviceInfo(deviceId);
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getOneDeviceInfo() : ", e);
			throw e;
		}
		if (row == null) return null;
		String serial = String.valueOf(row.get("dv_serial_number"));
		if (!RoiPaths.isSerial(serial)) throw new IllegalArgumentException("장비 시리얼을 확인하십시오");
		return new Device(deviceId, String.valueOf(row.get("dv_name")), serial);
	}

	private RoiResult deviceError(IllegalArgumentException e) {
		return RoiResult.error(422, "BAD_DEVICE", e.getMessage());
	}

	private static RoiResult noDevice() {
		return RoiResult.error(404, "NO_DEVICE", "장비를 찾을 수 없습니다.");
	}

	private Object lockFor(int deviceId) {
		return deviceLocks.computeIfAbsent(deviceId, k -> new Object());
	}

	private static String str(Map<String, Object> row, String key) {
		Object v = row.get(key);
		return v == null ? null : String.valueOf(v);
	}

	private static long num(Map<String, Object> row, String key) {
		Object v = row.get(key);
		return v instanceof Number ? ((Number) v).longValue() : Long.parseLong(String.valueOf(v));
	}

	private static String clip(String s, int max) {
		if (s == null) return null;
		return s.length() <= max ? s : s.substring(0, max);
	}

	private static Map<String, Object> emptyRois() {
		Map<String, Object> rois = new LinkedHashMap<>();
		for (String cam : RoiValidator.CAMERAS) {
			Map<String, Object> c = new LinkedHashMap<>();
			for (String kind : RoiValidator.KINDS) c.put(kind, new ArrayList<Object>());
			rois.put(cam, c);
		}
		return rois;
	}

	private static List<Map<String, Object>> problemList(List<RoiValidator.Problem> problems) {
		List<Map<String, Object>> out = new ArrayList<>();
		for (RoiValidator.Problem p : problems) {
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("camera", p.camera);
			m.put("kind", p.kind);
			m.put("index", p.index);
			m.put("code", p.code);
			out.add(m);
		}
		return out;
	}

	/** module_d 가 문자열로 돌려준 문제("Cam1/parking[0]:OVERLAP")를 화면과 같은 객체 형태로 바꾼다. */
	private static List<Map<String, Object>> deviceProblems(JsonNode problems) {
		List<Map<String, Object>> out = new ArrayList<>();
		if (problems == null || !problems.isArray()) return out;
		for (JsonNode p : problems) {
			Map<String, Object> m = new LinkedHashMap<>();
			Matcher mt = DEVICE_PROBLEM.matcher(p.asText(""));
			if (mt.matches()) {
				m.put("camera", mt.group(1));
				m.put("kind", mt.group(2));
				m.put("index", Integer.parseInt(mt.group(3)));
				m.put("code", mt.group(4));
			} else {
				m.put("code", clip(p.asText(""), 60));
			}
			out.add(m);
		}
		return out;
	}

	/** module_c 응답이 성공이 아닐 때 화면으로 보낼 오류로 바꾼다. 주소·내부 메시지는 싣지 않는다. */
	private static RoiResult relayError(Reply r) {
		if (r.failure == Failure.TIMEOUT) return RoiResult.error(504, "TIMEOUT", "장비 응답 시간이 초과되었습니다.");
		if (r.failure == Failure.UNREACHABLE) return RoiResult.error(503, "UNREACHABLE", "관제 서버와 통신할 수 없습니다.");
		if (r.failure == Failure.NOT_CONFIGURED) return RoiResult.error(503, "NOT_CONFIGURED", "ROI 연동 설정이 없습니다. 관리자에게 문의하십시오.");
		String code = r.body == null ? "" : r.body.path("code").asText("");
		String msg = r.body == null ? "" : r.body.path("msg").asText("");
		switch (r.status) {
		case 400:
			return withDetail(RoiResult.error(400, code.isEmpty() ? "INVALID" : code, msg.isEmpty() ? "ROI 검증에 실패했습니다." : msg), r.body);
		case 401:
			return RoiResult.error(503, "NOT_CONFIGURED", "ROI 연동 인증 설정을 확인하십시오.");
		case 404:
			return RoiResult.error(404, "NO_DEVICE", "등록된 장비를 찾을 수 없습니다.");
		case 409:
			return withDetail(RoiResult.error(409, code.isEmpty() ? "CONFLICT" : code, msg.isEmpty() ? "다른 곳에서 먼저 수정되었습니다." : msg), r.body);
		case 422:
			return RoiResult.error(422, code.isEmpty() ? "UNPROCESSABLE" : code, msg.isEmpty() ? "장비 정보를 확인하십시오." : msg);
		case 503:
			return RoiResult.error(503, code.isEmpty() ? "UNREACHABLE" : code, msg.isEmpty() ? "장비와 통신할 수 없습니다." : msg);
		case 504:
			return RoiResult.error(504, "TIMEOUT", "장비 응답 시간이 초과되었습니다.");
		default:
			return RoiResult.error(502, "DEVICE_ERROR", "장비가 요청을 처리하지 못했습니다.");
		}
	}

	private static RoiResult withDetail(RoiResult res, JsonNode body) {
		if (body == null) return res;
		if (body.has("problems")) res.with("problems", deviceProblems(body.get("problems")));
		String cur = body.path("currentHash").asText("");
		if (!cur.isEmpty() && HASH.matcher(cur).matches()) res.with("currentHash", cur);
		return res;
	}

	// ------------------------------------------------------------------ 조회

	@Override
	public RoiResult deviceInfo(int deviceId) {
		try {
			Device d = findDevice(deviceId);
			if (d == null) return noDevice();
			Map<String, Object> body = new LinkedHashMap<>();
			body.put("deviceId", d.id);
			body.put("name", d.name);
			body.put("serial", d.serial);
			return RoiResult.ok(body);
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
	}

	@Override
	public RoiResult load(int deviceId) {
		Device d;
		try {
			d = findDevice(deviceId);
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
		if (d == null) return noDevice();

		Map<String, Object> payload = new HashMap<>();
		payload.put("serial", d.serial);
		Reply reply = client.post("/ROI_get", payload);
		if (!reply.ok()) return relayError(reply);

		boolean exists = reply.body.path("exists").asBoolean(false);
		String text = reply.body.path("roisText").asText("");
		String hash = reply.body.path("hash").asText("");

		Map<String, Object> body = new LinkedHashMap<>();
		body.put("device", deviceBrief(d));
		if (!exists) {
			// 장비에 ROI 파일이 아직 없다: 빈 상태에서 시작하고 baseHash 는 빈 문자열로 저장한다.
			body.put("exists", false);
			body.put("hash", "");
			body.put("rois", emptyRois());
			body.put("problems", new ArrayList<Object>());
			body.put("formatError", false);
			body.put("drift", null);
			return RoiResult.ok(body);
		}
		if (!HASH.matcher(hash).matches() || !hash.equals(RoiCodec.sha256Hex(text))) {
			logger.warn("[ROI] 장비가 돌려준 해시와 내용이 일치하지 않습니다 (deviceId={})", deviceId);
			return RoiResult.error(502, "HASH_INCONSISTENT", "장비가 돌려준 ROI 내용과 해시가 일치하지 않습니다.");
		}

		resolvePending(d.id, hash);

		Map<String, Object> latest = roiMapper.selectLatestSuccess(d.id);
		Long driftRhId = null;
		if (latest == null || !hash.equals(str(latest, "rh_roi_hash"))) {
			synchronized (lockFor(d.id)) {
				// 락 안에서 다시 확인 — 동시에 연 다른 사용자가 이미 같은 SYNC 를 남겼을 수 있다.
				Map<String, Object> again = roiMapper.selectLatestSuccess(d.id);
				if (again == null || !hash.equals(str(again, "rh_roi_hash"))) {
					Map<String, String> prevNames = again == null ? new HashMap<>() : RoiCodec.readNames(str(again, "rh_meta_json"));
					ObjectNode parsed = RoiCodec.lenientRead(text, prevNames);
					Map<String, Object> p = new HashMap<>();
					p.put("dvId", d.id);
					p.put("roiJson", text);
					p.put("roiHash", hash);
					p.put("metaJson", parsed == null ? null : namesMeta(parsed));
					roiMapper.insertSyncHistory(p);
					driftRhId = ((Number) p.get("rhId")).longValue();
					logger.info("[ROI] 장비 값이 DB 와 달라 SYNC 이력을 남겼습니다 (deviceId={}, rhId={})", d.id, driftRhId);
				}
				latest = again;
			}
		}
		Map<String, String> names = latest == null ? new HashMap<>() : RoiCodec.readNames(str(latest, "rh_meta_json"));
		ObjectNode rois = RoiCodec.lenientRead(text, names);

		boolean formatError = rois == null;
		List<Map<String, Object>> problems = new ArrayList<>();
		if (!formatError) {
			try {
				problems = problemList(RoiValidator.validate(rois));
			} catch (RoiValidator.FormatException e) {
				formatError = true;
			}
		}
		body.put("exists", true);
		body.put("hash", hash);
		// 장비 파일을 해석할 수 없으면 빈 상태를 보여 주되 해시는 유지해, 저장하면 그 파일을 덮어쓰게 한다(화면이 경고).
		body.put("rois", formatError ? emptyRois() : rois);
		body.put("problems", problems);
		body.put("formatError", formatError);
		if (driftRhId != null) {
			Map<String, Object> drift = new LinkedHashMap<>();
			drift.put("detected", true);
			drift.put("rhId", driftRhId);
			body.put("drift", drift);
		} else {
			body.put("drift", null);
		}
		return RoiResult.ok(body);
	}

	private static Map<String, Object> deviceBrief(Device d) {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("deviceId", d.id);
		m.put("name", d.name);
		m.put("serial", d.serial);
		return m;
	}

	/** 화면용 ROI 의 도형 이름 맵을 rh_meta_json 형식으로. */
	private static String namesMeta(ObjectNode rois) {
		ObjectNode names = RoiCodec.mapper().createObjectNode();
		for (String cam : RoiValidator.CAMERAS) {
			for (String kind : RoiValidator.KINDS) {
				for (JsonNode s : rois.path(cam).path(kind)) {
					String id = s.path("id").asText("");
					String name = s.path("name").asText("");
					if (!id.isEmpty() && !name.isEmpty()) names.put(id, name);
				}
			}
		}
		ObjectNode meta = RoiCodec.mapper().createObjectNode();
		meta.set("names", names);
		return meta.toString();
	}

	/**
	 * 시간 초과로 PENDING 이 남은 이력을 장비 해시로 정리한다: 해시가 같으면 SUCCESS(적용되었음),
	 * 오래되었는데 다르면 FAIL. 사용자가 roiCheck 를 하지 않고 떠난 경우를 위한 것이다.
	 * 이 경로에서는 기준 스냅샷을 만들지 않는다(편집 중이던 임시 파일을 알 수 없다).
	 */
	private void resolvePending(int dvId, String deviceHash) {
		for (Map<String, Object> row : roiMapper.selectPending(dvId)) {
			long rhId = num(row, "rh_id");
			if (deviceHash.equals(str(row, "rh_roi_hash"))) {
				finish(rhId, "SUCCESS", null, null);
			} else if (num(row, "age_min") >= PENDING_EXPIRE_MIN) {
				finish(rhId, "FAIL", 504, "시간 초과 후 장비에 적용된 것을 확인하지 못했습니다");
			}
		}
	}

	private int finish(long rhId, String status, Integer failCode, String failMsg) {
		Map<String, Object> p = new HashMap<>();
		p.put("rhId", rhId);
		p.put("status", status);
		p.put("failCode", failCode);
		p.put("failMsg", clip(failMsg, 200));
		return roiMapper.updateHistoryResult(p);
	}

	// ------------------------------------------------------------------ 스냅샷

	@Override
	public RoiResult snapshot(int deviceId, RoiActor actor) {
		Device d;
		try {
			d = findDevice(deviceId);
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
		if (d == null) return noDevice();
		Reply reply = requestSnapshot(d.serial, actor);
		if (!reply.ok()) return relayError(reply);
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("width", reply.body.path("width").asInt(SNAPSHOT_W));
		body.put("height", reply.body.path("height").asInt(SNAPSHOT_H));
		body.put("takenAt", reply.body.path("takenAt").asText(""));
		body.put("ts", System.currentTimeMillis());
		return RoiResult.ok(body);
	}

	private Reply requestSnapshot(String serial, RoiActor actor) {
		Map<String, Object> payload = new HashMap<>();
		payload.put("serial", serial);
		payload.put("account", actor.loginId);
		return client.post("/ROI_snapshot", payload);
	}

	/** 공유 미디어 기준 폴더. 설정(roi.media.base)이 없으면 image.dec.path 의 부모 폴더(module_c 의 FILE_UPLOAD_PATH 와 같아야 함). */
	private Path mediaBase() {
		String configured = !mediaBaseConfig.isEmpty() ? mediaBaseConfig
				: (!imageDecPath.isEmpty() && RoiPaths.basePath(imageDecPath).getParent() != null
						? RoiPaths.basePath(imageDecPath).getParent().toString() : "");
		if (configured.isEmpty()) return null;
		Path base = RoiPaths.basePath(configured);
		return Files.isDirectory(base) ? base : null;
	}

	@Override
	public Path tempSnapshot(int deviceId, String camera, RoiActor actor) {
		if (!RoiPaths.isCamera(camera)) return null;
		try {
			Device d = findDevice(deviceId);
			Path base = mediaBase();
			if (d == null || base == null) return null;
			Path p = RoiPaths.resolveUnder(base, RoiPaths.tempRelative(actor.loginId, d.serial, camera));
			return Files.isRegularFile(p) ? p : null;
		} catch (IOException | IllegalArgumentException e) {
			return null;
		}
	}

	@Override
	public Path baselineSnapshot(long rsId) {
		if (rsId <= 0) return null;
		Map<String, Object> row = roiMapper.selectSnapshotById(rsId);
		if (row == null) return null;
		String rel = str(row, "rs_file_path");
		if (!RoiPaths.isBaselineRelative(rel)) {
			logger.warn("[ROI] 기준 스냅샷 경로가 규칙에 맞지 않아 무시합니다 (rsId={})", rsId);
			return null;
		}
		Path base = mediaBase();
		if (base == null) return null;
		try {
			Path p = RoiPaths.resolveUnder(base, rel);
			return Files.isRegularFile(p) ? p : null;
		} catch (IOException e) {
			return null;
		}
	}

	/** 1920x1080 JPEG 인지 헤더만 읽어 확인한다. 아니면 null. */
	private static int[] readJpegSize(Path file) {
		try (ImageInputStream in = ImageIO.createImageInputStream(file.toFile())) {
			if (in == null) return null;
			Iterator<ImageReader> it = ImageIO.getImageReaders(in);
			if (!it.hasNext()) return null;
			ImageReader reader = it.next();
			try {
				if (!"JPEG".equalsIgnoreCase(reader.getFormatName())) return null;
				reader.setInput(in);
				return new int[] { reader.getWidth(0), reader.getHeight(0) };
			} finally {
				reader.dispose();
			}
		} catch (IOException | RuntimeException e) {
			return null;
		}
	}

	/**
	 * 임시 스냅샷(Cam1, Cam2)을 기준 스냅샷(roi/baseline/{serial}/{rh_id}/)으로 복사하고 tbl_roi_snapshot 에 카메라별 1행을 기록한다.
	 * 임시 파일이 이미 정리되어 없으면 ROI_snapshot 을 다시 요청한다. 실패해도 ROI 적용 결과(SUCCESS)는 바꾸지 않고 false 만 돌려준다.
	 */
	private boolean persistBaseline(String serial, long rhId, RoiActor actor) {
		try {
			Path base = mediaBase();
			if (base == null) {
				logger.warn("[ROI] 미디어 기준 폴더를 찾을 수 없어 기준 스냅샷을 저장하지 못했습니다 (rhId={})", rhId);
				return false;
			}
			String[] cams = RoiValidator.CAMERAS;
			Path[] src = new Path[cams.length];
			boolean missing = false;
			for (int i = 0; i < cams.length; i++) {
				src[i] = RoiPaths.resolveUnder(base, RoiPaths.tempRelative(actor.loginId, serial, cams[i]));
				if (!Files.isRegularFile(src[i])) missing = true;
			}
			if (missing) {
				Reply again = requestSnapshot(serial, actor);
				if (!again.ok()) return false;
				for (Path p : src) if (!Files.isRegularFile(p)) return false;
			}
			int[][] sizes = new int[cams.length][];
			for (int i = 0; i < cams.length; i++) {
				sizes[i] = readJpegSize(src[i]);
				if (sizes[i] == null || sizes[i][0] != SNAPSHOT_W || sizes[i][1] != SNAPSHOT_H) {
					logger.warn("[ROI] 임시 스냅샷이 1920x1080 JPEG 가 아닙니다 (rhId={}, camera={})", rhId, cams[i]);
					return false;
				}
			}
			Path destDir = RoiPaths.resolveUnder(base, "roi/baseline/" + serial + "/" + rhId);
			Files.createDirectories(destDir);
			for (int i = 0; i < cams.length; i++) {
				byte[] suffix = new byte[6];
				random.nextBytes(suffix);
				StringBuilder hex = new StringBuilder();
				for (byte b : suffix) hex.append(String.format("%02x", b));
				Path tmp = destDir.resolve("." + cams[i] + ".jpg.tmp-" + hex);
				Files.copy(src[i], tmp, StandardCopyOption.REPLACE_EXISTING);
				try {
					Files.move(tmp, destDir.resolve(cams[i] + ".jpg"), StandardCopyOption.ATOMIC_MOVE);
				} catch (java.nio.file.AtomicMoveNotSupportedException e) {
					Files.move(tmp, destDir.resolve(cams[i] + ".jpg"), StandardCopyOption.REPLACE_EXISTING);
				}
			}
			for (int i = 0; i < cams.length; i++) {
				Map<String, Object> p = new HashMap<>();
				p.put("rhId", rhId);
				p.put("camera", cams[i]);
				p.put("filePath", RoiPaths.baselineRelative(serial, rhId, cams[i]));
				p.put("width", sizes[i][0]);
				p.put("height", sizes[i][1]);
				roiMapper.insertSnapshot(p);
			}
			return true;
		} catch (IOException | RuntimeException e) {
			logger.error("[ROI] 기준 스냅샷 저장 실패 (rhId=" + rhId + "): ", e);
			return false;
		}
	}

	// ------------------------------------------------------------------ 저장

	@Override
	public RoiResult save(int deviceId, JsonNode rois, String baseHash, Long rollbackRhId, RoiActor actor) {
		Device d;
		try {
			d = findDevice(deviceId);
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
		if (d == null) return noDevice();

		String base = baseHash == null ? "" : baseHash.trim();
		if (!base.isEmpty() && !HASH.matcher(base).matches()) {
			return RoiResult.error(400, "BAD_BASE_HASH", "편집 기준 정보가 올바르지 않습니다. 다시 불러오십시오.");
		}

		String action;
		JsonNode input = rois;
		if (rollbackRhId != null) {
			// 되돌리기: 원문은 클라이언트 값이 아니라 DB 이력에서 가져온다.
			Map<String, Object> row = roiMapper.selectHistory(rollbackRhId);
			if (row == null || num(row, "rh_dv_id") != d.id || !"SUCCESS".equals(str(row, "rh_status"))) {
				return RoiResult.error(404, "NO_HISTORY", "되돌릴 이력을 찾을 수 없습니다.");
			}
			input = RoiCodec.lenientRead(str(row, "rh_roi_json"), RoiCodec.readNames(str(row, "rh_meta_json")));
			if (input == null) return RoiResult.error(422, "BAD_HISTORY", "선택한 이력의 ROI 를 해석할 수 없습니다.");
			action = "ROLLBACK";
		} else {
			action = roiMapper.countSuccess(d.id) == 0 ? "CREATE" : "UPDATE";
		}

		// 3중 검증 중 서버(Java) 단계: 형식·범위·자기교차·겹침
		RoiCodec.Normalized n;
		try {
			List<RoiValidator.Problem> problems = RoiValidator.validate(input);
			if (!problems.isEmpty()) {
				return RoiResult.error(400, "INVALID", "ROI 검증에 실패했습니다.").with("problems", problemList(problems));
			}
			n = RoiCodec.normalize(input, includeName);
		} catch (RoiValidator.FormatException e) {
			return RoiResult.error(400, "FORMAT", e.getMessage());
		}

		Map<String, Object> ins = new HashMap<>();
		ins.put("dvId", d.id);
		ins.put("action", action);
		ins.put("roiJson", n.text);
		ins.put("metaJson", n.metaJson);
		ins.put("roiHash", n.hash);
		ins.put("baseHash", base.isEmpty() ? null : base);
		ins.put("uName", clip(actor.name == null || actor.name.isEmpty() ? actor.loginId : actor.name, 40));
		roiMapper.insertHistory(ins);
		long rhId = ((Number) ins.get("rhId")).longValue();

		Map<String, Object> payload = new HashMap<>();
		payload.put("serial", d.serial);
		payload.put("baseHash", base);
		payload.put("roisText", n.text);
		Reply reply = client.post("/ROI_send", payload);

		if (reply.failure == Failure.TIMEOUT) {
			// 결과 불명: PENDING 을 유지하고 화면이 roiCheck 로 확정하게 한다(계획서 확정사항 18).
			return RoiResult.error(504, "TIMEOUT", "장비 응답을 확인하지 못했습니다. 적용 여부를 확인합니다.").with("rhId", rhId);
		}
		if (reply.ok()) {
			String returned = reply.body.path("hash").asText("");
			if (!n.hash.equals(returned)) {
				logger.error("[ROI] 장비가 저장한 해시가 보낸 내용과 다릅니다 (rhId={})", rhId);
				finish(rhId, "FAIL", 502, "장비가 저장한 내용의 해시가 일치하지 않습니다");
				return RoiResult.error(502, "HASH_MISMATCH", "장비가 저장한 내용을 확인하지 못했습니다. 다시 불러와서 확인하십시오.").with("rhId", rhId);
			}
			finish(rhId, "SUCCESS", null, null);
			boolean snapshotSaved = persistBaseline(d.serial, rhId, actor);
			Map<String, Object> body = new LinkedHashMap<>();
			body.put("rhId", rhId);
			body.put("hash", n.hash);
			body.put("action", action);
			body.put("rois", n.rois);
			body.put("snapshotSaved", snapshotSaved);
			return RoiResult.ok(body);
		}
		RoiResult err = relayError(reply);
		String failMsg = String.valueOf(err.body.get("msg"));
		finish(rhId, "FAIL", err.status, failMsg);
		return err.with("rhId", rhId);
	}

	@Override
	public RoiResult check(long rhId, RoiActor actor) {
		Map<String, Object> row = rhId > 0 ? roiMapper.selectHistory(rhId) : null;
		if (row == null) return RoiResult.error(404, "NO_HISTORY", "이력을 찾을 수 없습니다.");
		String status = str(row, "rh_status");
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("rhId", rhId);
		if (!"PENDING".equals(status)) {
			// 이미 확정된 건(다른 화면이 먼저 확인했거나 처음부터 결과가 났음)
			body.put("status", status);
			body.put("failMsg", str(row, "rh_fail_msg"));
			return RoiResult.ok(body);
		}
		Device d;
		try {
			d = findDevice((int) num(row, "rh_dv_id"));
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
		if (d == null) return noDevice();

		Map<String, Object> payload = new HashMap<>();
		payload.put("serial", d.serial);
		Reply reply = client.post("/ROI_get", payload);
		if (!reply.ok()) {
			// 장비와 아직 통신이 안 되면 PENDING 으로 두고 나중에 다시 확인할 수 있게 한다.
			return relayError(reply).with("rhId", rhId).with("pending", true);
		}
		String deviceHash = reply.body.path("hash").asText("");
		if (deviceHash.equals(str(row, "rh_roi_hash"))) {
			int changed = finish(rhId, "SUCCESS", null, null);
			boolean snapshotSaved = changed > 0 && persistBaseline(d.serial, rhId, actor);
			body.put("status", "SUCCESS");
			body.put("hash", deviceHash);
			body.put("snapshotSaved", snapshotSaved);
			return RoiResult.ok(body);
		}
		finish(rhId, "FAIL", 504, "시간 초과 후 확인: 장비에 적용되지 않았습니다");
		body.put("status", "FAIL");
		body.put("failMsg", "시간 초과 후 확인한 결과 장비에 적용되지 않았습니다. 다시 불러온 뒤 저장하십시오.");
		return RoiResult.ok(body);
	}

	// ------------------------------------------------------------------ 이력

	@Override
	public RoiResult history(int deviceId, int limit) {
		try {
			Device d = findDevice(deviceId);
			if (d == null) return noDevice();
			Map<String, Object> p = new HashMap<>();
			p.put("dvId", d.id);
			p.put("limit", Math.max(1, Math.min(limit, 200)));
			Map<String, Object> latest = roiMapper.selectLatestSuccess(d.id);
			Map<String, Object> body = new LinkedHashMap<>();
			body.put("device", deviceBrief(d));
			body.put("items", roiMapper.selectHistoryList(p));
			body.put("currentRhId", latest == null ? null : num(latest, "rh_id"));
			return RoiResult.ok(body);
		} catch (IllegalArgumentException e) {
			return deviceError(e);
		}
	}

	@Override
	public RoiResult historyDetail(long rhId) {
		Map<String, Object> row = rhId > 0 ? roiMapper.selectHistory(rhId) : null;
		if (row == null) return RoiResult.error(404, "NO_HISTORY", "이력을 찾을 수 없습니다.");
		Map<String, Object> body = new LinkedHashMap<>();
		Map<String, Object> info = new LinkedHashMap<>();
		for (String k : new String[] { "rh_id", "rh_dv_id", "rh_action", "rh_status", "rh_fail_code", "rh_fail_msg", "rh_u_name", "req_date", "resp_date" }) {
			info.put(k, row.get(k));
		}
		info.put("rh_roi_hash", str(row, "rh_roi_hash"));
		body.put("history", info);
		ObjectNode rois = RoiCodec.lenientRead(str(row, "rh_roi_json"), RoiCodec.readNames(str(row, "rh_meta_json")));
		body.put("rois", rois == null ? emptyRois() : rois);
		body.put("formatError", rois == null);
		// 파일 경로는 노출하지 않고 rs_id 만 준다 — 이미지는 roiImage.do?rsId= 로 권한 검사 후 스트리밍한다.
		List<Map<String, Object>> snaps = new ArrayList<>();
		for (Map<String, Object> s : roiMapper.selectSnapshots(rhId)) {
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("rsId", num(s, "rs_id"));
			m.put("camera", str(s, "rs_camera"));
			m.put("width", s.get("rs_width"));
			m.put("height", s.get("rs_height"));
			snaps.add(m);
		}
		body.put("snapshots", snaps);
		return RoiResult.ok(body);
	}
}
