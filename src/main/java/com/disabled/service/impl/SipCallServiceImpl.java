package com.disabled.service.impl;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import com.disabled.mapper.SipCallMapper;
import com.disabled.service.SipCallService;
import com.disabled.service.VideoDecryptionService;

/**
 * SIP CALL 로그 서비스 구현 (작업계획서 07)
 *
 * 재사용:
 *  - 오디오 복호화: 기존 이미지·영상 AES-256({@link VideoDecryptionService}) 그대로 재사용(계획서 결정 §10-2)
 *  - 목록 필터·페이지네이션: 이벤트/디바이스 리스트 패턴
 */
@Service
public class SipCallServiceImpl implements SipCallService {

	private static final Logger logger = LoggerFactory.getLogger(SipCallServiceImpl.class);

	@Autowired
	private SipCallMapper sipCallMapper;

	@Autowired
	private VideoDecryptionService decryptionService;

	/** (2026-07-22) tier-3 디바이스 녹음 요청용 — 이미지·영상과 동일 경로(/fileSend) 재사용 */
	@Autowired
	private com.disabled.service.ApiService apiService;

	/** (2026-07-22) sc_dv_id → dv_ip 조회 */
	@Autowired
	private com.disabled.service.DeviceListService deviceListService;

	// 암호화된 오디오 파일 경로
	@Value("${audio.enc.path}")
	private String audioEncPath;

	// 복호화된(평문) 오디오 파일 경로
	@Value("${audio.dec.path}")
	private String audioDecPath;

	@Override
	public Map<String, Object> getList(String keyword, int listSize, String startDate, String endDate, int page) {

		Map<String, Object> out = new HashMap<String, Object>();

		try {
			if (listSize <= 0) listSize = 10;
			if (page <= 0) page = 1;
			int offset = (page - 1) * listSize;

			Map<String, Object> params = new HashMap<String, Object>();
			params.put("keyword", (keyword == null) ? "" : keyword.trim());
			// 검색창 통합: 숫자면 dv_id 완전일치 조건도 포함(문자면 시리얼 LIKE만)
			params.put("keywordIsNumeric", keyword != null && keyword.trim().matches("^[0-9]+$"));
			params.put("startDate", startDate);
			params.put("endDate", endDate);
			params.put("listSize", listSize);
			params.put("offset", offset);

			int total = sipCallMapper.countList(params);
			List<Map<String, Object>> list = sipCallMapper.selectList(params);

			out.put("total", total);
			out.put("list", list);
			out.put("page", page);
			out.put("listSize", listSize);
			return out;

		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, sipCallMapper.getList() : ", e);
			throw e;
		}
	}

	@Override
	public int streamAudio(Integer scId, HttpServletResponse res) {

		// 1. 유효성
		if (scId == null || scId <= 0) {
			logger.warn("[SIP] 유효하지 않은 scId: {}", scId);
			return HttpServletResponse.SC_BAD_REQUEST;
		}

		Map<String, Object> sipCall;
		try {
			sipCall = sipCallMapper.selectById(scId);
		} catch (DataAccessException e) {
			logger.error("[SIP] sipCallMapper.selectById 오류 scId={}", scId, e);
			return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
		}
		if (sipCall == null) {
			logger.info("[SIP] 존재하지 않는 통화 로그 scId={}", scId);
			return HttpServletResponse.SC_NOT_FOUND;
		}

		Object pathObj = sipCall.get("sc_audio_path");
		String audioPath = (pathObj == null) ? "" : pathObj.toString().trim();
		if (audioPath.isEmpty() || "null".equals(audioPath)) {
			logger.info("[SIP] 오디오 파일 경로 없음(부재중·실패 통화) scId={}", scId);
			return HttpServletResponse.SC_NOT_FOUND;
		}

		// Path Traversal 방어 (파일명만 허용)
		if (isUnsafeName(audioPath)) {
			logger.warn("[SIP] 안전하지 않은 오디오 파일명 scId={} name={}", scId, audioPath);
			return HttpServletResponse.SC_BAD_REQUEST;
		}

		// 2. tier-1: dec 평문 원본 존재 → 그대로 스트리밍
		File plainFile = new File(audioDecPath, audioPath);
		if (plainFile.exists()) {
			return streamFile(plainFile, audioPath, res);
		}

		// 3. tier-2: enc 존재 → AES-256 복호화(기존 로직 재사용) → dec 저장 → 스트리밍
		File encFile = new File(audioEncPath, audioPath + ".enc");
		if (encFile.exists()) {
			try {
				boolean ok = decryptionService.decryptAndSaveFileAutoName1(audioPath + ".enc", audioEncPath, audioDecPath);
				if (ok && plainFile.exists()) {
					return streamFile(plainFile, audioPath, res);
				}
				logger.error("[SIP] 오디오 복호화 실패 scId={} name={}", scId, audioPath);
			} catch (Exception e) {
				logger.error("[SIP] 오디오 복호화 예외 scId={} name={}", scId, audioPath, e);
			}
			return HttpServletResponse.SC_NOT_FOUND;
		}

		// 4. tier-3: 서버에 없으면 디바이스에 요청(이미지·영상의 ADR-008 패턴과 동일).
		//    흐름: 웹 → 디바이스(module_d) /fileSend {type:audio} → 디바이스가 module_c(/audioFileReceive)로 업로드
		//          → module_c 가 audio.dec.path 에 평문 저장 → 아래 폴링으로 도착 확인 후 스트리밍.
		//    한 번 받아오면 서버에 남으므로 다음 재생부터는 tier-1 에서 즉시 처리된다.
		if (fetchAudioFromDevice(res, scId, sipCall, audioPath)) {
			return streamFile(plainFile, audioPath, res);
		}

		logger.info("[SIP] 서버에 오디오 파일 없음(dec·enc·디바이스 모두 실패) scId={} name={}", scId, audioPath);
		return HttpServletResponse.SC_NOT_FOUND;
	}

