package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;

@Mapper
public interface UserManageMapper {

	/** 사용자 목록(계정 ID·이름·이메일·연락처·등급). 비밀 컬럼은 조회하지 않는다. */
	List<Map<String, Object>> selectUsers();

	Map<String, Object> selectUserById(@Param("uId") int uId);

	/** 자기 자신(uId)을 제외하고 같은 이메일을 쓰는 계정 수. */
	int countEmailExcept(@Param("email") String email, @Param("uId") int uId);

	/** 전달된(null 이 아닌) 항목만 갱신한다. 등급 변경은 현재 등급이 1·25 인 경우에만 반영된다. */
	int updateUser(@Param("uId") int uId, @Param("email") String email, @Param("phone") String phone,
			@Param("grade") Integer grade, @Param("modUser") int modUser);

}
