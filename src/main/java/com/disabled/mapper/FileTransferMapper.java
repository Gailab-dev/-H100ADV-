package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * 일일 파일 백업 전송 이력(tbl_file_transfer_log) 매퍼 — 작업계획서 39.
 * SQL 은 mappers/FileTransferMapper.xml. MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 */
@Mapper
@Repository
public interface FileTransferMapper {

	// ----- 대상 등록(이미 있으면 유지) -----
	/** kind=EVENT_IMAGE1/EVENT_IMAGE2/EVENT_VIDEO. (ymd,ymdNext) 하루치 또는 evId 한 건. 새로 등록된 행 수 반환 */
	int registerEventFiles(@Param("kind") String kind, @Param("ymd") String ymd, @Param("ymdNext") String ymdNext,
			@Param("evId") Integer evId);

	/** 통화 음성 하루치(ymd=yyyyMMdd). 새로 등록된 행 수 반환 */
	int registerCallAudio(@Param("ymd") String ymd);

	// ----- 처리 대상 -----
	List<Map<String, Object>> selectProcessable(@Param("fromDate") String fromDate, @Param("toDate") String toDate,
			@Param("dvId") Integer dvId);

	int requeueForDate(@Param("targetDate") String targetDate, @Param("dvId") Integer dvId);

	int markLostBefore(@Param("cutoff") String cutoff);

	// ----- 결과 기록 -----
	int markVerified(@Param("ftId") long ftId, @Param("attempts") int attempts, @Param("deviceBytes") Long deviceBytes,
			@Param("serverBytes") Long serverBytes);

	int markFailed(@Param("ftId") long ftId, @Param("attempts") int attempts, @Param("errorCode") String errorCode,
			@Param("deviceBytes") Long deviceBytes);

	int markMissing(@Param("ftId") long ftId, @Param("attempts") int attempts);

	// ----- 조회 -----
	List<Map<String, Object>> selectByEvent(@Param("evId") Integer evId);

	Map<String, Object> selectEventForBackup(@Param("evId") Integer evId);

	List<Map<String, Object>> selectStatusCounts();

	// ----- ev_has_* / sc_has_audio (검증 완료 시에만 1) -----
	int updateEvHasImgIfVerified(@Param("evId") Integer evId);

	int updateEvHasMovIfVerified(@Param("evId") Integer evId);

	int updateScHasAudioIfVerified(@Param("scId") Integer scId);

	// ----- 이벤트 삭제 기록 -----
	int markDeletedEventRow(@Param("ftId") long ftId, @Param("deletedBy") Integer deletedBy, @Param("origPath") String origPath);
}
