package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface EventListService {
	List<Map<String, Object>> getEventList();
	Integer getEventListCount();
	Map<String, Object> getEventListDetail(Integer evId);
}
