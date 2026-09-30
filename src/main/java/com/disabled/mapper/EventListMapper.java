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

	Map<String,Object> getEventListDetail(@Param("evId") Integer evId) throws RuntimeException;
	Map<String,Object> getEventListDetail(@Param("evId") Integer evId, @Param("evId2") Integer evId2) throws RuntimeException;
	String getDvIpByEvId(@Param("evId") Integer evId) throws RuntimeException;
	void updateEvHasImgOne(@Param("evId") Integer evId) throws RuntimeException;
	void updateEvHasMovOne(@Param("evId") Integer evId) throws RuntimeException;
	int getTotalRecordCountJoinSerial(@Param("startDate") String startDate, @Param("endDate") String endDate, @Param("searchKeyword") String searchKeyword) throws RuntimeException;
	int getTotalRecordCount(Map<String, Object> paramMap) throws RuntimeException;
	List<Map<String, Object>> getEventCountByEvCd(Map<String, Object> paramMap) throws RuntimeException; // ev_cd별 이벤트 건수

	// ====== 패치 2026-09-30 — 상세보기 이전/다음 탐색, 소프트 삭제 ======
	Integer getAdjacentEventId(Map<String, Object> paramMap) throws RuntimeException;
	int softDeleteEvents(Map<String, Object> paramMap) throws RuntimeException;

}
