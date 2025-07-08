package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;

@Mapper
public interface StatsMapper {
	List<Map<String,Object>> getEventByMonth( Map<String,Object> param);
	List<Map<String,Object>> getAllEvent();
}
