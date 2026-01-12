package com.disabled.common;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import org.springframework.stereotype.Service;

@Service
public class CommonValidation {
	/**
	 * 날짜 형식 검증 (yyyy-MM-dd)
	 * @param dateStr 날짜 문자열
	 * @return 유효한 날짜 형식이면 true
	 */
	public boolean isValidDate(String dateStr) {
		if (dateStr == null || dateStr.isEmpty()) {
			return false;
		}

		// 날짜 형식 정규식 검증 (yyyy-MM-dd)
		if (!dateStr.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
			return false;
		}

		// 실제 날짜 유효성 검증
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		sdf.setLenient(false);
		try {
			sdf.parse(dateStr);
			return true;
		} catch (ParseException e) {
			return false;
		}
	}
}
