package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * 웹 ROI 설정 SQL (34번 작업계획서 §4, 신설 테이블 tbl_roi_history / tbl_roi_snapshot).
 *  - 두 테이블은 운영자가 DDL 로 먼저 만든다(src/main/resources/sql/2026-10-20_ROI설정_테이블추가.sql). 앱은 DDL 을 실행하지 않는다.
 *  - 장비 조회(dv_serial_number, dv_ip)는 기존 DeviceListMapper.getOneDeviceInfo 를 쓴다.
 *  - MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 */
@Mapper
@Repository
public interface RoiMapper {

	/**
	 * 이력 INSERT(PENDING). paramMap: dvId, action, roiJson, metaJson, roiHash, baseHash, uName.
	 * 생성된 rh_id 는 paramMap 의 "rhId" 로 돌려받는다.
	 */
	int insertHistory(Map<String, Object> paramMap) throws IllegalStateException;

	/**
	 * 장비 값이 DB 와 달라 그대로 기록하는 SYNC 행(status=SUCCESS, u_name=SYSTEM). paramMap: dvId, roiJson, roiHash, metaJson(이름 보존용, null 가능).
	 * 생성된 rh_id 는 "rhId" 로 돌려받는다.
	 */
	int insertSyncHistory(Map<String, Object> paramMap) throws IllegalStateException;

	/** 장치의 PENDING 이력(rh_id, rh_roi_hash, age_min=요청 후 경과 분). */
	List<Map<String, Object>> selectPending(@Param("dvId") int dvId) throws IllegalStateException;

	/** PENDING 인 이력만 결과로 갱신한다(이미 확정된 행은 건드리지 않음). paramMap: rhId, status(SUCCESS/FAIL), failCode, failMsg. */
	int updateHistoryResult(Map<String, Object> paramMap) throws IllegalStateException;

	/** 장치의 SUCCESS 이력 개수(CREATE/UPDATE 구분용). */
	int countSuccess(@Param("dvId") int dvId) throws IllegalStateException;

	/** 장치의 현재 적용본(가장 최근 SUCCESS 행). 없으면 null. */
	Map<String, Object> selectLatestSuccess(@Param("dvId") int dvId) throws IllegalStateException;

	/** 이력 한 건(원문 포함). 없으면 null. */
	Map<String, Object> selectHistory(@Param("rhId") long rhId) throws IllegalStateException;

	/** 이력 목록(최신순, 원문 제외). paramMap: dvId, limit. */
	List<Map<String, Object>> selectHistoryList(Map<String, Object> paramMap) throws IllegalStateException;

	/** 기준 스냅샷 행 INSERT. paramMap: rhId, camera, filePath, width, height. */
	int insertSnapshot(Map<String, Object> paramMap) throws IllegalStateException;

	/** 이력 한 건의 기준 스냅샷 목록. */
	List<Map<String, Object>> selectSnapshots(@Param("rhId") long rhId) throws IllegalStateException;

	/** 스냅샷 한 건(rs_id). 없으면 null. */
	Map<String, Object> selectSnapshotById(@Param("rsId") long rsId) throws IllegalStateException;
}
