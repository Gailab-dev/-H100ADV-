package com.disabled.external.weather;

/**
 * 기상청 단기예보 위경도 ↔ 격자(nx, ny) 좌표 변환 유틸.
 *
 * <p>기상청이 공식 제공한 C 언어 Lambert Conformal Conic Projection 변환 코드를 Java 17로 포팅한 것이다.
 * 원본 C 코드의 {@code first==0} 초기화 블록(지도 파라미터 계산)은 클래스 로딩 시 한 번만 수행되도록
 * static initializer 로 옮겼다.</p>
 *
 * <p><b>격자 정수화 규칙</b> : 정방향({@link #latLngToGrid})은 연속 좌표에 {@code +1.5} 를 더해 내림하여
 * 기상청 공식 격자 번호를 얻는다. 역방향({@link #gridToLatLng})은 이 {@code +1.5} 보정을 되돌리기 위해
 * 대표 연속 좌표({@code grid - 1})를 사용한다. 이렇게 해야 기상청이 공개한 검증 케이스와 수치가 일치한다.</p>
 *
 * <p>검증 케이스(기상청/내부 확인):</p>
 * <ul>
 *   <li>광주광역시청 (35.1595, 126.8526) → 격자 (58, 74)</li>
 *   <li>격자 (59, 125) → (위도 37.488201, 경도 126.929810)</li>
 * </ul>
 */
public final class WeatherGridConverter {

	// ===== 지도 정보 초기값 (원본 C 코드의 map 구조체 값) =====
	/** 사용할 지구반경 [km] */
	private static final double RE = 6371.00877;
	/** 격자간격 [km] */
	private static final double GRID = 5.0;
	/** 표준위도 1 [degree] */
	private static final double SLAT1 = 30.0;
	/** 표준위도 2 [degree] */
	private static final double SLAT2 = 60.0;
	/** 기준점 경도 [degree] */
	private static final double OLON = 126.0;
	/** 기준점 위도 [degree] */
	private static final double OLAT = 38.0;
	/** 기준점 X좌표 [격자거리] (210/grid = 42) */
	private static final double XO = 210.0 / GRID;
	/** 기준점 Y좌표 [격자거리] (675/grid = 135) */
	private static final double YO = 675.0 / GRID;

	private static final double PI = Math.asin(1.0) * 2.0;
	private static final double DEGRAD = PI / 180.0;
	private static final double RADDEG = 180.0 / PI;

	/** 격자거리로 환산한 지구반경 (re = RE/GRID) */
	private static final double RE_GRID = RE / GRID;

	// ===== C 코드 first==0 초기화 블록에서 1회 계산되는 투영 파라미터 =====
	private static final double SN;
	private static final double SF;
	private static final double RO;

	static {
		double slat1 = SLAT1 * DEGRAD;
		double slat2 = SLAT2 * DEGRAD;
		double olat = OLAT * DEGRAD;

		double sn = Math.tan(PI * 0.25 + slat2 * 0.5) / Math.tan(PI * 0.25 + slat1 * 0.5);
		sn = Math.log(Math.cos(slat1) / Math.cos(slat2)) / Math.log(sn);

		double sf = Math.tan(PI * 0.25 + slat1 * 0.5);
		sf = Math.pow(sf, sn) * Math.cos(slat1) / sn;

		double ro = Math.tan(PI * 0.25 + olat * 0.5);
		ro = RE_GRID * sf / Math.pow(ro, sn);

		SN = sn;
		SF = sf;
		RO = ro;
	}

	private WeatherGridConverter() {
		// 유틸 클래스 - 인스턴스화 금지
	}

	/**
	 * 위경도 → 격자 좌표 변환 (원본 C 코드 {@code code == 0} 분기).
	 *
	 * @param lat 위도(degree)
	 * @param lng 경도(degree)
	 * @return 격자 좌표 (nx, ny)
	 */
	public static Grid latLngToGrid(double lat, double lng) {
		double olon = OLON * DEGRAD;

		double ra = Math.tan(PI * 0.25 + lat * DEGRAD * 0.5);
		ra = RE_GRID * SF / Math.pow(ra, SN);

		double theta = lng * DEGRAD - olon;
		if (theta > PI) {
			theta -= 2.0 * PI;
		}
		if (theta < -PI) {
			theta += 2.0 * PI;
		}
		theta *= SN;

		double x = ra * Math.sin(theta) + XO;
		double y = RO - ra * Math.cos(theta) + YO;

		// 연속 좌표 → 공식 격자 번호 (+1.5 후 내림)
		int nx = (int) Math.floor(x + 1.5);
		int ny = (int) Math.floor(y + 1.5);
		return new Grid(nx, ny);
	}

	/**
	 * 격자 좌표 → 위경도 변환 (원본 C 코드 {@code code != 0} 분기).
	 *
	 * <p>정방향의 {@code +1.5} 격자 보정을 되돌리기 위해 대표 연속 좌표 {@code (nx-1, ny-1)} 를 사용한다.</p>
	 *
	 * @param nx X축 격자 번호
	 * @param ny Y축 격자 번호
	 * @return 위경도 좌표
	 */
	public static LatLng gridToLatLng(int nx, int ny) {
		double olon = OLON * DEGRAD;

		double xn = (nx - 1) - XO;
		double yn = RO - (ny - 1) + YO;

		double ra = Math.sqrt(xn * xn + yn * yn);
		// 원본 C 코드 'if (sn<0.0) -ra;' 의 의도(부호 반전)를 반영. 현재 파라미터에서 sn>0 이라 실제 분기 없음.
		if (SN < 0.0) {
			ra = -ra;
		}

		double alat = Math.pow((RE_GRID * SF / ra), (1.0 / SN));
		alat = 2.0 * Math.atan(alat) - PI * 0.5;

		double theta;
		if (Math.abs(xn) <= 0.0) {
			theta = 0.0;
		} else if (Math.abs(yn) <= 0.0) {
			theta = PI * 0.5;
			if (xn < 0.0) {
				theta = -theta;
			}
		} else {
			theta = Math.atan2(xn, yn);
		}

		double alon = theta / SN + olon;
		return new LatLng(alat * RADDEG, alon * RADDEG);
	}
}
