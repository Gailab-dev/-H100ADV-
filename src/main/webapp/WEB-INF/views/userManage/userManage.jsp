<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- Tiles body fragment. 공용 chrome(헤더·사이드바·푸터)은 defaultLayout 제공. 최고 관리자(u_grade 30)만 접근(서버 인터셉터).
     작업계획서 2026-11-06 WP-B. 목록은 /userManage/list.do, 저장은 /userManage/update.do(세션 CSRF 헤더 X-H100-CSRF).
     사용자 값은 textContent/value 로만 넣는다(HTML 삽입 없음). 비밀번호 관련 값은 화면·응답 어디에도 없다. --%>
<title>사용자 정보 관리</title>
<style>
	.content { padding: 32px 24px 29px 24px !important; }
	.um-wrap { max-width: 1100px; }
	.um-title { margin: 0 0 8px; font-size: 22px; font-weight: 700; color: #272343; }
	.um-notice { margin: 0 0 14px; font-size: 13px; color: #6b6785; }
	.um-msg { min-height: 20px; margin: 0 0 10px; font-size: 13px; }
	.um-msg.ok { color: #1b7f3b; }
	.um-msg.err { color: #c62828; }
	.um-table { width: 100%; border-collapse: collapse; background: #fff; font-size: 14px; }
	.um-table th, .um-table td { padding: 10px 12px; border-bottom: 1px solid #ebe8f5; text-align: left; vertical-align: middle; }
	.um-table th { background: #f6f4fc; color: #4f4a85; font-weight: 600; white-space: nowrap; }
	.um-table input[type=text], .um-table select { width: 100%; box-sizing: border-box; padding: 6px 8px; border: 1px solid #cfc6ea; border-radius: 4px; font-size: 13px; background: #fff; }
	.um-table select:disabled { background: #f2f1f7; color: #7a7790; }
	.um-table tr.um-dirty td { background: #fbf9ff; }
	.um-badge { display: inline-block; margin-left: 6px; padding: 1px 6px; border-radius: 10px; font-size: 11px; background: #ece7fb; color: #4f4a85; }
	.um-save { padding: 6px 14px; border: 1px solid #6955a2; background: #6955a2; color: #fff; border-radius: 4px; cursor: pointer; font-size: 13px; }
	.um-save:disabled { background: #cfc6ea; border-color: #cfc6ea; cursor: default; }
	.um-empty { padding: 28px 12px; text-align: center; color: #999; }
	.um-col-id { width: 14%; } .um-col-name { width: 12%; } .um-col-email { width: 28%; }
	.um-col-phone { width: 18%; } .um-col-grade { width: 17%; } .um-col-act { width: 11%; }
</style>

<div class="um-wrap" id="userManageRoot" data-ctx="<c:out value='${pageContext.request.contextPath}'/>" data-csrf="<c:out value='${userManageCsrf}'/>">
	<h2 class="um-title">사용자 정보 관리</h2>
	<p class="um-notice">변경한 권한은 해당 사용자의 <strong>다음 로그인부터</strong> 적용됩니다. 최고 관리자 계정의 권한과 본인의 권한은 변경할 수 없습니다.</p>
	<div id="umMsg" class="um-msg" role="status" aria-live="polite"></div>
	<table class="um-table">
		<thead>
			<tr>
				<th class="um-col-id">계정 ID</th>
				<th class="um-col-name">이름</th>
				<th class="um-col-email">이메일</th>
				<th class="um-col-phone">연락처</th>
				<th class="um-col-grade">권한</th>
				<th class="um-col-act">저장</th>
			</tr>
		</thead>
		<tbody id="umBody"><tr><td colspan="6" class="um-empty">불러오는 중...</td></tr></tbody>
	</table>
</div>

<script>
(function() {
	var root = document.getElementById('userManageRoot');
	var CTX = root.getAttribute('data-ctx') || '';
	var CSRF = root.getAttribute('data-csrf') || '';
	var body = document.getElementById('umBody');
	var msg = document.getElementById('umMsg');
	// 선택 가능한 등급. 30(최고 관리자)은 표시만 하고 선택지에 넣지 않는다.
	var GRADE_NAME = { 1: '일반', 25: '장비 관리자', 30: '최고 관리자' };

	function showMsg(text, ok) {
		msg.textContent = text || '';
		msg.className = 'um-msg' + (text ? (ok ? ' ok' : ' err') : '');
	}

	function el(tag, cls, text) {
		var e = document.createElement(tag);
		if (cls) e.className = cls;
		if (text != null) e.textContent = text;
		return e;
	}

	function sessionExpired() {
		location.href = CTX + '/user/login.do?reason=EXPIRED';
	}

	function call(url, opts) {
		opts = opts || {};
		opts.credentials = 'same-origin';
		opts.cache = 'no-store';
		opts.headers = Object.assign({ 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }, opts.headers || {});
		return fetch(CTX + url, opts).then(function(r) {
			if (r.status === 401) { sessionExpired(); return Promise.reject(new Error('session')); }
			return r.json().catch(function() { return {}; }).then(function(d) { d.__status = r.status; return d; });
		});
	}

	function gradeCell(u) {
		var grade = Number(u.u_grade);
		var sel = el('select');
		sel.setAttribute('aria-label', '권한');
		if (grade === 1 || grade === 25) {
			[[1, GRADE_NAME[1]], [25, GRADE_NAME[25]]].forEach(function(o) {
				var opt = el('option', null, o[1]);
				opt.value = String(o[0]);
				if (o[0] === grade) opt.selected = true;
				sel.appendChild(opt);
			});
			// 본인 권한은 변경할 수 없다
			if (u.is_self) sel.disabled = true;
		} else {
			// 30 최고 관리자 또는 그 밖의 값: 표시만(선택 불가)
			var label = GRADE_NAME[grade] || ('기타(' + (u.u_grade == null ? '-' : u.u_grade) + ')');
			var opt2 = el('option', null, label);
			opt2.value = String(u.u_grade);
			sel.appendChild(opt2);
			sel.disabled = true;
		}
		return sel;
	}

	function renderRow(u) {
		var tr = el('tr');
		var idTd = el('td', null, u.u_login_id == null ? '' : u.u_login_id);
		if (u.is_self) idTd.appendChild(el('span', 'um-badge', '본인'));
		tr.appendChild(idTd);
		tr.appendChild(el('td', null, u.u_name == null ? '' : u.u_name));

		var emailIn = el('input'); emailIn.type = 'text'; emailIn.maxLength = 100; emailIn.setAttribute('aria-label', '이메일');
		emailIn.value = u.u_email == null ? '' : u.u_email;
		var phoneIn = el('input'); phoneIn.type = 'text'; phoneIn.maxLength = 20; phoneIn.setAttribute('aria-label', '연락처');
		phoneIn.value = u.u_phone == null ? '' : u.u_phone;
		var gradeSel = gradeCell(u);
		var saveBtn = el('button', 'um-save', '저장'); saveBtn.type = 'button'; saveBtn.disabled = true;

		var orig = { email: emailIn.value, phone: phoneIn.value, grade: gradeSel.value };
		function changed() {
			return emailIn.value.trim() !== orig.email.trim() || phoneIn.value.trim() !== orig.phone.trim() || (!gradeSel.disabled && gradeSel.value !== orig.grade);
		}
		function refresh() {
			var d = changed();
			saveBtn.disabled = !d;
			tr.className = d ? 'um-dirty' : '';
		}
		[emailIn, phoneIn].forEach(function(i) { i.addEventListener('input', refresh); });
		gradeSel.addEventListener('change', refresh);

		saveBtn.addEventListener('click', function() {
			var payload = { u_id: u.u_id };
			if (emailIn.value.trim() !== orig.email.trim()) payload.u_email = emailIn.value.trim();
			if (phoneIn.value.trim() !== orig.phone.trim()) payload.u_phone = phoneIn.value.trim();
			var gradeChanged = !gradeSel.disabled && gradeSel.value !== orig.grade;
			if (gradeChanged) {
				payload.u_grade = Number(gradeSel.value);
				var from = GRADE_NAME[Number(orig.grade)], to = GRADE_NAME[payload.u_grade];
				if (!window.confirm((u.u_login_id || '') + ' 계정의 권한을 "' + from + '"에서 "' + to + '"(으)로 변경합니다.\n변경된 권한은 해당 사용자의 다음 로그인부터 적용됩니다. 계속하시겠습니까?')) return;
			}
			saveBtn.disabled = true;
			showMsg('저장 중...', true);
			call('/userManage/update.do', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json', 'X-H100-CSRF': CSRF },
				body: JSON.stringify(payload)
			}).then(function(d) {
				if (d && d.ok) {
					showMsg(d.code === 'NO_CHANGE' ? (d.msg || '변경된 내용이 없습니다.') : '저장했습니다.', true);
					load(); // 서버 기준 값으로 다시 그린다
				} else {
					showMsg((d && d.msg) || '저장하지 못했습니다.', false);
					refresh();
				}
			}).catch(function(e) {
				if (e && e.message === 'session') return;
				showMsg('저장하지 못했습니다. 잠시 후 다시 시도해 주십시오.', false);
				refresh();
			});
		});

		var t1 = el('td'); t1.appendChild(emailIn); tr.appendChild(t1);
		var t2 = el('td'); t2.appendChild(phoneIn); tr.appendChild(t2);
		var t3 = el('td'); t3.appendChild(gradeSel); tr.appendChild(t3);
		var t4 = el('td'); t4.appendChild(saveBtn); tr.appendChild(t4);
		return tr;
	}

	function load() {
		call('/userManage/list.do').then(function(d) {
			body.innerHTML = '';
			if (!d || !d.ok) {
				var tr0 = el('tr'); var td0 = el('td', 'um-empty', (d && d.msg) || '목록을 불러오지 못했습니다.'); td0.colSpan = 6; tr0.appendChild(td0); body.appendChild(tr0);
				return;
			}
			var users = d.users || [];
			if (!users.length) {
				var tr1 = el('tr'); var td1 = el('td', 'um-empty', '사용자가 없습니다.'); td1.colSpan = 6; tr1.appendChild(td1); body.appendChild(tr1);
				return;
			}
			users.forEach(function(u) { body.appendChild(renderRow(u)); });
		}).catch(function(e) {
			if (e && e.message === 'session') return;
			body.innerHTML = '';
			var tr2 = el('tr'); var td2 = el('td', 'um-empty', '목록을 불러오지 못했습니다.'); td2.colSpan = 6; tr2.appendChild(td2); body.appendChild(tr2);
		});
	}

	load();
})();
</script>
