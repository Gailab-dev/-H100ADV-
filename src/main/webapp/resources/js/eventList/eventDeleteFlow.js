/**
 * 이벤트 삭제 흐름(작업계획서 39 WP-6) — 목록 다중 선택 삭제·상세보기 단건 삭제 공용.
 *
 * 흐름
 *  1) 확인 대화상자: "이벤트를 삭제하면 이미지·영상 등 관련 자료를 조회할 수 없습니다. 삭제하시겠습니까?"
 *  2) POST /eventList/delete/check  — 서버가 이미지·영상 파일 존재를 확인(없으면 장비에서 내려받는 비동기 작업 시작)
 *  3) 내려받는 중이면 진행 안내 팝업("이미지·영상을 내려받는 중입니다") + GET /eventList/delete/status 폴링
 *  4) 장비 오프라인·실패 → 삭제 중단 + 사유 안내
 *     장비에도 파일 없음 → "파일이 존재하지 않습니다. 그래도 삭제하시겠습니까?" 확인 후 삭제 허용
 *  5) POST /eventList/delete/confirm — 삭제 확정(소프트 삭제 + 이력 기록 + 알림 삭제)
 *
 * 사용: H100EventDelete.run([evId, ...], { onDone: function(result){ ... } })
 * 확인/안내는 기존 화면과 같은 방식(window.confirm / alert)이고, 진행 팝업만 이 파일이 만든다.
 */
