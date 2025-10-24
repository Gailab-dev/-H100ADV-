package com.disabled.mapper;

import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface LoginMapper {
	Map<String,Object> cntUsrByIdAndPwd(@Param("id") String id, @Param("pwd")String pwd) throws IllegalStateException;
	Integer updateNewPwd(@Param("uId") Integer uId, @Param("encryptPwd") String encryptPwd) throws IllegalStateException;
}
