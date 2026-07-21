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
</style>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css">
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
		<select id="listSize">
			<option value="10">10개</option>
			<option value="30">30개</option>
			<option value="50">50개</option>
			<option value="100">100개</option>
		</select>
		<input type="date" id="startDate" />
		<span>~</span>
		<input type="date" id="endDate" />
		<button type="button" id="btnSearch">검색</button>
		<span class="total-count">총 <b id="totalCount">0</b> 건</span>
	</div>

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

	<!-- 페이지네이션 -->
	<div id="pagination" class="pagination-area"></div>

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

function loadSipCallList(page) {
	currentPage = page;
	closeInlineAudio();   // 재조회 전 열려있던 인라인 오디오 파형 정리(메모리 누수 방지)
	$.ajax({
		url: CONTEXT_PATH + '/sipcall/list',
		method: 'GET',
		dataType: 'json',
		data: {
			keyword: $('#searchKeyword').val(),
			listSize: $('#listSize').val(),
			startDate: $('#startDate').val(),
			endDate: $('#endDate').val(),
			page: page
		},
		success: function(res) {
			$('#totalCount').text(res.total || 0);
			renderList(res.list || [], page);
			renderPagination(res.total || 0, page);
		},
		error: function() {
			$('#sipCallList').html('<tr><td colspan="8" class="empty-row">조회 중 오류가 발생했습니다.</td></tr>');
		}
	});
}

function renderList(list, page) {
	var listSize = parseInt($('#listSize').val(), 10);
	if (!list.length) {
		$('#sipCallList').html('<tr><td colspan="8" class="empty-row">조회된 통화 로그가 없습니다.</td></tr>');
		return;
	}
	var html = '';
	list.forEach(function(item, idx) {
		var seq = (page - 1) * listSize + idx + 1;
		var hasAudio = String(item.sc_has_audio) === '1' && item.sc_audio_path;
		var audioBtn = hasAudio
			? '<button type="button" class="btn-audio" data-id="' + item.sc_id + '">🎵 재생</button>'
			: '<span class="no-audio">-</span>';
		html += '<tr>'
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
	$('#sipCallList').html(html);
}

function renderPagination(total, page) {
	var listSize = parseInt($('#listSize').val(), 10);
	var lastPage = Math.max(1, Math.ceil(total / listSize));
	var blockSize = 10;
	var blockStart = Math.floor((page - 1) / blockSize) * blockSize + 1;
	var blockEnd = Math.min(blockStart + blockSize - 1, lastPage);

	var html = '';
	html += '<button type="button" class="pg-btn" data-page="1" ' + (page === 1 ? 'disabled' : '') + '>&laquo;</button>';
	html += '<button type="button" class="pg-btn" data-page="' + (page - 1) + '" ' + (page === 1 ? 'disabled' : '') + '>&lsaquo;</button>';
	for (var p = blockStart; p <= blockEnd; p++) {
		html += '<button type="button" class="pg-btn ' + (p === page ? 'active' : '') + '" data-page="' + p + '">' + p + '</button>';
	}
	html += '<button type="button" class="pg-btn" data-page="' + (page + 1) + '" ' + (page === lastPage ? 'disabled' : '') + '>&rsaquo;</button>';
	html += '<button type="button" class="pg-btn" data-page="' + lastPage + '" ' + (page === lastPage ? 'disabled' : '') + '>&raquo;</button>';
	$('#pagination').html(html);
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
	loadSipCallList(1);

	$('#btnSearch').on('click', function() { loadSipCallList(1); });
	$('#searchKeyword').on('keypress', function(e) { if (e.which === 13) loadSipCallList(1); });
	$('#listSize').on('change', function() { loadSipCallList(1); });

	// 이벤트 위임 (동적 렌더링 대상)
	$('#sipCallList').on('click', '.btn-audio', function() {
		toggleAudio($(this).data('id'), $(this).closest('tr'));
	});
	// 인라인 오디오 컨트롤(동적 삽입된 재생 행) 위임
	$('#sipCallList').on('click', '.ia-play', function() { if (wavesurfer) wavesurfer.play(); });
	$('#sipCallList').on('click', '.ia-pause', function() { if (wavesurfer) wavesurfer.pause(); });
	$('#sipCallList').on('click', '.ia-close', function() { closeInlineAudio(); });

	$('#pagination').on('click', '.pg-btn', function() {
		if ($(this).is(':disabled')) return;
		var p = parseInt($(this).data('page'), 10);
		if (!isNaN(p) && p >= 1) loadSipCallList(p);
	});
});
</script>