(function (window) {
	'use strict';

	var BASE = (typeof CONTEXT_PATH !== 'undefined') ? CONTEXT_PATH : '';

	var MSG_CONFIRM = '이벤트를 삭제하면 이미지·영상 등 관련 자료를 조회할 수 없습니다. 삭제하시겠습니까?';
	var MSG_MISSING_ONE = '파일이 존재하지 않습니다. 그래도 삭제하시겠습니까?';
	var MSG_PROGRESS = '이미지·영상을 내려받는 중입니다.';
	var MSG_FAIL = '삭제에 실패했습니다. 잠시 후 다시 시도해주세요.';
	var MSG_ERROR = '삭제 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

	var POLL_INTERVAL_MS = 1000;
	var POLL_MAX_MS = 30 * 60 * 1000;
	var busy = false;

	// ---------- 진행 안내 팝업 ----------
	var overlay = null;
	var msgEl = null;
	var countEl = null;

	function ensureOverlay() {
		if (overlay) return;
		if (!document.getElementById('h100DeleteFlowStyle')) {
			var st = document.createElement('style');
			st.id = 'h100DeleteFlowStyle';
			st.textContent =
				'#h100DeleteFlowOverlay{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:center;justify-content:center;z-index:99999}' +
				'#h100DeleteFlowOverlay .h100df-box{background:#fff;border-radius:12px;padding:28px 36px;min-width:300px;text-align:center;box-shadow:0 8px 28px rgba(0,0,0,.25)}' +
				'#h100DeleteFlowOverlay .h100df-spin{width:34px;height:34px;margin:0 auto 14px;border:4px solid #e3def2;border-top-color:#6955A2;border-radius:50%;animation:h100dfspin .9s linear infinite}' +
				'#h100DeleteFlowOverlay .h100df-msg{font-size:15px;color:#222}' +
				'#h100DeleteFlowOverlay .h100df-count{margin-top:6px;font-size:13px;color:#777}' +
				'@keyframes h100dfspin{to{transform:rotate(360deg)}}';
			document.head.appendChild(st);
		}
		overlay = document.createElement('div');
		overlay.id = 'h100DeleteFlowOverlay';
		overlay.setAttribute('role', 'alertdialog');
		overlay.setAttribute('aria-live', 'polite');
		var box = document.createElement('div');
		box.className = 'h100df-box';
		var spin = document.createElement('div');
		spin.className = 'h100df-spin';
		msgEl = document.createElement('div');
		msgEl.className = 'h100df-msg';
		countEl = document.createElement('div');
		countEl.className = 'h100df-count';
		box.appendChild(spin);
		box.appendChild(msgEl);
		box.appendChild(countEl);
		overlay.appendChild(box);
		document.body.appendChild(overlay);
	}

	function showProgress(done, total) {
		ensureOverlay();
		msgEl.textContent = MSG_PROGRESS;
		countEl.textContent = total > 0 ? ('(' + done + '/' + total + ')') : '';
		overlay.style.display = 'flex';
	}

	function hideProgress() {
		if (overlay) overlay.style.display = 'none';
	}

	// ---------- 서버 호출 ----------
	function request(url, options) {
		options = options || {};
		options.headers = Object.assign({ 'X-Requested-With': 'XMLHttpRequest' }, options.headers || {});
		options.credentials = 'same-origin';
		return fetch(url, options).then(function (r) {
			if (r.status === 401) {
				var err = new Error('SESSION_TIMEOUT');
				err.sessionTimeout = true;
				throw err;
			}
			return r.json();
		});
	}

	function postJson(url, body) {
		return request(BASE + url, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(body)
		});
	}

	function getJson(url) {
		return request(BASE + url, { method: 'GET' });
	}

	function sleep(ms) {
		return new Promise(function (resolve) { setTimeout(resolve, ms); });
	}

	/** RUNNING 이면 DONE/ERROR 가 될 때까지 폴링 */
	function waitDone(first) {
		var started = Date.now();
		var failures = 0;
		function step(d) {
			if (d && d.state === 'RUNNING') {
				showProgress(d.pullDone || 0, d.pullTotal || 0);
				if (Date.now() - started > POLL_MAX_MS) {
					return Promise.reject(new Error('TIMEOUT'));
				}
				return sleep(POLL_INTERVAL_MS)
					.then(function () { return getJson('/eventList/delete/status?jobId=' + encodeURIComponent(d.jobId)); })
					.then(function (next) { failures = 0; return step(next); }, function (e) {
						if (e && e.sessionTimeout) throw e;
						failures++;
						if (failures >= 5) throw e; // 일시적인 네트워크 오류는 몇 번 더 시도
						return step(d);
					});
			}
			return Promise.resolve(d);
		}
		return step(first);
	}

	function blockedMessage(d) {
		var lines = ['장비에서 파일을 내려받지 못해 삭제하지 않았습니다.'];
		var list = (d && d.blocked) || [];
		for (var i = 0; i < list.length && i < 5; i++) {
			lines.push('- 이벤트 ' + list[i].evId + ': ' + (list[i].reason || '내려받기 실패'));
		}
		if (list.length > 5) lines.push('- 외 ' + (list.length - 5) + '건');
		lines.push('장비 상태를 확인한 뒤 다시 시도해주세요.');
		return lines.join('\n');
	}

	function missingMessage(d, evCount) {
		if (evCount === 1) return MSG_MISSING_ONE;
		return '선택한 이벤트 중 ' + d.missingCount + '건은 장비에도 파일이 존재하지 않습니다. 그래도 삭제하시겠습니까?';
	}

	function fail(e) {
		hideProgress();
		busy = false;
		if (e && e.sessionTimeout) {
			alert('로그인 시간이 만료되었습니다. 다시 로그인해주세요.');
		} else {
			alert(MSG_ERROR);
		}
	}

	/**
	 * @param evIds 삭제할 이벤트 ID 배열
	 * @param opts  { onDone: function(result) } — 삭제가 확정되면 호출
	 */
	function run(evIds, opts) {
		opts = opts || {};
		if (busy) return;
		if (!evIds || !evIds.length) return;
		if (!window.confirm(MSG_CONFIRM)) return;
		busy = true;

		postJson('/eventList/delete/check', { evIds: evIds })
			.then(function (d) {
				if (!d || d.success === false) {
					hideProgress();
					busy = false;
					alert((d && d.message) || MSG_FAIL);
					return null;
				}
				return waitDone(d);
			})
			.then(function (d) {
				if (!d) return null;
				hideProgress();
				if (d.state === 'ERROR' || d.success === false) {
					busy = false;
					alert(d.message || MSG_FAIL);
					return null;
				}
				if (d.blockedCount > 0) {
					busy = false;
					alert(blockedMessage(d));
					return null;
				}
				var allowMissing = false;
				if (d.missingCount > 0) {
					if (!window.confirm(missingMessage(d, evIds.length))) {
						busy = false;
						return null;
					}
					allowMissing = true;
				}
				return postJson('/eventList/delete/confirm', { jobId: d.jobId, allowMissing: allowMissing });
			})
			.then(function (res) {
				if (!res) return;
				busy = false;
				if (res.success) {
					if (typeof opts.onDone === 'function') opts.onDone(res);
				} else if (res.code === 'BLOCKED') {
					alert(blockedMessage(res));
				} else {
					alert(res.message || MSG_FAIL);
				}
			})
			.catch(fail);
	}

	window.H100EventDelete = { run: run };
})(window);
