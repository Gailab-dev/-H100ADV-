package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface DeviceListMapper {
	List<Map<String, Object>> getDeviceInfo() throws DataAccessException;
	String getDvIpByDvId(@Param("dvId") int dvId) throws DataAccessException;
}
