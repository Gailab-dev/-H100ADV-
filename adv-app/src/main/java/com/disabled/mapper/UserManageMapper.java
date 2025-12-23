package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;

@Mapper
public interface UserManageMapper {

	int getTotalRecordCount(Map<String, Object> paramMap) throws IllegalStateException;

	List<Map<String, Object>> getUserManageList(Map<String, Object> paramMap) throws IllegalStateException;

	Integer getRegionByAdmin(Integer uId);

}
