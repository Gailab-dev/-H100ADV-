package com.disabled.mapper;

import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface MyInfoMapper {
	// 사용자 정보 가져오기
	Map<String, Object> getMyInfoMap(Map<String, Object> paramMap) throws IllegalStateException;
	// 사용자 정보 저장하기
	Integer updateMyInfo(Map<String, Object> paramMap) throws IllegalStateException;
}
