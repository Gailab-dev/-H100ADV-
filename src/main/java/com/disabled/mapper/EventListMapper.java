package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface EventListMapper {
	List<Map<String, Object>> getEventList(Map<String,Object> paramMap) throws DataAccessException;
	Integer getEventListCount() throws DataAccessException;
	Map<String,Object> getEventListDetail(Integer evId) throws DataAccessException;
}
