package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.interceptor.UserManageAccessInterceptor;
import com.disabled.mapper.UserManageMapper;
import com.disabled.service.UserManageService;

@Service
public class UserManageServiceImpl implements UserManageService {

	private static final Logger logger = LoggerFactory.getLogger(UserManageServiceImpl.class);

	/** 화면에서 선택할 수 있는 등급: 1 일반, 25 장비 관리자. 30(최고 관리자)은 선택·변경 불가. */
	public static final int GRADE_GENERAL = 1;
	public static final int GRADE_DEVICE_MANAGER = 25;

	// 가입 화면(register.jsp EMAIL_RULE)과 같은 이메일 규칙 + 길이 제한
	private static final String EMAIL_RULE = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
	private static final int EMAIL_MAX = 100;
	private static final int PHONE_MAX = 20;

	@Autowired
	private UserManageMapper userManageMapper;

	@Override
	public List<Map<String, Object>> getUsers() {
		List<Map<String, Object>> list = userManageMapper.selectUsers();
		return list == null ? new ArrayList<Map<String, Object>>() : list;
	}

	@Override
	public UpdateResult updateUser(int actorUId, int targetUId, String email, String phone, Integer grade) {
		Map<String, Object> target = userManageMapper.selectUserById(targetUId);
		if (target == null) {
			return fail(404, "NOT_FOUND", "대상 사용자를 찾을 수 없습니다.");
		}
		String loginId = String.valueOf(target.get("u_login_id"));
		Integer currentGrade = toInt(target.get("u_grade"));

		List<String> changed = new ArrayList<String>();
		String newEmail = null;
		String newPhone = null;
		Integer newGrade = null;

		// ---- 이메일 ----
		if (email != null) {
			String e = email.trim();
			if (e.isEmpty() || e.length() > EMAIL_MAX || !e.matches(EMAIL_RULE)) {
				return fail(400, "INVALID_EMAIL", "이메일 형식이 올바르지 않습니다.");
			}
			String cur = target.get("u_email") == null ? "" : String.valueOf(target.get("u_email")).trim();
			if (!e.equals(cur)) {
				if (userManageMapper.countEmailExcept(e, targetUId) > 0) {
					return fail(409, "DUPLICATE_EMAIL", "이미 다른 계정에서 사용 중인 이메일입니다.");
				}
				newEmail = e;
				changed.add("email");
			}
		}

		// ---- 연락처(비우는 것은 허용) ----
		if (phone != null) {
			String p = phone.trim();
			if (!p.isEmpty() && !isValidPhone(p)) {
				return fail(400, "INVALID_PHONE", "연락처는 숫자와 하이픈(-)으로 9~11자리를 입력해 주십시오.");
			}
			String cur = target.get("u_phone") == null ? "" : String.valueOf(target.get("u_phone")).trim();
			if (!p.equals(cur)) {
				newPhone = p;
				changed.add("phone");
			}
		}

		// ---- 등급 ----
		if (grade != null && !grade.equals(currentGrade)) {
			if (actorUId == targetUId) {
				return fail(403, "SELF_GRADE", "본인의 권한은 변경할 수 없습니다.");
			}
			if (currentGrade != null && currentGrade == UserManageAccessInterceptor.GRADE_SUPER_ADMIN) {
				return fail(403, "SUPER_ADMIN_LOCKED", "최고 관리자 계정의 권한은 변경할 수 없습니다.");
			}
			if (grade != GRADE_GENERAL && grade != GRADE_DEVICE_MANAGER) {
				return fail(400, "INVALID_GRADE", "선택할 수 없는 권한입니다.");
			}
			if (currentGrade == null || (currentGrade != GRADE_GENERAL && currentGrade != GRADE_DEVICE_MANAGER)) {
				return fail(400, "UNSUPPORTED_CURRENT_GRADE", "이 계정의 현재 권한은 이 화면에서 변경할 수 없습니다.");
			}
			newGrade = grade;
			changed.add("grade");
		}

		if (changed.isEmpty()) {
			return new UpdateResult(200, true, "NO_CHANGE", "변경된 내용이 없습니다.");
		}

		int rows = userManageMapper.updateUser(targetUId, newEmail, newPhone, newGrade, actorUId);
		if (rows < 1) {
			// 대상이 그 사이 삭제됐거나 등급이 바뀐 경우(등급 조건 불일치)
			return fail(409, "STALE", "그 사이 정보가 바뀌었습니다. 목록을 새로 고친 뒤 다시 시도해 주십시오.");
		}

		// 변경 내역 로그: 계정 ID·변경 항목 종류·등급 이전/이후 값만 남긴다(이메일·연락처 값은 남기지 않는다).
		if (newGrade != null) {
			logger.info("[UserManage] 사용자 정보 변경 actorUId={} target={} fields={} grade {} -> {}",
					actorUId, loginId, changed, currentGrade, newGrade);
		} else {
			logger.info("[UserManage] 사용자 정보 변경 actorUId={} target={} fields={}", actorUId, loginId, changed);
		}
		return new UpdateResult(200, true, "UPDATED", "저장했습니다.");
	}

	private static boolean isValidPhone(String p) {
		if (p.length() > PHONE_MAX || !p.matches("[0-9-]+") || p.startsWith("-") || p.endsWith("-") || p.contains("--")) {
			return false;
		}
		int digits = p.replace("-", "").length();
		return digits >= 9 && digits <= 11;
	}

	private static Integer toInt(Object v) {
		if (v instanceof Number) {
			return ((Number) v).intValue();
		}
		if (v == null) {
			return null;
		}
		try {
			return Integer.valueOf(String.valueOf(v).trim());
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private static UpdateResult fail(int status, String code, String msg) {
		return new UpdateResult(status, false, code, msg);
	}
}
