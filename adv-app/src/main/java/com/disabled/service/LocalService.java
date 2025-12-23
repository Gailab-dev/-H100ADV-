package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface LocalService {

	List<Map<String, Object>> getLocalList();

	Integer saveLocalManage(List<Map<String, Object>> mappedJson);

	Map<String,Object> getUserUsingLocal(List<Map<String, Object>> mappedJson);

}
