package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * 헤더 알림 SQL (작업계획서 15 §4-2 / 신설 테이블 tbl_notification)
 *  - INSERT 는 Go module_c(이벤트·SIP·디바이스이상 각 endpoint)가 담당. 웹은 조회·읽음처리만 한다.
 *  - MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 */
@Mapper
@Repository
public interface NotificationMapper {

	// 안읽은 알림 개수 (헤더 배지)
	int countUnread() throws IllegalStateException;

	// 최근 알림 목록. paramMap: limit
	List<Map<String, Object>> selectRecent(Map<String, Object> paramMap) throws IllegalStateException;

	// 단건 읽음 처리
	int updateRead(Integer notiId) throws IllegalStateException;

	// 전체 읽음 처리
	int updateReadAll() throws IllegalStateException;
}
