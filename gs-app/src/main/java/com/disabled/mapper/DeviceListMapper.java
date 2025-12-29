package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface DeviceListMapper {
	List<Map<String, Object>> getDeviceInfo(Map<String, Object> paramMap) throws IllegalStateException;
	String getDvIpByDvId(@Param("dvId") int dvId) throws IllegalStateException;
	Integer getTotalRecordCount(@Param("searchKeyword") String searchKeyword) throws IllegalStateException;;
	Integer updateDeviceInfo(@Param("dvId") Integer dvId, @Param("dvName") String dvName, @Param("dvAddr") String dvAddr, @Param("dvIp") String dvIp, @Param("dvStatus") Integer dvStatus, @Param("dvSerialNumber") String dvSerialNumber) throws IllegalStateException;
	Integer deleteDeviceInfo(@Param("dvId") Integer dvId) throws IllegalStateException;
	Integer insertDeviceInfo(@Param("dvName") String dvName, @Param("dvAddr") String dvAddr, @Param("dvIp") String dvIp, @Param("dvStatus") Integer dvStatus, @Param("dvSerialNumber") String dvSerialNumber) throws IllegalStateException;
	Map<String, Object> getOneDeviceInfo(@Param("dvId") Integer dvId) throws IllegalStateException;
	int getDeviceCountDvNameAndAddr(Map<String, Object> body) throws IllegalStateException;
	
	// 모든 디바이스 ip 조회
	List<String> getAllDvIp() throws IllegalStateException;
	
	// 디바이스 IP별 상태값 수정
	Integer updateDeviceStatus(@Param("dvStatus") Integer dvStatus, @Param("dvIp") String dvIp) throws IllegalStateException;
}
