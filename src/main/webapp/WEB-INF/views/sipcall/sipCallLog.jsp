<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- Tiles body fragment (patches 2026-07-06). 공용 chrome(헤더·사이드바·푸터)은 template.jsp/defaultLayout 제공. jQuery 는 template 에서 로드 --%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/sipCallLog.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css">
<%-- 오디오 파형 UI: Wavesurfer.js v7 (작업계획서 §10-6 확정). UMD 빌드로 전역 WaveSurfer 노출 --%>
<script src="https://cdn.jsdelivr.net/npm/wavesurfer.js@7/dist/wavesurfer.min.js"></script>
<script>
	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>

<div class="sip-call-log-container">

	<h2 class="sip-title">SIP 통화 로그</h2>

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

	<!-- 오디오 재생 영역 (하단 고정 패널) -->
	<div id="audioPlayerPanel" class="audio-panel" style="display:none;">
		<div class="audio-panel-head">
			<span id="audioTitle">통화 오디오</span>
			<button type="button" id="btnClosePanel" class="btn-close">닫기</button>
		</div>
		<div id="waveform"></div>
		<div id="audioLoading" class="audio-loading" style="display:none;">오디오 불러오는 중...</div>
		<div id="audioError" class="audio-error" style="display:none;">오디오 파일이 존재하지 않습니다.</div>
		<div class="audio-controls">
			<button type="button" id="btnPlay">▶ 재생</button>
			<button type="button" id="btnPause">❚❚ 정지</button>
			<span id="currentTime">0:00</span> / <span id="totalTime">0:00</span>
		</div>
	</div>

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

function playAudio(scId) {
	$('#audioPlayerPanel').show();
	$('#audioError').hide();
	$('#audioLoading').show();
	$('#currentTime').text('0:00');
	$('#totalTime').text('0:00');

	if (wavesurfer) { wavesurfer.destroy(); wavesurfer = null; }

	wavesurfer = WaveSurfer.create({
		container: '#waveform',
		waveColor: '#4F4A85',
		progressColor: '#383351',
		cursorColor: '#FF6B6B',
		height: 96,
		url: CONTEXT_PATH + '/sipcall/audio/' + scId
	});

	wavesurfer.on('ready', function() {
		$('#audioLoading').hide();
		$('#totalTime').text(formatTime(wavesurfer.getDuration()));
	});
	wavesurfer.on('timeupdate', function(t) {
		$('#currentTime').text(formatTime(t));
	});
	wavesurfer.on('error', function() {
		$('#audioLoading').hide();
		$('#audioError').show();
	});
}

$(document).ready(function() {
	loadSipCallList(1);

	$('#btnSearch').on('click', function() { loadSipCallList(1); });
	$('#searchKeyword').on('keypress', function(e) { if (e.which === 13) loadSipCallList(1); });
	$('#listSize').on('change', function() { loadSipCallList(1); });

	// 이벤트 위임 (동적 렌더링 대상)
	$('#sipCallList').on('click', '.btn-audio', function() {
		playAudio($(this).data('id'));
	});
	$('#pagination').on('click', '.pg-btn', function() {
		if ($(this).is(':disabled')) return;
		var p = parseInt($(this).data('page'), 10);
		if (!isNaN(p) && p >= 1) loadSipCallList(p);
	});

	$('#btnPlay').on('click', function() { if (wavesurfer) wavesurfer.play(); });
	$('#btnPause').on('click', function() { if (wavesurfer) wavesurfer.pause(); });
	$('#btnClosePanel').on('click', function() {
		if (wavesurfer) { wavesurfer.destroy(); wavesurfer = null; }
		$('#audioPlayerPanel').hide();
	});
});
</script>
