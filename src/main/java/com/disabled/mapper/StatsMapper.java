package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.dao.DataAccessException;

@Mapper
public interface StatsMapper {
	List<Map<String,Object>> getEventByMonth(Map<String,Object> param) throws DataAccessException;
	List<Map<String,Object>> getAllEvent() throws DataAccessException;
	List<Map<String, Object>> getEventByMonthAndSearchParams(@Param("startDate") String startDate, @Param("endDate") String endDate, @Param("stCd") Integer stCd) throws IllegalStateException;
}
