package com.disabled.backup;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 서버 디스크에서 "정상 파일"을 찾는다 — 백업 판정과 이벤트 삭제 전 확인의 공통 기준.
 *
 * <p>저장 위치(module_c fileReceive.go · 웹 globals.properties):
 * 이미지/영상은 module_c 가 받은 그대로 {@code *.enc.path}(output_*_enc)에 저장하고(module_c 는 암호화하지 않는다),
 * 웹이 열람할 때 {@code decryptForView} 가 {@code *.dec.path}(output_*)로 복호화·복사한다.
 * 통화 음성은 평문이라 {@code audio.dec.path}(output_audios)에 바로 저장된다.
 * 따라서 백업 판정은 enc 폴더(수신 원본)를 1순위로, dec 폴더(평문 원본만 남은 이벤트)를 2순위로 본다.</p>
 *
 * <p>"정상"의 정의: 일반 파일이고 크기가 0보다 크며, (알고 있다면) 장비가 보고한 바이트와 같고,
 * 장비의 JSON 확인 응답({"result":...})이 파일로 저장된 오염본이 아니어야 한다
 * (과거 2026-08 사고에서 18바이트 JSON 이 이미지/영상 파일로 저장된 사례가 있었다).</p>
 */
@Component
public class ServerFileLocator {

	private static final Logger logger = LoggerFactory.getLogger(ServerFileLocator.class);

	private static final ObjectMapper MAPPER = new ObjectMapper();

	@Value("${image.enc.path}")
	private String imgEncPath;

	@Value("${video.enc.path}")
	private String videoEncPath;

	@Value("${image.dec.path}")
	private String imgDecPath;

	@Value("${video.dec.path}")
	private String videoDecPath;

	@Value("${audio.enc.path}")
	private String audioEncPath;

	@Value("${audio.dec.path}")
	private String audioDecPath;

	/** 찾은 서버 파일(경로·크기) */
	public static final class ServerFile {
		public final File file;
		public final long bytes;

		ServerFile(File file, long bytes) {
			this.file = file;
			this.bytes = bytes;
		}
	}

	/** 파일명 안전성: 경로 요소·제어문자가 섞이면 장비 요청·디스크 조회 모두 하지 않는다 */
	public static boolean isSafeName(String name) {
		if (name == null) {
			return false;
		}
		String n = name.trim();
		if (n.isEmpty() || n.length() > 255 || "null".equals(n)) {
			return false;
		}
		if (n.contains("..") || n.contains("/") || n.contains("\\") || n.contains(":")) {
			return false;
		}
		for (int i = 0; i < n.length(); i++) {
			if (n.charAt(i) < 0x20) {
				return false;
			}
		}
		return true;
	}

	/**
	 * 서버에 정상 파일이 있으면 돌려준다.
	 * @param expectedBytes 장비가 보고한 바이트(알면 일치해야 정상, 모르면 null)
	 */
	public ServerFile find(FileKind kind, String fileName, Long expectedBytes) {
		if (!isSafeName(fileName)) {
			return null;
		}
		for (File candidate : candidates(kind, fileName.trim())) {
			long bytes = validBytes(candidate, expectedBytes);
			if (bytes >= 0) {
				return new ServerFile(candidate, bytes);
			}
		}
		return null;
	}

	/** 삭제 기록용 "원래 경로": 정상 파일이 있으면 그 경로, 없으면 1순위 저장 위치 */
	public String originalPath(FileKind kind, String fileName) {
		if (!isSafeName(fileName)) {
			return null;
		}
		ServerFile found = find(kind, fileName, null);
		if (found != null) {
			return found.file.getPath();
		}
		List<File> list = candidates(kind, fileName.trim());
		return list.isEmpty() ? null : list.get(0).getPath();
	}

	private List<File> candidates(FileKind kind, String name) {
		List<File> list = new ArrayList<File>();
		String plain = name.replaceFirst("\\.enc$", "");
		switch (kind) {
		case EVENT_IMAGE1:
		case EVENT_IMAGE2:
			list.add(new File(imgEncPath, name));
			list.add(new File(imgDecPath, plain));
			break;
		case EVENT_VIDEO:
			list.add(new File(videoEncPath, name));
			list.add(new File(videoDecPath, plain));
			break;
		case CALL_AUDIO:
			// module_c 가 평문으로 audio.dec.path 에 저장. 구형 .enc 보관본(SipCallServiceImpl tier-2)은 보조로만 본다.
			list.add(new File(audioDecPath, name));
			list.add(new File(audioEncPath, name + ".enc"));
			break;
		default:
			break;
		}
		return list;
	}

	/** 정상 파일이면 바이트 수, 아니면 -1 */
	private long validBytes(File f, Long expectedBytes) {
		try {
			if (!f.isFile()) {
				return -1;
			}
			long len = f.length();
			if (len <= 0) {
				return -1;
			}
			if (expectedBytes != null && expectedBytes.longValue() != len) {
				return -1;
			}
			if (looksLikeDeviceJson(f, len)) {
				logger.warn("[FileBackup] 장비 JSON 확인 응답이 파일로 저장된 오염본으로 판단 — 정상 파일 아님: {}", f.getName());
				return -1;
			}
			return len;
		} catch (SecurityException e) {
			logger.warn("[FileBackup] 파일 접근 불가: {}", f.getName(), e);
			return -1;
		}
	}

	/** 작은 파일이 {"result": ...} JSON 이면 오염본(실제 미디어가 아님) */
	private boolean looksLikeDeviceJson(File f, long len) {
		if (len > 4096) {
			return false;
		}
		try (InputStream in = new FileInputStream(f)) {
			byte[] head = in.readNBytes(4096);
			int i = 0;
			while (i < head.length && (head[i] == ' ' || head[i] == '\n' || head[i] == '\r' || head[i] == '\t')) {
				i++;
			}
			if (i >= head.length || head[i] != '{') {
				return false;
			}
			JsonNode node = MAPPER.readTree(head);
			return node != null && node.hasNonNull("result");
		} catch (IOException e) {
			// JSON 파싱 실패 = 바이너리 파일로 간주
			return false;
		}
	}
}
