package com.disabled.backup;

/**
 * 전송 이력 상태 값(tbl_file_transfer_log.ft_status).
 *  PENDING 대상 등록 → VERIFIED 검증 완료 / FAILED 재시도 대기 / MISSING 장비에도 없음 /
 *  LOST 재시도 기한 경과 / DELETED_EVENT 이벤트 삭제로 폐기
 */
public final class TransferStatus {

	public static final String PENDING = "PENDING";
	public static final String VERIFIED = "VERIFIED";
	public static final String FAILED = "FAILED";
	public static final String MISSING = "MISSING";
	public static final String LOST = "LOST";
	public static final String DELETED_EVENT = "DELETED_EVENT";

	private TransferStatus() {
	}
}
