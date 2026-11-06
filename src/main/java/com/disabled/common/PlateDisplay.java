package com.disabled.common;

import java.util.List;
import java.util.Map;

/**
 * 차량번호 화면 표시 규칙(작업계획서 2026-11-06 WP-C, 결정 D-5·D-6).
 * <p>
 * 화면 표시용 값 {@code ev_car_num_display} 만 만든다. DB·API 의 원본 {@code ev_car_num}, 검색·정렬·엑셀은 바꾸지 않는다.
 * 문구는 {@link #NO_PLATE_TEXT} 한 곳에서만 정의한다.
 * <ul>
 * <li>ev_cd 4(위험상황)·5(물건적재)·6(이중주차): 번호 값이 있어도 항상 "해당없음"</li>
 * <li>ev_cd 1(미등록차량): 현행 유지(번호 그대로, 비어 있으면 빈 값)</li>
 * <li>그 외(3 스티커 불법 사용 포함): 번호가 비어 있으면 "해당없음", 있으면 그대로</li>
 * </ul>
 * "비어 있음" = null · 빈 문자열 · 공백뿐 · 하이픈뿐('-' 등 자리표시).
 */
public final class PlateDisplay {

	/** 번호가 해당되지 않을 때 화면에 보여 줄 문구(공백 없음). */
	public static final String NO_PLATE_TEXT = "해당없음";

	/** 화면 표시용 값을 담는 키. */
	public static final String DISPLAY_KEY = "ev_car_num_display";

	private PlateDisplay() {
	}

	public static String display(Object evCd, Object plate) {
		int cd = toInt(evCd);
		if (cd == 4 || cd == 5 || cd == 6) {
			return NO_PLATE_TEXT;
		}
		String text = plate == null ? "" : plate.toString();
		if (cd == 1) {
			return text;
		}
		return isBlankPlate(text) ? NO_PLATE_TEXT : text;
	}

	/** 행 맵에 표시용 값을 추가한다(원본 값은 그대로 둔다). null 이면 무시한다. */
	public static void apply(Map<String, Object> row) {
		if (row == null) {
			return;
		}
		row.put(DISPLAY_KEY, display(row.get("ev_cd"), row.get("ev_car_num")));
	}

	public static void applyAll(List<Map<String, Object>> rows) {
		if (rows == null) {
			return;
		}
		for (Map<String, Object> row : rows) {
			apply(row);
		}
	}

	private static boolean isBlankPlate(String text) {
		String t = text.trim();
		return t.isEmpty() || t.matches("[-\\u2010-\\u2015\\s]+");
	}

	private static int toInt(Object value) {
		if (value instanceof Number) {
			return ((Number) value).intValue();
		}
		if (value == null) {
			return -1;
		}
		try {
			return Integer.parseInt(value.toString().trim());
		} catch (NumberFormatException e) {
			return -1;
		}
	}
}
