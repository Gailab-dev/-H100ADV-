package com.disabled.external.dto;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import com.disabled.external.exception.ExternalApiException;

/**
 * 외부 API 호출 결과를 담는 공통 응답 DTO.
 *
 * <p>모든 어댑터는 성공/실패 여부와 관계없이 본 객체로 결과를 감싸 반환한다.
 * 응답 본문({@code body})은 가공하지 않은 <b>원본 문자열</b>(JSON, XML 등)을 그대로 보관하여
 * API 포맷에 종속되지 않도록 한다.</p>
 *
 * <p>{@code responseTime} 은 Jackson(jsr310 모듈 미적용) 직렬화 호환을 위해
 * {@link LocalDateTime} 대신 ISO-8601 문자열로 보관한다.</p>
 */
public class ExternalApiResponse {

	private static final DateTimeFormatter TS_FORMAT = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

	/** 어댑터 식별명 (로깅/추적용) */
	private String adapterName;

	/** 호출 성공 여부 */
	private boolean success;

	/** HTTP 상태 코드 (네트워크 오류 등으로 응답이 없으면 0) */
	private int httpStatus;

	/** 응답 본문 원본 (성공 시) */
	private String body;

	/** 응답 수신 시각 (ISO-8601) */
	private String responseTime;

	/** 요청~응답 소요 시간(ms) */
	private long elapsedMillis;

	/** 실패 원인 분류 (성공 시 null) */
	private String errorType;

	/** 실패 메시지 (성공 시 null) */
	private String errorMessage;

	public ExternalApiResponse() {
		this.responseTime = LocalDateTime.now().format(TS_FORMAT);
	}

	/**
	 * 성공 응답 생성.
	 *
	 * @param adapterName 어댑터 식별명
	 * @param httpStatus  HTTP 상태 코드
	 * @param body        응답 본문 원본
	 */
	public static ExternalApiResponse success(String adapterName, int httpStatus, String body) {
		ExternalApiResponse res = new ExternalApiResponse();
		res.adapterName = adapterName;
		res.success = true;
		res.httpStatus = httpStatus;
		res.body = body;
		return res;
	}

	/**
	 * 실패 응답 생성.
	 *
	 * @param adapterName   어댑터 식별명
	 * @param ex            분류된 외부 API 예외
	 * @param elapsedMillis 소요 시간(ms)
	 */
	public static ExternalApiResponse failure(String adapterName, ExternalApiException ex, long elapsedMillis) {
		ExternalApiResponse res = new ExternalApiResponse();
		res.adapterName = adapterName;
		res.success = false;
		res.httpStatus = ex != null ? ex.getHttpStatus() : 0;
		res.errorType = ex != null ? ex.getErrorType().name() : ExternalApiException.ErrorType.UNKNOWN.name();
		res.errorMessage = ex != null ? ex.getMessage() : "알 수 없는 오류";
		res.elapsedMillis = elapsedMillis;
		return res;
	}

	public String getAdapterName() {
		return adapterName;
	}

	public void setAdapterName(String adapterName) {
		this.adapterName = adapterName;
	}

	public boolean isSuccess() {
		return success;
	}

	public void setSuccess(boolean success) {
		this.success = success;
	}

	public int getHttpStatus() {
		return httpStatus;
	}

	public void setHttpStatus(int httpStatus) {
		this.httpStatus = httpStatus;
	}

	public String getBody() {
		return body;
	}

	public void setBody(String body) {
		this.body = body;
	}

	public String getResponseTime() {
		return responseTime;
	}

	public void setResponseTime(String responseTime) {
		this.responseTime = responseTime;
	}

	public long getElapsedMillis() {
		return elapsedMillis;
	}

	public void setElapsedMillis(long elapsedMillis) {
		this.elapsedMillis = elapsedMillis;
	}

	public String getErrorType() {
		return errorType;
	}

	public void setErrorType(String errorType) {
		this.errorType = errorType;
	}

	public String getErrorMessage() {
		return errorMessage;
	}

	public void setErrorMessage(String errorMessage) {
		this.errorMessage = errorMessage;
	}
}
