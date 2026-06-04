package com.disabled.external.weather;

import java.util.ArrayList;
import java.util.List;

/**
 * 기상청 단기예보 파싱 결과 DTO.
 *
 * <p>격자/좌표/발표기준시각 정보와, 예보 시각(fcstDate+fcstTime)별로 묶은 핵심 항목 슬롯 목록을 담는다.
 * 좌표 정보({@code nx/ny/lat/lng})를 객체 자체에 포함하므로, 여러 좌표를 동시에 조회할 때는
 * {@code List<WeatherForecast>} 형태로 자연스럽게 확장된다.</p>
 *
 * <p>본 프로젝트의 Jackson(2.9.4)은 record 직렬화를 지원하지 않으므로, 컨트롤러 응답으로 직렬화되는
 * 본 DTO는 record 가 아닌 getter 보유 일반 클래스로 작성한다.</p>
 */
public class WeatherForecast {

	/** X축 격자 번호 */
	private int nx;
	/** Y축 격자 번호 */
	private int ny;
	/** 요청 위도 */
	private double lat;
	/** 요청 경도 */
	private double lng;
	/** 발표 기준 날짜 (yyyyMMdd) */
	private String baseDate;
	/** 발표 기준 시간 (HHmm) */
	private String baseTime;
	/** API가 보고한 전체 항목 수 */
	private int totalCount;
	/** 실제 수신한 item 수 */
	private int itemCount;
	/** 예보 시각별 슬롯 목록 */
	private List<ForecastSlot> slots = new ArrayList<>();

	/**
	 * 예보 시각 1개(fcstDate+fcstTime)에 대한 핵심 카테고리 묶음.
	 */
	public static class ForecastSlot {

		/** 예보 날짜 (yyyyMMdd) */
		private String fcstDate;
		/** 예보 시각 (HHmm) */
		private String fcstTime;
		/** TMP : 1시간 기온(℃) */
		private String tmp;
		/** POP : 강수확률(%) */
		private String pop;
		/** REH : 습도(%) */
		private String reh;
		/** SKY : 하늘상태 코드(1/3/4) */
		private String skyCode;
		/** SKY : 하늘상태 한글 */
		private String sky;
		/** PTY : 강수형태 코드(0~4) */
		private String ptyCode;
		/** PTY : 강수형태 한글 */
		private String pty;

		public String getFcstDate() {
			return fcstDate;
		}

		public void setFcstDate(String fcstDate) {
			this.fcstDate = fcstDate;
		}

		public String getFcstTime() {
			return fcstTime;
		}

		public void setFcstTime(String fcstTime) {
			this.fcstTime = fcstTime;
		}

		public String getTmp() {
			return tmp;
		}

		public void setTmp(String tmp) {
			this.tmp = tmp;
		}

		public String getPop() {
			return pop;
		}

		public void setPop(String pop) {
			this.pop = pop;
		}

		public String getReh() {
			return reh;
		}

		public void setReh(String reh) {
			this.reh = reh;
		}

		public String getSkyCode() {
			return skyCode;
		}

		public void setSkyCode(String skyCode) {
			this.skyCode = skyCode;
		}

		public String getSky() {
			return sky;
		}

		public void setSky(String sky) {
			this.sky = sky;
		}

		public String getPtyCode() {
			return ptyCode;
		}

		public void setPtyCode(String ptyCode) {
			this.ptyCode = ptyCode;
		}

		public String getPty() {
			return pty;
		}

		public void setPty(String pty) {
			this.pty = pty;
		}
	}

	public int getNx() {
		return nx;
	}

	public void setNx(int nx) {
		this.nx = nx;
	}

	public int getNy() {
		return ny;
	}

	public void setNy(int ny) {
		this.ny = ny;
	}

	public double getLat() {
		return lat;
	}

	public void setLat(double lat) {
		this.lat = lat;
	}

	public double getLng() {
		return lng;
	}

	public void setLng(double lng) {
		this.lng = lng;
	}

	public String getBaseDate() {
		return baseDate;
	}

	public void setBaseDate(String baseDate) {
		this.baseDate = baseDate;
	}

	public String getBaseTime() {
		return baseTime;
	}

	public void setBaseTime(String baseTime) {
		this.baseTime = baseTime;
	}

	public int getTotalCount() {
		return totalCount;
	}

	public void setTotalCount(int totalCount) {
		this.totalCount = totalCount;
	}

	public int getItemCount() {
		return itemCount;
	}

	public void setItemCount(int itemCount) {
		this.itemCount = itemCount;
	}

	public List<ForecastSlot> getSlots() {
		return slots;
	}

	public void setSlots(List<ForecastSlot> slots) {
		this.slots = slots;
	}
}
