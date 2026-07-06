package com.disabled.service;

import java.util.Map;

import javax.servlet.http.HttpServletResponse;

/**
 * SIP CALL 로그 서비스 (작업계획서 07)
 */
public interface SipCallService {

	/**
	 * SIP 통화 로그 조회 (필터 + 페이지네이션)
	 * @return {"total": int, "list": List<Map>}
	 */
	Map<String, Object> getList(String keyword, int listSize, String startDate, String endDate, int page);

	/**
	 * 오디오 재생용 파일 스트리밍.
	 * 서버 파일 우선(ADR-008 정합): 1) dec 평문 → 2) enc 복호화(AES-256 재사용) → 3) 없으면 404.
	 * (디바이스 실시간 fetch(tier-3)·module_d 는 부수 영역으로 별도)
	 * @return HTTP status (200 스트리밍 완료 / 404 파일 없음 / 400 잘못된 요청)
	 */
	int streamAudio(Integer scId, HttpServletResponse res);
}
