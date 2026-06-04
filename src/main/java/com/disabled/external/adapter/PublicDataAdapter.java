package com.disabled.external.adapter;

import java.net.URI;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import com.disabled.external.dto.ExternalApiResponse;

/**
 * 공공데이터포털(data.go.kr) 연동 어댑터.
 *
 * <p>인증 방식은 {@code serviceKey} 를 쿼리 파라미터로 전송하며, 응답은 JSON 을 가정한다.
 * (응답 본문은 가공하지 않고 {@link ExternalApiResponse#getBody()} 에 원본 그대로 담는다.)</p>
 *
 * <p>베이스 URL / ServiceKey / 기본 경로는 {@code globals.properties} 또는 환경변수에서 주입한다.</p>
 *
 * <p><b>ServiceKey 인코딩 주의</b> : 공공데이터포털은 키를 "Encoding" / "Decoding" 두 형태로 제공한다.
 * 본 어댑터는 키가 <b>이미 URL 인코딩된 값(Encoding 키)</b> 이라고 가정하고 재인코딩하지 않는다
 * ({@code build(true)}). Decoding 키를 쓸 경우 {@code service-key-encoded=false} 로 설정한다.</p>
 */
@Component("publicDataAdapter")
public class PublicDataAdapter extends AbstractExternalApiAdapter {

	/** 공공데이터포털 베이스 URL (예: https://apis.data.go.kr/...) */
	@Value("${external.api.publicdata.base-url}")
	private String baseUrl;

	/** 인증 ServiceKey */
	@Value("${external.api.publicdata.service-key}")
	private String serviceKey;

	/** ServiceKey 가 이미 URL 인코딩된 값인지 여부 (Encoding 키=true) */
	@Value("${external.api.publicdata.service-key-encoded:true}")
	private boolean serviceKeyEncoded;

	@Override
	public String getName() {
		return "PublicDataAdapter";
	}

	@Override
	protected ExternalApiResponse doFetch(Map<String, String> params) {
		URI uri = buildUri(params);
		return get(uri);
	}

	@Override
	public boolean healthCheck() {
		return ping(baseUrl);
	}

	/**
	 * 베이스 URL + 호출 파라미터 + serviceKey 로 최종 URI 를 조립한다.
	 *
	 * @param params 호출 파라미터 (path 키가 있으면 베이스 URL 뒤에 경로로 덧붙임)
	 */
	private URI buildUri(Map<String, String> params) {

		UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl);

		if (params != null) {
			for (Map.Entry<String, String> entry : params.entrySet()) {
				// 예약 키 'path' 는 쿼리가 아니라 경로 세그먼트로 처리
				if ("path".equals(entry.getKey())) {
					builder.path(entry.getValue());
				} else {
					builder.queryParam(entry.getKey(), entry.getValue());
				}
			}
		}

		// 인증 키 부착
		builder.queryParam("serviceKey", serviceKey);

		// serviceKeyEncoded=true 면 이미 인코딩된 값이므로 재인코딩하지 않는다.
		return builder.build(serviceKeyEncoded).toUri();
	}
}
