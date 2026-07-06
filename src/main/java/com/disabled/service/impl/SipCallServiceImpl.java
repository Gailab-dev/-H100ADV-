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

		// 4. tier-3(디바이스 실시간 fetch)·module_d 는 부수 영역으로 별도(작업계획서 §6-12, §8).
		//    서버에 파일이 없으면 "파일 없음" 으로 정직하게 응답.
		logger.info("[SIP] 서버에 오디오 파일 없음(dec·enc 모두 부재) scId={} name={} — 디바이스 fetch(tier-3)는 후속 예정", scId, audioPath);
		return HttpServletResponse.SC_NOT_FOUND;
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
