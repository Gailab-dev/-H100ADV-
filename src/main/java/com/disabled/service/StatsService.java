package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface StatsService {
	List<Map<String,Object>> getEventByMonth(String startDate, String endDate);
	List<Map<String,Object>> getEventByMonth();
	List<Map<String, Object>> getEventByMonthAndSearchParams(Map<String, Object> paramMap);
}
