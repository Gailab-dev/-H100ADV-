package com.minwon.dao;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;

@Mapper
public interface LoginMapper {
	Integer cntUsrByIdAndPwd(@Param("id") String id, @Param("pwd")String pwd);
}
