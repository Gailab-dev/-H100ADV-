package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface StatsService {
	Integer loginCheck(String id, String pwd);
	List<Map<String,Object>> getEventByMonth(String startDate, String endDate);
	List<Map<String,Object>> getEventByMonth();
}
