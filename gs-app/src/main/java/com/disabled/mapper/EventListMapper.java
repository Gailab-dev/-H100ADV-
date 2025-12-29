package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface EventListMapper {
	List<Map<String, Object>> getEventList(Map<String,Object> paramMap) throws RuntimeException;
	List<Map<String, Object>> getEventListJoinSerial(Map<String,Object> paramMap) throws RuntimeException;
	Map<String,Object> getEventListDetail(@Param("dvId") Integer dvId, @Param("evId") Integer evId) throws RuntimeException;
	String getDvIpByEvId(@Param("dvId") Integer dvId, @Param("evId") Integer evId) throws RuntimeException;
	void updateEvHasImgOne(@Param("evId") Integer evId) throws RuntimeException;
	void updateEvHasMovOne(@Param("evId") Integer evId) throws RuntimeException;
	int getTotalRecordCount(@Param("startDate") String startDate, @Param("endDate") String endDate, @Param("searchKeyword") String searchKeyword) throws RuntimeException;
	int getTotalRecordCountJoinSerial(@Param("startDate") String startDate, @Param("endDate") String endDate, @Param("searchKeyword") String searchKeyword) throws RuntimeException;
}
