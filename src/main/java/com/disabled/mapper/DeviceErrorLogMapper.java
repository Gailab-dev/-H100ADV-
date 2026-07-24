package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * 디바이스 이상 로그 SQL (작업계획서 15 §4-5 / 신설 테이블 tbl_device_error_log)
 *  - INSERT 는 Go module_c(DeviceStatusHandler)가 상태 변경 시점에 담당. 웹은 조회만 한다.
 *  - MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 */
@Mapper
@Repository
public interface DeviceErrorLogMapper {

	// 특정 디바이스의 최근 이상 로그. paramMap: dvId, limit
	List<Map<String, Object>> selectRecentByDevice(Map<String, Object> paramMap) throws IllegalStateException;
}
