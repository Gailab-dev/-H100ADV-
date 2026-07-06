package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * SIP CALL 로그 화면 SQL (작업계획서 07 / DB설계서 v0.0.7 tbl_sip_call = AP_DB_0012)
 * - 기존 이벤트/디바이스 매퍼와 동일하게 MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 */
@Mapper
@Repository
public interface SipCallMapper {

	// 조회(필터 + 페이지네이션). paramMap: keyword, startDate, endDate, listSize, offset
	List<Map<String, Object>> selectList(Map<String, Object> paramMap) throws IllegalStateException;

	// 조회 총 갯수(동일 필터)
	int countList(Map<String, Object> paramMap) throws IllegalStateException;

	// 단건 조회(오디오 재생용)
	Map<String, Object> selectById(Integer scId) throws IllegalStateException;
}
