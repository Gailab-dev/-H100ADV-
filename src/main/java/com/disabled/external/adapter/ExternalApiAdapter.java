package com.disabled.external.adapter;

import java.util.Map;

import com.disabled.external.dto.ExternalApiResponse;

/**
 * 외부 공공 API 연동을 위한 공통 어댑터 인터페이스.
 *
 * <p>비즈니스 로직이 특정 외부 API(공공데이터포털, 기상청, 행정정보공동이용센터 등)에
 * 직접 결합되지 않도록 하기 위한 추상화 계층이다. 각 외부 API는 본 인터페이스의
 * 구현체(어댑터)로 캡슐화되며, 호출 측은 {@link ExternalApiResponse} 라는
 * 단일 응답 타입만 다루면 된다.</p>
 *
 * <p>공통 처리(타임아웃·재시도·로깅·에러 분류)는 {@link AbstractExternalApiAdapter}
 * 에서 제공하므로, 신규 어댑터는 보통 해당 추상 클래스를 상속하여 API별 특화 로직만 구현한다.</p>
 */
public interface ExternalApiAdapter {

	/**
	 * 외부 API를 호출하고 결과를 공통 응답 DTO로 반환한다.
	 *
	 * @param params 호출 파라미터 (쿼리 파라미터 등). null 허용 안 함(빈 Map 사용)
	 * @return 호출 결과 (성공/실패 무관하게 항상 non-null)
	 */
	ExternalApiResponse fetch(Map<String, String> params);

	/**
	 * 어댑터 식별명 반환 (로깅·라우팅용). 어댑터마다 고유해야 한다.
	 *
	 * @return 어댑터 식별명 (예: "PublicDataAdapter")
	 */
	String getName();

	/**
	 * 외부 API에 연결 가능한지(살아 있는지) 확인한다.
	 *
	 * @return 연결 가능하면 true
	 */
	boolean healthCheck();
}
