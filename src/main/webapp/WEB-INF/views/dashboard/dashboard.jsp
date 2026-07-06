<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- Tiles body fragment (patches 2026-07-06). 공용 chrome(헤더·사이드바·푸터)은 template.jsp/defaultLayout 제공. jQuery 는 template 에서 로드 --%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/dashboard.css">
<!-- Font Awesome (상태 아이콘) -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<!-- 카카오 지도 JavaScript SDK (services=Geocoder 등). autoload=false → kakao.maps.load 로 초기화 -->
<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoMapJsKey}&libraries=services&autoload=false"></script>
<script>
	const CONTEXT_PATH = "${pageContext.request.contextPath}";
	const KAKAO_JS_KEY = "${kakaoMapJsKey}";
</script>

<div class="dashboard-wrap">
	<div class="dashboard-head">
		<h2 class="dashboard-title">G-Eye Parking 대시보드</h2>
		<div class="legend">
			<span><i class="fas fa-map-marker-alt" style="color:#28a745"></i> 정상</span>
			<span><i class="fas fa-map-marker-alt" style="color:#ffc107"></i> 이상 1~2</span>
			<span><i class="fas fa-map-marker-alt" style="color:#dc3545"></i> 이상 3+</span>
			<span><i class="fas fa-map-marker-alt" style="color:#808080"></i> 30분+ 미갱신</span>
		</div>
	</div>

	<div id="mapWarning" class="map-warning" style="display:none;">
		카카오 지도 키(kakao.map.js-key)가 설정되지 않았거나 지도를 불러올 수 없습니다.
		<br>globals.properties 의 <b>kakao.map.js-key</b>(환경변수 KAKAO_MAP_JS_KEY)를 확인하세요.
	</div>

	<div class="dashboard-container">
		<!-- 좌측: 지도 (11번 완료) -->
		<div class="map-area">
			<div id="map"></div>
		</div>

		<!-- 우측: 일별 대시보드 카드 (신설, 화면설계서 v0.0.2 Slide4) -->
		<div class="cards-area">
			<div class="card weather-card">
				<h3><i class="fas fa-cloud-sun"></i> 오늘 날씨</h3>
				<div class="card-value" id="weather-value">-</div>
				<div class="card-sub" id="weather-sub"></div>
			</div>
			<div class="card guide-card">
				<h3><i class="fas fa-hand-paper"></i> 일별 계도</h3>
				<div class="card-value" id="guide-value">0</div>
			</div>
			<div class="card enforce-card">
				<h3><i class="fas fa-triangle-exclamation"></i> 일별 단속</h3>
				<div class="card-value" id="enforce-value">0</div>
			</div>
		</div>

		<!-- 하단: 최근 이벤트 요약 (신설) -->
		<div class="recent-events-area">
			<div class="section-header">
				<h3>최근 이벤트</h3>
				<button type="button" id="btnMoreEvents" class="btn-more">＋ 더보기</button>
			</div>
			<table class="recent-events-table">
				<thead>
					<tr>
						<th>발생시각</th>
						<th>디바이스</th>
						<th>차량번호</th>
						<th>유형</th>
						<th>처리</th>
						<th>상세</th>
					</tr>
				</thead>
				<tbody id="recent-events-body">
					<tr><td colspan="6" class="empty-row">불러오는 중...</td></tr>
				</tbody>
			</table>
		</div>
	</div>
</div>

<script>
var map = null;
var markerMap = {};   // dv_id -> { marker, colorKey, device } — 부분 갱신용(전체 재생성 회피)
var overlays = [];

// 상태 색상 (DB v0.0.7: 상태 5종, dv_status_display 제외)
function getStatusColor(device) {
	// dv_status_updated 30분 이상 옛 → 회색
	if (device.dv_status_updated) {
		var updated = new Date(device.dv_status_updated);
		if (!isNaN(updated.getTime()) && (Date.now() - updated.getTime() > 30 * 60 * 1000)) {
			return "#808080";
		}
	}
	// 이상(0) 개수 — 5종
	var errorCount = [
		device.dv_status_pc,
		device.dv_status_cctv,
		device.dv_lens,
		device.dv_status_speaker,
		device.dv_status_sip
	].filter(function(v) { return String(v) === '0'; }).length;

	if (errorCount === 0) return "#28a745"; // 초록
	if (errorCount <= 2) return "#ffc107";  // 노랑
	return "#dc3545";                        // 빨강
}

function markerImage(color) {
	var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="30" height="42" viewBox="0 0 30 42">'
		+ '<path d="M15 0 C6.7 0 0 6.7 0 15 C0 26 15 42 15 42 S30 26 30 15 C30 6.7 23.3 0 15 0 Z" fill="' + color + '"/>'
		+ '<circle cx="15" cy="15" r="6" fill="white"/></svg>';
	return new kakao.maps.MarkerImage(
		"data:image/svg+xml;utf8," + encodeURIComponent(svg),
		new kakao.maps.Size(30, 42),
		{ offset: new kakao.maps.Point(15, 42) }
	);
}

