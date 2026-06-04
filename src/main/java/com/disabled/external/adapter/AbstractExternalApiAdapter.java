package com.disabled.external.adapter;

import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.net.URI;
import java.net.UnknownHostException;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import com.disabled.external.dto.ExternalApiResponse;
import com.disabled.external.exception.ExternalApiException;
import com.disabled.external.exception.ExternalApiException.ErrorType;

/**
 * 외부 API 어댑터 공통 처리 추상 클래스.
 *
 * <p>모든 구체 어댑터가 공통으로 필요로 하는 다음 로직을 한곳에 모은다.</p>
 * <ul>
 *   <li>HTTP 타임아웃 : {@code externalApiRestTemplate} 빈에 설정 (properties로 변경 가능)</li>
 *   <li>재시도 : 실패 시 최대 N회(기본 2회), 지수 백오프</li>
 *   <li>요청·응답 로깅 : 어댑터명 / 상태 코드 / 소요 시간</li>
 *   <li>에러 분류 : 네트워크 / 타임아웃 / 4xx / 5xx 구분 ({@link ExternalApiException})</li>
 * </ul>
 *
 * <p>{@link #fetch(Map)} 는 위 공통 처리를 수행한 뒤, 실제 API 호출은 하위 클래스의
 * {@link #doFetch(Map)} 에 위임한다(템플릿 메서드 패턴). 하위 클래스는 보통
 * {@link #get(URI)} 헬퍼를 사용해 호출만 하면 되며, HTTP 오류 분류·재시도는 자동 처리된다.</p>
 */
public abstract class AbstractExternalApiAdapter implements ExternalApiAdapter {

	/** 하위 클래스의 실제 타입으로 로거 생성 */
	protected final Logger logger = LoggerFactory.getLogger(getClass());

	/** 타임아웃이 설정된 공통 RestTemplate (ExternalApiConfig 에서 정의) */
	@Autowired
	protected RestTemplate externalApiRestTemplate;

	/** 최대 재시도 횟수 (최초 호출 제외, 기본 2회) */
	@Value("${external.api.retry.max-attempts:2}")
	private int maxRetries;

	/** 지수 백오프 기준 대기 시간(ms). 재시도 n회차 대기 = base * 2^(n-1) */
	@Value("${external.api.retry.backoff-millis:500}")
	private long backoffMillis;

	/**
	 * 공통 처리(재시도·로깅·에러 분류)를 포함한 호출 진입점.
	 * 실제 호출은 {@link #doFetch(Map)} 에 위임한다.
	 */
	@Override
	public final ExternalApiResponse fetch(Map<String, String> params) {

		final long start = System.currentTimeMillis();
		ExternalApiException lastEx = null;

		// attempt 0 = 최초 호출, 이후 maxRetries 회까지 재시도
		for (int attempt = 0; attempt <= maxRetries; attempt++) {

			// 재시도 전 지수 백오프 대기
			if (attempt > 0) {
				long wait = backoffMillis * (1L << (attempt - 1));
				logger.warn("[{}] 재시도 {}/{} ({}ms 대기 후)", getName(), attempt, maxRetries, wait);
				if (!sleep(wait)) {
					// 인터럽트 발생 시 즉시 중단
					break;
				}
			}

			try {
				ExternalApiResponse res = doFetch(params);
				long elapsed = System.currentTimeMillis() - start;
				res.setElapsedMillis(elapsed);
				logger.info("[{}] 호출 성공 status={} elapsed={}ms", getName(), res.getHttpStatus(), elapsed);
				return res;

			} catch (Exception e) {
				lastEx = classify(e);
				logger.error("[{}] 호출 실패 (attempt={}) type={} status={} msg={}",
						getName(), attempt, lastEx.getErrorType(), lastEx.getHttpStatus(), lastEx.getMessage());

				// 재시도해도 의미 없는 오류(4xx 등)는 즉시 중단
				if (!lastEx.isRetryable()) {
					break;
				}
			}
		}

		long elapsed = System.currentTimeMillis() - start;
		logger.error("[{}] 최종 실패 elapsed={}ms", getName(), elapsed);
		return ExternalApiResponse.failure(getName(), lastEx, elapsed);
	}

