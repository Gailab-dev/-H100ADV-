package com.disabled.external.scheduler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.disabled.external.adapter.WeatherApiAdapter;
import com.disabled.external.weather.WeatherForecast;

/**
 * 기상청 단기예보 정기 수집 스케줄러.
 *
 * <p>기상청 발표 시각(02·05·08·11·14·17·20·23시)의 10분 후에 기본 좌표 기준으로 예보를 수집한다.
 * 스케줄 활성화({@code @EnableScheduling})는 기존 {@code com.disabled.config.SchedulerConfig} 에
 * 이미 선언되어 있으므로 별도 추가가 필요 없다.</p>
 *
 * <p>현재는 수집 결과를 로그로만 출력한다. 향후 디바이스별 좌표 수집/캐시 저장 등으로 확장 가능하다.</p>
 */
@Component
public class WeatherFetchScheduler {

	private static final Logger logger = LoggerFactory.getLogger(WeatherFetchScheduler.class);

	@Autowired
	private WeatherApiAdapter weatherApiAdapter;

	/** 기본 좌표 위도 (광주광역시청) */
	@Value("${weather.location.default.lat:35.1595}")
	private double defaultLat;

	/** 기본 좌표 경도 (광주광역시청) */
	@Value("${weather.location.default.lng:126.8526}")
	private double defaultLng;

	/**
	 * 발표 시각 10분 후 정기 수집.
	 * cron 필드: 초 분 시 일 월 요일
	 * (테스트 시 매 분 호출하려면 "0 * * * * *" 로 임시 변경)
	 */
	@Scheduled(cron = "0 10 2,5,8,11,14,17,20,23 * * *")
	public void scheduledFetch() {

		logger.info("[WeatherFetchScheduler] 단기예보 정기 수집 시작 (기본좌표 lat={}, lng={})",
				defaultLat, defaultLng);

		try {
			WeatherForecast forecast = weatherApiAdapter.getForecast(defaultLat, defaultLng);

			if (forecast.getSlots().isEmpty()) {
				logger.warn("[WeatherFetchScheduler] 수집 결과 슬롯이 비어 있습니다. base={} {} nx={} ny={}",
						forecast.getBaseDate(), forecast.getBaseTime(), forecast.getNx(), forecast.getNy());
				return;
			}

			WeatherForecast.ForecastSlot first = forecast.getSlots().get(0);
			logger.info("[WeatherFetchScheduler] 수집 완료 base={} {} nx={} ny={} | 최근슬롯 {}시 "
					+ "기온={}℃ 강수확률={}% 하늘={} 강수={} 습도={}%",
					forecast.getBaseDate(), forecast.getBaseTime(), forecast.getNx(), forecast.getNy(),
					first.getFcstTime(), first.getTmp(), first.getPop(),
					first.getSky(), first.getPty(), first.getReh());

		} catch (Exception e) {
			logger.error("[WeatherFetchScheduler] 단기예보 수집 실패: {}", e.getMessage(), e);
		}
	}
}