/**
 * 마커 부분 갱신 (전체 재생성·화면 새로고침 없음).
 *  - 신규 디바이스: 마커 생성
 *  - 기존 디바이스: 색상(상태)이 바뀐 마커만 setImage, 저장 데이터만 갱신
 *  - 사라진 디바이스: 해당 마커만 제거
 * → 폴링 시 카카오 지도 타일·SDK 재호출 없음. 내 백엔드(/deviceMapList)만 조회.
 */
function upsertMarkers(devices) {
	var seen = {};
	(devices || []).forEach(function(device) {
		if (device.dv_lat == null || device.dv_lng == null) return;
		var id = device.dv_id;
		seen[id] = true;
		var color = getStatusColor(device);
		var entry = markerMap[id];

		if (!entry) {
			// 신규 마커
			var marker = new kakao.maps.Marker({
				map: map,
				position: new kakao.maps.LatLng(device.dv_lat, device.dv_lng),
				title: device.dv_name,
				image: markerImage(color)
			});
			kakao.maps.event.addListener(marker, "mouseover", function() { showDetailPopup(id); });
			kakao.maps.event.addListener(marker, "mouseout", function() { hideDetailPopup(); });
			markerMap[id] = { marker: marker, colorKey: color, device: device };
		} else {
			// 기존 마커: 데이터 갱신 + 색상 바뀐 경우에만 이미지 교체
			entry.device = device;
			if (entry.colorKey !== color) {
				entry.marker.setImage(markerImage(color));
				entry.colorKey = color;
			}
			// 좌표가 바뀐 경우에만 위치 갱신(드묾)
			var pos = entry.marker.getPosition();
			if (pos.getLat() != device.dv_lat || pos.getLng() != device.dv_lng) {
				entry.marker.setPosition(new kakao.maps.LatLng(device.dv_lat, device.dv_lng));
			}
		}
	});

	// 목록에서 사라진 디바이스의 마커만 제거
	Object.keys(markerMap).forEach(function(id) {
		if (!seen[id]) {
			markerMap[id].marker.setMap(null);
			delete markerMap[id];
		}
	});
}

function statusIcon(icon, value, label) {
	var cls = (String(value) === '1') ? "status-normal" : "status-error";
	return '<i class="fas fa-' + icon + ' status-icon ' + cls + '" title="' + label + '"></i>';
}

function esc(s) {
	if (s == null) return '';
	return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function showDetailPopup(id) {
	var entry = markerMap[id];
	if (!entry) return;
	var marker = entry.marker;
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/deviceDetail/" + id,
		method: "GET",
		dataType: "json",
		success: function(data) {
			var d = data.device || entry.device;
			var c = data.todayCount || {};
			var addr = esc(d.dv_addr) + (d.dv_addr_detail ? ' ' + esc(d.dv_addr_detail) : '');
			var html = '<div class="device-popup">'
				+ '<h4>' + esc(d.dv_name) + '</h4>'
				+ '<p class="addr">📍 ' + addr + '</p>'
				+ '<p class="section">📊 오늘 처리</p>'
				+ '<ul class="today">'
				+ '<li>계도 <b>' + (c.guide_cnt || 0) + '</b></li>'
				+ '<li>단속 <b>' + (c.enforce_cnt || 0) + '</b></li>'
				+ '<li>과태료 <b>' + (c.fine_cnt || 0) + '</b></li>'
				+ '</ul>'
				+ '<p class="section">디바이스 상태</p>'
				+ '<div class="status-row">'
				+ statusIcon("desktop", d.dv_status_pc, "PC")
				+ statusIcon("video", d.dv_status_cctv, "CCTV")
				+ statusIcon("eye", d.dv_lens, "렌즈")
				+ statusIcon("volume-high", d.dv_status_speaker, "스피커")
				+ statusIcon("phone", d.dv_status_sip, "SIP")
				+ '</div>'
				+ '</div>';

			hideDetailPopup();
			var overlay = new kakao.maps.CustomOverlay({
				content: html,
				position: marker.getPosition(),
				xAnchor: 0.5,
				yAnchor: 1.3,
				map: map
			});
			overlays.push(overlay);
		}
	});
}

function hideDetailPopup() {
	overlays.forEach(function(o) { o.setMap(null); });
	overlays = [];
}

function loadDevices() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/deviceMapList",
		method: "GET",
		dataType: "json",
		success: function(devices) {
			upsertMarkers(devices);
		}
	});
}

function initMap() {
	map = new kakao.maps.Map(document.getElementById("map"), {
		center: new kakao.maps.LatLng(35.1595, 126.8526), // 광주시청
		level: 8
	});
	loadDevices();
	setInterval(loadDevices, 10000); // 10초 폴링 (04 정합)
}

// ===== 작업계획서 12: 우측 카드 · 하단 최근 이벤트 요약 =====

