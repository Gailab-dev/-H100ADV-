package com.disabled.service;

import java.util.List;
import java.util.Map;

/**
 * 사용자 정보 관리(최고 관리자 전용 화면, 작업계획서 2026-11-06 WP-B).
 */
public interface UserManageService {

	/** 사용자 목록(계정 ID·이름·이메일·연락처·등급). 비밀 컬럼은 포함하지 않는다. */
	List<Map<String, Object>> getUsers();

	/**
	 * 이메일·연락처·등급 수정. 전달된(null 이 아닌) 항목 중 실제로 바뀐 것만 반영한다.
	 * 이름·계정 ID·비밀번호는 바꿀 수 없다.
	 *
	 * @param actorUId  요청한 최고 관리자의 u_id
	 * @param targetUId 수정 대상 u_id
	 * @param email     새 이메일(null 이면 변경 안 함)
	 * @param phone     새 연락처(null 이면 변경 안 함, 빈 문자열이면 비움)
	 * @param grade     새 등급(null 이면 변경 안 함). 허용값 1·25
	 */
	UpdateResult updateUser(int actorUId, int targetUId, String email, String phone, Integer grade);

	/** 수정 결과. status 는 HTTP 상태 코드로 그대로 쓰인다. */
	final class UpdateResult {
		public final int status;
		public final boolean ok;
		public final String code;
		public final String msg;

		public UpdateResult(int status, boolean ok, String code, String msg) {
			this.status = status;
			this.ok = ok;
			this.code = code;
			this.msg = msg;
		}
	}
}
