package com.disabled.external.adapter;

import java.net.URI;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import com.disabled.external.dto.ExternalApiResponse;
import com.disabled.external.exception.ExternalApiException;
import com.disabled.external.exception.ExternalApiException.ErrorType;
import com.disabled.external.weather.Grid;
import com.disabled.external.weather.WeatherForecast;
import com.disabled.external.weather.WeatherGridConverter;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 기상청 단기예보조회 서비스(공공데이터포털 VilageFcstInfoService_2.0) 어댑터.
 *
 * <p>{@link AbstractExternalApiAdapter} 의 공통 처리(타임아웃·재시도·로깅·에러 분류) 위에서,
 * 위경도→격자 변환, 발표 기준 시각 계산, JSON 파싱 등 기상청 특화 로직만 구현한다.</p>
 *
 * <p>인증키는 환경변수 {@code WEATHER_API_KEY} 로만 주입한다(코드/Git 미포함). 미설정 시 기동은
 * 정상 진행하되 경고 로그를 남기고, 실제 호출 시 명확한 실패 메시지를 반환한다.</p>
 */
@Component("weatherApiAdapter")
public class WeatherApiAdapter extends AbstractExternalApiAdapter {

	/** 단기예보조회 오퍼레이션 경로 */
	private static final String OP_VILAGE_FCST = "/getVilageFcst";

	/** 발표 시각 (02·05·08·11·14·17·20·23시) */
	private static final int[] BASE_HOURS = {2, 5, 8, 11, 14, 17, 20, 23};

	/** 발표 후 데이터 제공까지의 지연(분). 이 시간 이전에는 직전 발표분을 사용 */
	private static final int API_DELAY_MINUTES = 10;

	private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

	/** 베이스 URL */
	@Value("${external.api.weather.base-url:https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0}")
	private String baseUrl;

	/** 인증 ServiceKey (환경변수 WEATHER_API_KEY) */
	@Value("${external.api.weather.service-key:}")
	private String serviceKey;

	/** ServiceKey 가 이미 URL 인코딩된 값인지 여부 (Encoding 키=true) */
	@Value("${external.api.weather.service-key-encoded:true}")
	private boolean serviceKeyEncoded;

	/** 트리 모델 파싱용 (record 미지원 Jackson 2.9 호환을 위해 JsonNode 사용) */
	private final ObjectMapper objectMapper =
			new ObjectMapper().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

	/**
	 * 기동 시 인증키 설정 여부 점검. 미설정이어도 컨텍스트 기동은 막지 않는다(대시보드 부가기능이므로
	 * 전체 서비스 중단을 유발하지 않도록). 대신 장애 원인 파악을 위해 경고를 남긴다.
	 */
	@PostConstruct
	void verifyServiceKey() {
		if (serviceKey == null || serviceKey.trim().isEmpty()) {
			logger.warn("[{}] 환경변수 WEATHER_API_KEY 가 설정되지 않았습니다. "
					+ "기상청 API 호출은 실패합니다. (환경변수 설정 절차서 참고)", getName());
		}
	}