	/**
	 * (2026-07-22) 디바이스에 녹음 파일 전송을 요청하고, module_c 를 통해 서버에 도착할 때까지 대기한다.
	 *  - 디바이스 응답은 "보냈다"는 결과일 뿐이므로, 실제 도착 여부는 파일 존재로 확인해야 한다.
	 * @return 파일이 도착해 재생 가능하면 true
	 */
	private boolean fetchAudioFromDevice(HttpServletResponse res, Integer scId,
			Map<String, Object> sipCall, String audioPath) {
		try {
			Object dvIdObj = sipCall.get("sc_dv_id");
			if (dvIdObj == null) {
				logger.warn("[SIP] 디바이스 ID 없음 → 디바이스 요청 불가 scId={}", scId);
				return false;
			}
			int dvId = Integer.parseInt(dvIdObj.toString());

			String dvIp = deviceListService.getDvIpByDvID(dvId);
			if (dvIp == null || dvIp.isBlank()) {
				logger.warn("[SIP] 디바이스 IP 없음 scId={} dvId={}", scId, dvId);
				return false;
			}

			HashMap<String, Object> json = new HashMap<String, Object>();
			json.put("type", "audio");
			json.put("fileName", audioPath);

			String r = apiService.forwardStreamToJSON(res, json, dvIp, "/fileSend");
			if ("error".equals(r)) {
				logger.error("[SIP] 디바이스 녹음 전송 요청 실패 scId={} dvId={} name={}", scId, dvId, audioPath);
				return false;
			}

			// 디바이스 → module_c → 디스크 저장까지는 비동기이므로 도착을 잠시 기다린다(최대 약 10초).
			File plainFile = new File(audioDecPath, audioPath);
			for (int i = 0; i < 20; i++) {
				if (plainFile.exists() && plainFile.length() > 0) {
					logger.info("[SIP] 디바이스에서 녹음 수신 완료 scId={} name={} size={}", scId, audioPath, plainFile.length());
					return true;
				}
				Thread.sleep(500);
			}
			logger.warn("[SIP] 디바이스 요청은 성공했으나 파일이 도착하지 않음(module_c 확인 필요) scId={} name={}", scId, audioPath);
			return false;

		} catch (InterruptedException ie) {
			Thread.currentThread().interrupt();
			return false;
		} catch (Exception e) {
			logger.error("[SIP] 디바이스 녹음 수신 중 오류 scId=" + scId + " name=" + audioPath, e);
			return false;
		}
	}

	/** 파일을 응답 스트림으로 송출. 성공 시 200, 실패 시 500 반환. */
	private int streamFile(File file, String name, HttpServletResponse res) {
		res.setContentType(contentTypeOf(name));
		res.setHeader("Content-Length", String.valueOf(file.length()));
		res.setHeader("Accept-Ranges", "none");
		try (FileInputStream fis = new FileInputStream(file); OutputStream os = res.getOutputStream()) {
			byte[] buffer = new byte[8192];
			int read;
			while ((read = fis.read(buffer)) != -1) {
				os.write(buffer, 0, read);
			}
			os.flush();
			return HttpServletResponse.SC_OK;
		} catch (Exception e) {
			logger.error("[SIP] 오디오 스트리밍 오류 name={}", name, e);
			return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
		}
	}

	/** 확장자별 Content-Type (mp3/wav 위주, 계획서 §1) */
	private String contentTypeOf(String name) {
		String lower = name.toLowerCase();
		if (lower.endsWith(".mp3")) return "audio/mpeg";
		if (lower.endsWith(".wav")) return "audio/wav";
		if (lower.endsWith(".ogg")) return "audio/ogg";
		if (lower.endsWith(".m4a")) return "audio/mp4";
		return "application/octet-stream";
	}

	/** 파일명에 경로 요소가 섞였는지(디렉토리 이동 방어) */
	private boolean isUnsafeName(String name) {
		return name.contains("..") || name.contains("/") || name.contains("\\")
				|| name.contains("\0") || name.contains("%2e") || name.contains("%2f");
	}
}
