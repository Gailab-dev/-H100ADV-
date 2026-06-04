package com.disabled.external.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

/**
 * 외부 API 연동용 공통 RestTemplate 설정.
 *
 * <p>기존 {@code CryptoConfig} 와 동일하게 {@code globals.properties} 를 PropertySource 로 사용한다.
 * HTTP 연결/응답 타임아웃은 properties 로 변경 가능하며 기본값은 각 10초이다.</p>
 *
 * <p>외부 라이브러리 추가 없이 JDK 표준 HttpURLConnection 기반
 * {@link SimpleClientHttpRequestFactory} 를 사용한다. (커넥션 풀이 필요해지면
 * 향후 Apache HttpComponents 기반 팩토리로 교체 가능.)</p>
 */
@Configuration
@PropertySource("classpath:globals.properties")
public class ExternalApiConfig {

	/** 연결 타임아웃(ms) */
	@Value("${external.api.timeout.connect-millis:10000}")
	private int connectTimeout;

	/** 응답(읽기) 타임아웃(ms) */
	@Value("${external.api.timeout.read-millis:10000}")
	private int readTimeout;

	/**
	 * 본 (servlet) 컨텍스트에서 {@code @Value("${...}")} 해석을 보장하기 위한 플레이스홀더 리졸버.
	 *
	 * <p>플레이스홀더 리졸버는 BeanFactoryPostProcessor 라서 부모(root) 컨텍스트의 것이
	 * 자식(servlet) 컨텍스트로 상속되지 않는다. 따라서 servlet 컨텍스트에 별도로 둔다.
	 * 다른 빈의 미해석 플레이스홀더까지 건드리지 않도록 {@code ignoreUnresolvablePlaceholders=true}
	 * 로 두어 기존 동작에 영향을 주지 않는다. (static 메서드여야 BFPP 로 정상 동작)</p>
	 */
	@Bean
	public static PropertySourcesPlaceholderConfigurer externalApiPropertyConfigurer() {
		PropertySourcesPlaceholderConfigurer configurer = new PropertySourcesPlaceholderConfigurer();
		configurer.setIgnoreUnresolvablePlaceholders(true);
		return configurer;
	}

	/**
	 * 외부 API 전용 RestTemplate.
	 * 빈 이름을 명시하여 향후 다른 RestTemplate 빈이 추가되어도 타입 충돌 없이 주입되도록 한다.
	 */
	@Bean("externalApiRestTemplate")
	public RestTemplate externalApiRestTemplate() {
		SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
		factory.setConnectTimeout(connectTimeout);
		factory.setReadTimeout(readTimeout);
		return new RestTemplate(factory);
	}
}