	@Override
	public String getName() {
		return "WeatherApiAdapter";
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

	// ------------------------------------------------------------------
	// 기상청 특화 공개 API
	// ------------------------------------------------------------------

	/**
	 * 지정 위경도의 단기예보를 조회·파싱한다.
	 *
	 * @param lat 위도
	 * @param lng 경도
	 * @return 파싱된 예보 결과
	 * @throws ExternalApiException 호출 실패 또는 파싱/결과코드 오류 시
	 */
	public WeatherForecast getForecast(double lat, double lng) {

		Grid grid = WeatherGridConverter.latLngToGrid(lat, lng);
		String[] base = computeBaseDateTime(LocalDateTime.now());
		String baseDate = base[0];
		String baseTime = base[1];

		logger.info("[{}] 단기예보 호출 시작 base_date={} base_time={} nx={} ny={} (lat={}, lng={})",
				getName(), baseDate, baseTime, grid.nx(), grid.ny(), lat, lng);

		Map<String, String> params = new LinkedHashMap<>();
		params.put("pageNo", "1");
		params.put("numOfRows", "1000");
		params.put("dataType", "JSON");
		params.put("base_date", baseDate);
		params.put("base_time", baseTime);
		params.put("nx", String.valueOf(grid.nx()));
		params.put("ny", String.valueOf(grid.ny()));

		// 공통 처리(타임아웃·재시도·로깅·HTTP 에러 분류)는 상위 fetch() 가 담당
		ExternalApiResponse res = fetch(params);
		if (!res.isSuccess()) {
			throw new ExternalApiException(ErrorType.UNKNOWN,
					"기상청 호출 실패: " + res.getErrorMessage(), null);
		}

		WeatherForecast forecast = parse(res.getBody(), grid, lat, lng, baseDate, baseTime);
		logger.info("[{}] 응답 수신 응답시간={}ms totalCount={} 추출슬롯수={}",
				getName(), res.getElapsedMillis(), forecast.getTotalCount(), forecast.getSlots().size());
		return forecast;
	}

	// ------------------------------------------------------------------
	// 내부 처리
	// ------------------------------------------------------------------

	/**
	 * 베이스 URL + 오퍼레이션 경로 + 파라미터 + serviceKey 로 최종 URI 조립.
	 */
	private URI buildUri(Map<String, String> params) {
		UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(baseUrl).path(OP_VILAGE_FCST);
		if (params != null) {
			for (Map.Entry<String, String> entry : params.entrySet()) {
				builder.queryParam(entry.getKey(), entry.getValue());
			}
		}
		builder.queryParam("serviceKey", serviceKey);
		// serviceKeyEncoded=true 면 이미 인코딩된 값이므로 재인코딩하지 않는다.
		return builder.build(serviceKeyEncoded).toUri();
	}

	/**
	 * 현재 시각 기준 가장 최근에 제공 가능한 발표 날짜/시각을 계산한다.
	 * 발표 후 {@link #API_DELAY_MINUTES} 분이 지나야 데이터가 제공되므로 이를 보정하며,
	 * 02:10 이전이면 전일 23시 발표분을 사용한다.
	 *
	 * @return [0]=base_date(yyyyMMdd), [1]=base_time(HHmm)
	 */
	private String[] computeBaseDateTime(LocalDateTime now) {
		LocalDateTime effective = now.minusMinutes(API_DELAY_MINUTES);
		int hour = effective.getHour();

		int chosen = -1;
		for (int h : BASE_HOURS) {
			if (h <= hour) {
				chosen = h;
			}
		}

		LocalDateTime baseDt;
		if (chosen == -1) {
			// 첫 발표(02시) 제공 이전 → 전일 23시 발표분
			baseDt = effective.minusDays(1).withHour(23);
		} else {
			baseDt = effective.withHour(chosen);
		}

		return new String[] {
				baseDt.format(DATE_FMT),
				String.format("%02d00", baseDt.getHour())
		};
	}

	/**
	 * 기상청 JSON 응답을 파싱하여 핵심 카테고리(TMP/POP/SKY/PTY/REH)를 예보 시각별 슬롯으로 묶는다.
	 */
	private WeatherForecast parse(String body, Grid grid, double lat, double lng,
			String baseDate, String baseTime) {
		try {
			JsonNode root = objectMapper.readTree(body);
			JsonNode header = root.path("response").path("header");
			String resultCode = header.path("resultCode").asText("");
			String resultMsg = header.path("resultMsg").asText("");

			if (!"00".equals(resultCode)) {
				// 인증키 오류/쿼터 초과/NODATA 등은 재시도해도 동일하므로 CLIENT_ERROR 로 분류
				throw new ExternalApiException(ErrorType.CLIENT_ERROR,
						"기상청 오류 응답 resultCode=" + resultCode + " (" + resultMsg + ")", null);
			}

			JsonNode bodyNode = root.path("response").path("body");
			int totalCount = bodyNode.path("totalCount").asInt(0);
			JsonNode items = bodyNode.path("items").path("item");

			Map<String, WeatherForecast.ForecastSlot> slotMap = new LinkedHashMap<>();
			int itemCount = 0;

			if (items.isArray()) {
				for (JsonNode item : items) {
					itemCount++;
					String category = item.path("category").asText();
					String fcstDate = item.path("fcstDate").asText();
					String fcstTime = item.path("fcstTime").asText();
					String fcstValue = item.path("fcstValue").asText();

					String key = fcstDate + fcstTime;
					WeatherForecast.ForecastSlot slot = slotMap.computeIfAbsent(key, k -> {
						WeatherForecast.ForecastSlot s = new WeatherForecast.ForecastSlot();
						s.setFcstDate(fcstDate);
						s.setFcstTime(fcstTime);
						return s;
					});

					// 핵심 카테고리만 추출 (Java 17 switch expression)
					switch (category) {
						case "TMP" -> slot.setTmp(fcstValue);
						case "POP" -> slot.setPop(fcstValue);
						case "REH" -> slot.setReh(fcstValue);
						case "SKY" -> {
							slot.setSkyCode(fcstValue);
							slot.setSky(decodeSky(fcstValue));
						}
						case "PTY" -> {
							slot.setPtyCode(fcstValue);
							slot.setPty(decodePty(fcstValue));
						}
						default -> {
							// 그 외 카테고리(UUU, VVV, WSD 등)는 사용하지 않음
						}
					}
				}
			}

			if (totalCount != itemCount) {
				logger.warn("[{}] totalCount({})와 수신 item 수({})가 일치하지 않습니다.",
						getName(), totalCount, itemCount);
			}

			WeatherForecast forecast = new WeatherForecast();
			forecast.setNx(grid.nx());
			forecast.setNy(grid.ny());
			forecast.setLat(lat);
			forecast.setLng(lng);
			forecast.setBaseDate(baseDate);
			forecast.setBaseTime(baseTime);
			forecast.setTotalCount(totalCount);
			forecast.setItemCount(itemCount);
			forecast.setSlots(new ArrayList<>(slotMap.values()));
			return forecast;

		} catch (ExternalApiException e) {
			throw e;
		} catch (Exception e) {
			String snippet = (body == null) ? "null" : body.substring(0, Math.min(body.length(), 200));
			logger.error("[{}] 응답 파싱 실패: {} / body 앞부분=[{}]", getName(), e.getMessage(), snippet);
			throw new ExternalApiException(ErrorType.UNKNOWN, "기상청 응답 파싱 실패", e);
		}
	}

	/** SKY(하늘상태) 코드 → 한글 */
	private String decodeSky(String code) {
		return switch (code) {
			case "1" -> "맑음";
			case "3" -> "구름많음";
			case "4" -> "흐림";
			default -> "알수없음(" + code + ")";
		};
	}

	/** PTY(강수형태) 코드 → 한글 */
	private String decodePty(String code) {
		return switch (code) {
			case "0" -> "없음";
			case "1" -> "비";
			case "2" -> "비/눈";
			case "3" -> "눈";
			case "4" -> "소나기";
			default -> "알수없음(" + code + ")";
		};
	}
}
