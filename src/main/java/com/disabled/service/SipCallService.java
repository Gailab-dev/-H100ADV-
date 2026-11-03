package com.disabled.service;

import java.util.Map;

import javax.servlet.http.HttpServletResponse;

/**
 * SIP CALL 로그 서비스 (작업계획서 07)
 */
public interface SipCallService {

	/**
	 * SIP 통화 로그 조회 (필터 + 페이지네이션)
	 * 알림에서 넘어온 경우(focusScId 또는 notiSerial+notiTime)에는 해당 통화 로그가 있는 페이지로 보정해 내려준다.
	 * @param listSize   한 페이지 크기(서버 고정값, 컨트롤러가 전달)
	 * @param focusScId  강조할 통화 로그 sc_id(없으면 null)
	 * @param notiSerial 응급콜 알림의 noti_serial(없으면 null) — focusScId 가 없을 때 알림 시각과 함께 로그 행을 찾는 데 사용
	 * @param notiTime   응급콜 알림 시각 'yyyy-MM-dd HH:mm:ss'(noti_reg_date)
	 * @return {"total": int, "list": List<Map>, "page": int, "listSize": int,
	 *          "focusScId": 강조할 sc_id(찾은 경우만), "focusRequested": 강조 요청 여부, "focusFound": 찾았는지}
	 */
	Map<String, Object> getList(String keyword, int listSize, String startDate, String endDate, int page,
			Integer focusScId, String notiSerial, String notiTime);

	/**
	 * 오디오 재생용 파일 스트리밍.
	 * 서버 파일 우선(ADR-008 정합): 1) dec 평문 → 2) enc 복호화(AES-256 재사용) → 3) 없으면 404.
	 * (디바이스 실시간 fetch(tier-3)·module_d 는 부수 영역으로 별도)
	 * @return HTTP status (200 스트리밍 완료 / 404 파일 없음 / 400 잘못된 요청)
	 */
	int streamAudio(Integer scId, HttpServletResponse res);
}