	/**
	 * 각 구체 어댑터가 구현하는 실제 API 호출 로직.
	 * URL 조립·인증 파라미터 부착 등 API별 특화 처리를 수행한 뒤
	 * {@link #get(URI)} 등으로 호출하고 결과를 반환한다.
	 *
	 * @param params 호출 파라미터
	 * @return 성공 응답 (실패 시 RestTemplate 예외를 그대로 던지면 상위에서 분류·재시도)
	 */
	protected abstract ExternalApiResponse doFetch(Map<String, String> params);

	// ------------------------------------------------------------------
	// 하위 클래스용 공통 헬퍼
	// ------------------------------------------------------------------

	/**
	 * GET 호출 후 본문을 원본 문자열로 담아 성공 응답을 만든다.
	 * 4xx/5xx 응답 시 RestTemplate 이 예외를 던지며, 이는 상위 {@link #fetch(Map)}
	 * 에서 분류·재시도된다.
	 *
	 * @param uri 호출 대상 URI (이미 인코딩된 상태여야 함)
	 */
	protected ExternalApiResponse get(URI uri) {
		ResponseEntity<String> resp = externalApiRestTemplate.getForEntity(uri, String.class);
		return ExternalApiResponse.success(getName(), resp.getStatusCodeValue(), resp.getBody());
	}

	/**
	 * 지정 URL로 가벼운 연결 확인(HEAD)을 수행한다.
	 * 서버가 4xx/5xx로 응답하더라도 "연결 자체는 가능"하므로 true 로 본다.
	 *
	 * @param url 확인 대상 URL
	 * @return 연결 가능하면 true
	 */
	protected boolean ping(String url) {
		try {
			externalApiRestTemplate.headForHeaders(URI.create(url));
			return true;
		} catch (HttpStatusCodeException e) {
			// 서버가 응답을 돌려줬다 = 도달 가능
			return true;
		} catch (Exception e) {
			logger.warn("[{}] healthCheck 실패 url={} msg={}", getName(), url, e.getMessage());
			return false;
		}
	}

	// ------------------------------------------------------------------
	// 내부 유틸
	// ------------------------------------------------------------------

	/**
	 * RestTemplate / 네트워크 예외를 {@link ExternalApiException} 으로 분류한다.
	 */
	protected ExternalApiException classify(Exception e) {

		// HTTP 4xx
		if (e instanceof HttpClientErrorException) {
			HttpClientErrorException he = (HttpClientErrorException) e;
			return new ExternalApiException(ErrorType.CLIENT_ERROR, he.getRawStatusCode(),
					"HTTP 4xx: " + he.getStatusText(), e);
		}

		// HTTP 5xx
		if (e instanceof HttpServerErrorException) {
			HttpServerErrorException he = (HttpServerErrorException) e;
			return new ExternalApiException(ErrorType.SERVER_ERROR, he.getRawStatusCode(),
					"HTTP 5xx: " + he.getStatusText(), e);
		}

		// 연결/타임아웃 등 I/O 계열 (RestTemplate 는 ResourceAccessException 으로 감쌈)
		if (e instanceof ResourceAccessException) {
			Throwable cause = e.getCause();
			if (cause instanceof SocketTimeoutException) {
				return new ExternalApiException(ErrorType.TIMEOUT, "응답 시간 초과", e);
			}
			if (cause instanceof ConnectException || cause instanceof UnknownHostException) {
				return new ExternalApiException(ErrorType.NETWORK, "네트워크 연결 실패", e);
			}
			return new ExternalApiException(ErrorType.NETWORK, "네트워크 오류: " + e.getMessage(), e);
		}

		// 기타 (이미 분류된 예외는 그대로)
		if (e instanceof ExternalApiException) {
			return (ExternalApiException) e;
		}

		return new ExternalApiException(ErrorType.UNKNOWN, "알 수 없는 오류: " + e.getMessage(), e);
	}

	/**
	 * 인터럽트 안전 sleep.
	 *
	 * @return 정상 대기 완료 시 true, 인터럽트 발생 시 false
	 */
	private boolean sleep(long millis) {
		try {
			Thread.sleep(millis);
			return true;
		} catch (InterruptedException ie) {
			Thread.currentThread().interrupt();
			logger.warn("[{}] 재시도 대기 중 인터럽트 발생", getName());
			return false;
		}
	}
}
