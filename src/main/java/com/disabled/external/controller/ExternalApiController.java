package com.disabled.external.controller;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.disabled.external.adapter.ExternalApiAdapter;
import com.disabled.external.adapter.WeatherApiAdapter;
import com.disabled.external.dto.ExternalApiResponse;
import com.disabled.external.weather.WeatherForecast;

/**
 * 외부 공공 API 연동 신규 컨트롤러.
 *
 * <p>기존 {@code ApiService} 계층(디바이스 스트림 프록시)과 책임이 다르고 혼동을 피하기 위해
 * 별도의 {@code /api/external} 네임스페이스로 분리한다. (기존 코드는 일절 수정하지 않음)</p>
 *
 * <p>모든 {@link ExternalApiAdapter} 구현체를 {@code List} 로 주입받아 어댑터명으로 라우팅하므로,
 * 신규 어댑터를 {@code @Component} 로 추가하기만 하면 별도 컨트롤러 수정 없이 확장된다.</p>
 */
@RestController
@RequestMapping("/api/external")
public class ExternalApiController {

	private static final Logger logger = LoggerFactory.getLogger(ExternalApiController.class);

	/** 어댑터명 -> 어댑터 인스턴스 매핑 */
	private final Map<String, ExternalApiAdapter> adapters = new LinkedHashMap<>();

	/** 기상청 어댑터 (날씨 특화 엔드포인트용). 미등록 환경 대비 required=false */
	@Autowired(required = false)
	private WeatherApiAdapter weatherApiAdapter;

	/** 기본 좌표 위도 (광주광역시청) */
	@Value("${weather.location.default.lat:35.1595}")
	private double defaultLat;

	/** 기본 좌표 경도 (광주광역시청) */
	@Value("${weather.location.default.lng:126.8526}")
	private double defaultLng;

	/**
	 * 스프링이 모든 ExternalApiAdapter 빈을 주입한다.
	 * (어댑터가 하나도 없으면 컨텍스트 기동에 실패하지 않도록 required=false 로 둔다.)
	 */
	@Autowired(required = false)
	public ExternalApiController(List<ExternalApiAdapter> adapterList) {
		if (adapterList != null) {
			for (ExternalApiAdapter adapter : adapterList) {
				adapters.put(adapter.getName(), adapter);
				logger.info("외부 API 어댑터 등록: {}", adapter.getName());
			}
		}
	}

	/**
	 * 공공데이터포털 호출 예시 엔드포인트.
	 * 전달된 모든 쿼리 파라미터를 그대로 어댑터에 위임한다.
	 *
	 * <p>예: {@code GET /api/external/public-data?path=/B551182/.../getList&pageNo=1&numOfRows=10}</p>
	 *
	 * @param params 호출 파라미터 (serviceKey 는 어댑터가 자동 부착)
	 */
	@GetMapping("/public-data")
	public ResponseEntity<ExternalApiResponse> publicData(@RequestParam Map<String, String> params) {
		return invoke("PublicDataAdapter", params);
	}

	/**
	 * 기상청 단기예보 수동 테스트 엔드포인트.
	 * 스케줄러를 기다리지 않고 즉시 호출하여 파싱 결과를 JSON 으로 반환한다.
	 *
	 * <p>좌표 입력 정책(다층 fallback):</p>
	 * <ol>
	 *   <li>호출 시 명시적으로 전달된 (lat, lng)</li>
	 *   <li>(향후 확장) 디바이스 ID로 tbl_device 의 좌표 조회 — 현재 좌표 컬럼 미존재로 미구현</li>
	 *   <li>application/globals.properties 의 기본 좌표</li>
	 * </ol>
	 *
	 * @param lat 위도 (선택)
	 * @param lng 경도 (선택)
	 */
	@GetMapping("/weather/test")
	public ResponseEntity<?> weatherTest(
			@RequestParam(value = "lat", required = false) Double lat,
			@RequestParam(value = "lng", required = false) Double lng) {

		if (weatherApiAdapter == null) {
			logger.warn("weatherApiAdapter 가 등록되지 않았습니다.");
			Map<String, Object> err = new LinkedHashMap<>();
			err.put("success", false);
			err.put("error", "weatherApiAdapter 미등록");
			return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(err);
		}

		// 1순위: 명시 좌표 / 3순위: 기본 좌표 (2순위 디바이스 조회는 향후 확장)
		double useLat = (lat != null) ? lat : defaultLat;
		double useLng = (lng != null) ? lng : defaultLng;

		try {
			WeatherForecast forecast = weatherApiAdapter.getForecast(useLat, useLng);
			return ResponseEntity.ok(forecast);
		} catch (Exception e) {
			logger.error("날씨 테스트 호출 실패: {}", e.getMessage(), e);
			Map<String, Object> err = new LinkedHashMap<>();
			err.put("success", false);
			err.put("error", e.getMessage());
			return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(err);
		}
	}

	/**
	 * 등록된 모든 어댑터의 연결 상태를 확인한다.
	 *
	 * @return 어댑터명 -> 연결 가능 여부
	 */
	@GetMapping("/health")
	public ResponseEntity<Map<String, Boolean>> health() {
		Map<String, Boolean> result = new LinkedHashMap<>();
		for (Map.Entry<String, ExternalApiAdapter> entry : adapters.entrySet()) {
			boolean alive;
			try {
				alive = entry.getValue().healthCheck();
			} catch (Exception e) {
				logger.warn("healthCheck 예외 adapter={} msg={}", entry.getKey(), e.getMessage());
				alive = false;
			}
			result.put(entry.getKey(), alive);
		}
		return ResponseEntity.ok(result);
	}

	/**
	 * 어댑터명으로 조회 후 호출을 위임하는 공통 처리.
	 */
	private ResponseEntity<ExternalApiResponse> invoke(String adapterName, Map<String, String> params) {

		ExternalApiAdapter adapter = adapters.get(adapterName);
		if (adapter == null) {
			logger.warn("등록되지 않은 어댑터 요청: {}", adapterName);
			ExternalApiResponse notFound = new ExternalApiResponse();
			notFound.setAdapterName(adapterName);
			notFound.setSuccess(false);
			notFound.setErrorType("UNKNOWN");
			notFound.setErrorMessage("등록되지 않은 어댑터: " + adapterName);
			return ResponseEntity.status(HttpStatus.NOT_FOUND).body(notFound);
		}

		ExternalApiResponse response = adapter.fetch(params);

		// 호출 실패 시 502(Bad Gateway)로 매핑하여 외부 연동 실패임을 명확히 한다.
		HttpStatus status = response.isSuccess() ? HttpStatus.OK : HttpStatus.BAD_GATEWAY;
		return ResponseEntity.status(status).body(response);
	}
}
