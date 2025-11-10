package com.disabled.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface LoginMapper {
	Map<String,Object> existUsrByIdAndPwd(@Param("id") String id, @Param("pwd") String pwd) throws IllegalStateException;
	Integer updateNewPwd(@Param("uId") Integer uId, @Param("encryptPwd") String encryptPwd) throws IllegalStateException;
	String getPwd(@Param("uId") Integer uId) throws IllegalStateException;
	Map<String, Object> getMyInfo(@Param("uId") Integer uId);
	String getLoginId(@Param("uId") Integer uId);
}
