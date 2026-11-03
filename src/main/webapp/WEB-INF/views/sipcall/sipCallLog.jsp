<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- Tiles body fragment (patches 2026-07-06). 공용 chrome(헤더·사이드바·푸터)은 template.jsp/defaultLayout 제공. jQuery 는 template 에서 로드 --%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/sipCallLog.css">
<%-- patches 2026-07-07: 외부 CSS 캐시 대비 인라인 — 공용 .content 여백을 다른 화면과 동일하게, 이중여백 제거
     patches 2026-07-09: 오디오 재생 UI 를 하단 고정 모달 → '클릭한 행 바로 아래 인라인 행(아코디언)' 으로 변경.
       - 각 로그 행마다 그 아래에 독립 오디오 재생 행이 열림(표 맨 아래 아님).
       - 높이는 표 행에 맞춰 컴팩트(파형 40px + 컨트롤 가로 배치). --%>
<style>
	.content { padding: 32px 24px 29px 24px !important; }
	.sip-call-log-container { padding: 0 !important; }
	/* 인라인 오디오 재생 행 (클릭한 로그 바로 아래) */
	.sip-audio-row > td { padding: 0 !important; background: #f5f2ff !important; border-top: 0 !important; }
	.inline-audio { display: flex; align-items: center; gap: 14px; padding: 8px 14px; }
	.ia-wave-wrap { flex: 1 1 auto; min-width: 0; position: relative; }
	.ia-waveform { width: 100%; }
	.ia-msg { font-size: 12px; color: #888; padding: 6px 0; }
	.ia-msg.ia-error { color: #dc3545; }
	.ia-controls { flex: 0 0 auto; display: flex; align-items: center; gap: 8px; white-space: nowrap; font-size: 13px; color: #555; }
	.ia-controls button { border: 1px solid #cfc6ea; background: #fff; color: #4F4A85; border-radius: 4px; padding: 4px 9px; cursor: pointer; line-height: 1; }
	.ia-controls button:hover { background: #ece7fb; }
	.ia-controls .ia-close { margin-left: 4px; color: #888; border-color: #ddd; }
	/* ===== 36번 WP-C / 37 WP-N: 고정 행 수 · 알림 도착 안내 ===== */
	/* 마지막 페이지 등 행이 모자랄 때 채우는 빈 행 — 실제 행(패딩 10*2 + 버튼 약 28 + 선 1 = 49px)과 같은 높이 */
	.sip-call-table .filler-row td { height: 49px; padding: 0; border: 0; }
	.sip-call-table .filler-row:hover { background: transparent !important; }
	/* 알림으로 들어왔는데 해당 통화 로그를 찾지 못했을 때의 안내 */
	.sip-focus-msg { margin: 0 0 12px; padding: 10px 14px; border: 1px solid #f0d78c; background: #fff9e5; color: #7a5b00; border-radius: 6px; font-size: 13px; }
	/* 낮은 화면(HD 노트북 등, 브라우저 높이 800px 이하)에서는 행 여백을 줄여 10행이 스크롤 없이 들어가게 한다(소스 검토 기준, 미실측) */
	@media (max-height: 800px) {
		.sip-call-table th, .sip-call-table td { padding: 6px 8px; }
		.sip-call-table .filler-row td { height: 41px; padding: 0; }
		.sip-title { margin-bottom: 10px; }
		.filter-area { margin-bottom: 10px; padding: 8px 16px; }
	}
</style>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css?v=20261103">
<script src="${pageContext.request.contextPath}/resources/js/common/pagination.js?v=20261103"></script>
<%-- 오디오 파형 UI: Wavesurfer.js v7 (작업계획서 §10-6 확정). UMD 빌드로 전역 WaveSurfer 노출 --%>
<script src="https://cdn.jsdelivr.net/npm/wavesurfer.js@7/dist/wavesurfer.min.js"></script>
<script>
	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>

<div class="sip-call-log-container">

	<h2 class="sip-title">응급 연락망</h2>

	<!-- 최상단 필터 -->
	<div class="filter-area">
		<input type="text" id="searchKeyword" placeholder="디바이스ID 또는 시리얼 검색" />
		<input type="date" id="startDate" />
		<span>~</span>
		<input type="date" id="endDate" />
		<button type="button" id="btnSearch">검색</button>
	</div>

	<%-- 알림(응급콜)으로 들어왔는데 해당 통화 로그가 없을 때만 보이는 안내 --%>
	<div id="sipFocusMsg" class="sip-focus-msg" style="display:none;"></div>

	<!-- 리스트 -->
	<table class="sip-call-table" id="sipCallTable">
		<thead>
			<tr>
				<th>연번</th>
				<th>디바이스ID</th>
				<th>serialNumber</th>
				<th>통화시작</th>
				<th>통화시간</th>
				<th>통화상태</th>
				<th>통화방향</th>
				<th>오디오</th>
			</tr>
		</thead>
		<tbody id="sipCallList">
			<tr><td colspan="8" class="empty-row">조회 중...</td></tr>
		</tbody>
	</table>

	<!-- 공통 페이지네이션(총 건수 · 현재/전체 페이지 · 처음/이전/번호/다음/마지막) — common/pagination.js -->
	<div id="pagination" class="h100-pg"></div>

	<%-- patches 2026-07-09: 하단 고정 오디오 패널 제거. 오디오는 각 로그 행 바로 아래 인라인 행으로 열림(아래 JS) --%>

</div>

<script>
var currentPage = 1;
var wavesurfer = null;

// 코드 → 화면 문자열 변환 (DB v0.0.7: sc_status / sc_direction)
function convertStatus(s) {
	return ({0:'발신', 1:'응답', 2:'부재중', 3:'실패'})[s] || '-';
}
function convertDirection(d) {
	return ({0:'인바운드', 1:'아웃바운드'})[d] || '-';
}

// yyyyMMddHHmmss(문자열) → yyyy-MM-dd HH:mm:ss
function formatDeviceDate(v) {
	if (v === null || v === undefined || v === '') return '-';
	var s = String(v).trim();
	if (/^\d{14}$/.test(s)) {
		return s.substr(0,4)+'-'+s.substr(4,2)+'-'+s.substr(6,2)+' '+s.substr(8,2)+':'+s.substr(10,2)+':'+s.substr(12,2);
	}
	if (/^\d{8}$/.test(s)) {
		return s.substr(0,4)+'-'+s.substr(4,2)+'-'+s.substr(6,2);
	}
	return s;
}

// 초 → m:ss
function formatTime(seconds) {
	if (isNaN(seconds)) return '0:00';
	var m = Math.floor(seconds / 60);
	var sec = Math.floor(seconds % 60);
	return m + ':' + (sec < 10 ? '0' + sec : sec);
}

// 한 페이지 크기는 서버 고정값(SipCallController.SIP_LIST_PAGE_SIZE) — 조회 응답의 listSize 로 갱신된다
var PAGE_SIZE = 10;

// 알림(sip_call)에서 넘어온 쿼리 파라미터 읽기(첫 조회 1회만 사용)
//  - notiSerial : 알림의 noti_serial(장비 시리얼)
//  - notiTime   : 알림 시각 noti_reg_date('yyyy-MM-dd HH:mm:ss')
//  - scId       : 통화 로그 sc_id 를 직접 아는 경우
//  서버가 시리얼 + 알림 직후에 등록된 통화 로그를 찾아 그 행이 있는 페이지로 보정해 내려 준다.
function readFocusParams() {
	var q = new URLSearchParams(window.location.search);
	var p = {};
	if (q.get('scId')) p.scId = q.get('scId');
	if (q.get('notiSerial')) p.notiSerial = q.get('notiSerial');
	if (q.get('notiTime')) p.notiTime = q.get('notiTime');
	return Object.keys(p).length ? p : null;
}

function loadSipCallList(page, focus) {
	currentPage = page;
	closeInlineAudio();   // 재조회 전 열려있던 인라인 오디오 파형 정리(메모리 누수 방지)
	var data = {
		keyword: $('#searchKeyword').val(),
		startDate: $('#startDate').val(),
		endDate: $('#endDate').val(),
		page: page
	};
	if (focus) $.extend(data, focus);
	$.ajax({
		url: CONTEXT_PATH + '/sipcall/list',
		method: 'GET',
		dataType: 'json',
		data: data,
		success: function(res) {
			var pg = res.page || page;     // 서버가 마지막 페이지·알림 대상 행 기준으로 보정한 페이지
			currentPage = pg;
			if (res.listSize) PAGE_SIZE = res.listSize;
			renderList(res.list || [], pg);
			renderPagination(res.total || 0, pg);
			if (focus) applyFocus(res);
		},
		error: function() {
			$('#sipCallList').html('<tr><td colspan="8" class="empty-row">조회 중 오류가 발생했습니다.</td></tr>');
		}
	});
}

// 알림 도착 강조 — 이벤트 목록의 강조(#fff6d6, 2.6초)와 같은 스타일. 못 찾으면 안내 문구만 표시
function applyFocus(res) {
	var $msg = $('#sipFocusMsg');
	if (res.focusFound && res.focusScId) {
		var $tr = $('#sipCallList tr[data-id="' + res.focusScId + '"]').not('.sip-audio-row');
		if ($tr.length) {
			$tr.css({ transition: 'background .4s', background: '#fff6d6' });
			$tr[0].scrollIntoView({ behavior: 'smooth', block: 'center' });
			setTimeout(function() { $tr.css('background', ''); }, 2600);
		}
		$msg.hide();
	} else if (res.focusRequested) {
		$msg.text('알림에 해당하는 통화 로그를 찾지 못했습니다. 통화가 아직 끝나지 않았거나 로그가 등록되지 않았을 수 있습니다.').show();
	}
	// 새로고침·재조회 때 다시 강조되지 않도록 일회성 파라미터 제거
	try {
		var u = new URL(window.location.href);
		['scId', 'notiSerial', 'notiTime'].forEach(function(k) { u.searchParams.delete(k); });
		history.replaceState(null, '', u.pathname + u.search);
	} catch (e) { /* 무시 */ }
}

// 행이 모자랄 때 빈 행으로 높이를 채워 페이지네이션 위치가 흔들리지 않게 한다
function fillerRows(n) {
	var h = '';
	for (var i = 0; i < n; i++) h += '<tr class="filler-row" aria-hidden="true"><td colspan="8">&nbsp;</td></tr>';
	return h;
}

function renderList(list, page) {
	if (!list.length) {
		$('#sipCallList').html('<tr><td colspan="8" class="empty-row">조회된 통화 로그가 없습니다.</td></tr>' + fillerRows(PAGE_SIZE - 1));
		return;
	}
	var html = '';
	list.forEach(function(item, idx) {
		var seq = (page - 1) * PAGE_SIZE + idx + 1;
		var hasAudio = String(item.sc_has_audio) === '1' && item.sc_audio_path;
		var audioBtn = hasAudio
			? '<button type="button" class="btn-audio" data-id="' + item.sc_id + '">🎵 재생</button>'
			: '<span class="no-audio">-</span>';
		html += '<tr data-id="' + item.sc_id + '">'
			+ '<td>' + seq + '</td>'
			+ '<td>' + (item.sc_dv_id != null ? item.sc_dv_id : '-') + '</td>'
			+ '<td>' + (item.sc_serial_number || '-') + '</td>'
			+ '<td>' + formatDeviceDate(item.sc_start_date) + '</td>'
			+ '<td>' + (item.sc_duration != null ? item.sc_duration + '초' : '-') + '</td>'
			+ '<td>' + convertStatus(item.sc_status) + '</td>'
			+ '<td>' + convertDirection(item.sc_direction) + '</td>'
			+ '<td>' + audioBtn + '</td>'
			+ '</tr>';
	});
	$('#sipCallList').html(html + fillerRows(PAGE_SIZE - list.length));
}

// 공통 페이지네이션(common/pagination.js)
function renderPagination(total, page) {
	H100Pagination.render(document.getElementById('pagination'), {
		total: total,
		page: page,
		pageSize: PAGE_SIZE,
		onPage: function(p) { loadSipCallList(p); }
	});
}

// 열려있는 인라인 오디오 행 정리(파형 파괴 + 행 제거)
function closeInlineAudio() {
	if (wavesurfer) { wavesurfer.destroy(); wavesurfer = null; }
	$('.sip-audio-row').remove();
}

// 클릭한 로그 행($tr) 바로 아래에 오디오 재생 행을 토글로 열고/닫음
function toggleAudio(scId, $tr) {
	// 같은 행의 오디오가 이미 열려 있으면 닫기(토글)
	var $next = $tr.next('.sip-audio-row');
	if ($next.length && String($next.data('id')) === String(scId)) {
		closeInlineAudio();
		return;
	}
	// 다른 곳에 열려 있던 것은 닫고 이 행 아래에 새로 연다
	closeInlineAudio();

	var waveId = 'waveform-' + scId;
	var rowHtml = ''
		+ '<tr class="sip-audio-row" data-id="' + scId + '">'
		+   '<td colspan="8">'
		+     '<div class="inline-audio">'
		+       '<div class="ia-wave-wrap">'
		+         '<div class="ia-waveform" id="' + waveId + '"></div>'
		+         '<div class="ia-msg ia-loading">오디오 불러오는 중...</div>'
		+         '<div class="ia-msg ia-error" style="display:none;">오디오 파일이 존재하지 않습니다.</div>'
		+       '</div>'
		+       '<div class="ia-controls">'
		+         '<button type="button" class="ia-play">▶ 재생</button>'
		+         '<button type="button" class="ia-pause">❚❚ 정지</button>'
		+         '<span class="ia-cur">0:00</span> / <span class="ia-tot">0:00</span>'
		+         '<button type="button" class="ia-close">닫기</button>'
		+       '</div>'
		+     '</div>'
		+   '</td>'
		+ '</tr>';
	$tr.after(rowHtml);

	var $arow = $tr.next('.sip-audio-row');
	var $loading = $arow.find('.ia-loading');
	var $error = $arow.find('.ia-error');

	wavesurfer = WaveSurfer.create({
		container: '#' + waveId,
		waveColor: '#4F4A85',
		progressColor: '#383351',
		cursorColor: '#FF6B6B',
		height: 40,               // 표 행에 맞춘 컴팩트 높이
		url: CONTEXT_PATH + '/sipcall/audio/' + scId
	});

	wavesurfer.on('ready', function() {
		$loading.hide();
		$arow.find('.ia-tot').text(formatTime(wavesurfer.getDuration()));
	});
	wavesurfer.on('timeupdate', function(t) {
		$arow.find('.ia-cur').text(formatTime(t));
	});
	wavesurfer.on('error', function() {
		$loading.hide();
		$error.show();
	});
}

$(document).ready(function() {
	loadSipCallList(1, readFocusParams());

	$('#btnSearch').on('click', function() { loadSipCallList(1); });
	$('#searchKeyword').on('keypress', function(e) { if (e.which === 13) loadSipCallList(1); });

	// 이벤트 위임 (동적 렌더링 대상)
	$('#sipCallList').on('click', '.btn-audio', function() {
		toggleAudio($(this).data('id'), $(this).closest('tr'));
	});
	// 인라인 오디오 컨트롤(동적 삽입된 재생 행) 위임
	$('#sipCallList').on('click', '.ia-play', function() { if (wavesurfer) wavesurfer.play(); });
	$('#sipCallList').on('click', '.ia-pause', function() { if (wavesurfer) wavesurfer.pause(); });
	$('#sipCallList').on('click', '.ia-close', function() { closeInlineAudio(); });

});
</script>
