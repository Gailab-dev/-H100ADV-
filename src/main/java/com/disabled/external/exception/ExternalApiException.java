package com.disabled.external.exception;

/**
 * 외부 API 연동 공통 예외.
 *
 * <p>네트워크 / 타임아웃 / HTTP 4xx / HTTP 5xx 등 실패 원인을 {@link ErrorType} 으로 분류하여
 * 호출 측(어댑터, 컨트롤러)이 재시도 가능 여부나 사용자 노출 메시지를 판단할 수 있도록 한다.</p>
 */
public class ExternalApiException extends RuntimeException {

	private static final long serialVersionUID = 1L;

	/**
	 * 실패 원인 분류.
	 * <ul>
	 *   <li>NETWORK : 연결 실패(Connection refused, DNS 오류 등) - 재시도 대상</li>
	 *   <li>TIMEOUT : 응답 시간 초과 - 재시도 대상</li>
	 *   <li>CLIENT_ERROR : HTTP 4xx (요청 오류) - 재시도 비대상</li>
	 *   <li>SERVER_ERROR : HTTP 5xx (서버 오류) - 재시도 대상</li>
	 *   <li>UNKNOWN : 분류되지 않은 기타 오류</li>
	 * </ul>
	 */
	public enum ErrorType {
		NETWORK, TIMEOUT, CLIENT_ERROR, SERVER_ERROR, UNKNOWN
	}

	/** 실패 원인 분류 */
	private final ErrorType errorType;

	/** HTTP 상태 코드 (HTTP 오류가 아닐 경우 0) */
	private final int httpStatus;

	public ExternalApiException(ErrorType errorType, int httpStatus, String message, Throwable cause) {
		super(message, cause);
		this.errorType = errorType;
		this.httpStatus = httpStatus;
	}

	public ExternalApiException(ErrorType errorType, String message, Throwable cause) {
		this(errorType, 0, message, cause);
	}

	public ErrorType getErrorType() {
		return errorType;
	}

	public int getHttpStatus() {
		return httpStatus;
	}

	/**
	 * 재시도가 의미 있는 오류인지 여부.
	 * 네트워크 / 타임아웃 / 5xx 는 일시적 장애일 수 있어 재시도하고,
	 * 4xx(요청 오류)는 재시도해도 동일하게 실패하므로 즉시 중단한다.
	 *
	 * @return 재시도 대상이면 true
	 */
	public boolean isRetryable() {
		return errorType == ErrorType.NETWORK
				|| errorType == ErrorType.TIMEOUT
				|| errorType == ErrorType.SERVER_ERROR;
	}
}
