package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface UserManageService {

	int getTotalRecordCount(Map<String, Object> paramMap);

	List<Map<String, Object>> getUserManageList(Map<String, Object> paramMap);

	Integer getRegionByAdmin(Integer uId);

}