// ev_cd / ev_action 변환 (DB v0.0.8 코드 주석 기준)
function convertEvCd(code) {
	return ({0:'정상', 1:'미등록차량', 2:'장애인미탑승', 3:'스티커불법사용', 4:'위험상황', 5:'물건적재', 6:'이중주차'})[code] || '기타';
}
function convertEvAction(action) {
	return ({0:'계도', 1:'단속', 2:'과태료'})[action] || '-';
}
function actionClass(action) {
	return ({0:'act-guide', 1:'act-enforce', 2:'act-fine'})[action] || '';
}

// 발생시각: ev_date(yyyyMMddHHmmss) 우선, 없으면 ev_reg_date
function formatEvDate(item) {
	var s = item.ev_date ? String(item.ev_date).trim() : '';
	if (/^\d{14}$/.test(s)) {
		return s.substr(0,4)+'-'+s.substr(4,2)+'-'+s.substr(6,2)+' '+s.substr(8,2)+':'+s.substr(10,2);
	}
	if (item.ev_reg_date) {
		var d = new Date(item.ev_reg_date);
		if (!isNaN(d.getTime())) {
			var p = function(n){ return n < 10 ? '0'+n : n; };
			return d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate())+' '+p(d.getHours())+':'+p(d.getMinutes());
		}
	}
	return s || '-';
}

// 오늘 날씨 — 기존 WeatherApiAdapter 엔드포인트(/api/external/weather/test, 기본 광주 좌표) 재사용
function loadWeather() {
	$.ajax({
		url: CONTEXT_PATH + "/api/external/weather/test",
		method: "GET", dataType: "json",
		success: function(data) {
			if (!data || !data.slots || !data.slots.length) {
				$('#weather-value').text('-');
				$('#weather-sub').text('날씨 정보 없음');
				return;
			}
			var s = data.slots[0];
			var label = (s.pty && s.pty !== '없음') ? s.pty : (s.sky || '-');
			$('#weather-value').text(label + (s.tmp ? ' · ' + s.tmp + '°C' : ''));
			$('#weather-sub').text('강수확률 ' + (s.pop || '0') + '%');
		},
		error: function() {
			$('#weather-value').text('-');
			$('#weather-sub').text('날씨 정보 없음');
		}
	});
}

// 우측 카드 — 오늘 계도·단속 합계
function loadTodaySummary() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/todaySummary",
		method: "GET", dataType: "json",
		success: function(data) {
			// 당일 데이터 없으면 SUM 이 null → 0 으로 표시
			$('#guide-value').text((data && data.guide_cnt != null) ? data.guide_cnt : 0);
			$('#enforce-value').text((data && data.enforce_cnt != null) ? data.enforce_cnt : 0);
		},
		error: function() {
			// 조회 실패 시에도 '-' 대신 0 유지
			$('#guide-value').text(0);
			$('#enforce-value').text(0);
		}
	});
}

// 하단 최근 이벤트 요약
function loadRecentEvents() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/recentEvents",
		method: "GET", dataType: "json",
		success: function(events) {
			if (!events || !events.length) {
				$('#recent-events-body').html('<tr><td colspan="6" class="empty-row">최근 이벤트가 없습니다.</td></tr>');
				return;
			}
			var html = '';
			events.forEach(function(e) {
				html += '<tr>'
					+ '<td>' + formatEvDate(e) + '</td>'
					+ '<td>' + esc(e.ev_dv_name) + '</td>'
					+ '<td>' + esc(e.ev_car_num) + '</td>'
					+ '<td>' + convertEvCd(e.ev_cd) + '</td>'
					+ '<td class="' + actionClass(e.ev_action) + '">' + convertEvAction(e.ev_action) + '</td>'
					+ '<td><button type="button" class="btn-detail" data-ev="' + e.ev_id + '" data-dv="' + (e.ev_dv_id != null ? e.ev_dv_id : '') + '">상세</button></td>'
					+ '</tr>';
			});
			$('#recent-events-body').html(html);
		},
		error: function() {
			$('#recent-events-body').html('<tr><td colspan="6" class="empty-row">이벤트 조회 오류</td></tr>');
		}
	});
}

$(document).ready(function() {
	// 카드·이벤트는 지도와 독립 로드 (지도 키가 없어도 동작)
	loadTodaySummary();
	loadRecentEvents();
	loadWeather();
	setInterval(loadTodaySummary, 60000);  // 1분 (카드 갱신)
	setInterval(loadRecentEvents, 30000);  // 30초 (최근 이벤트 갱신)

	$('#btnMoreEvents').on('click', function() {
		location.href = CONTEXT_PATH + '/eventList/viewEventList.do';
	});
	$('#recent-events-body').on('click', '.btn-detail', function() {
		var evId = $(this).data('ev');
		var dvId = $(this).data('dv');
		location.href = CONTEXT_PATH + '/eventList/eventListDetail?evId=' + evId + (dvId !== '' ? '&dvId=' + dvId : '');
	});

	// 지도 (11번) — 키 있을 때만
	if (!KAKAO_JS_KEY || typeof kakao === "undefined" || !kakao.maps) {
		$('#mapWarning').show();
		return;
	}
	kakao.maps.load(function() { initMap(); });
});
</script>
