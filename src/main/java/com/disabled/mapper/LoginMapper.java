package com.disabled.mapper;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Repository;

@Mapper
@Repository
public interface LoginMapper {
	Integer cntUsrByIdAndPwd(@Param("id") String id, @Param("pwd")String pwd) throws DataAccessException;
}
