<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%-- patches 13: 계도/단속 카드 링크용 오늘 날짜(yyyy-MM-dd). eventList 컨트롤러가 '-' 제거하므로 이 형식으로 전달 --%>
<% String today = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()); %>

<%-- Tiles body fragment (patches 2026-07-06). 공용 chrome(헤더·사이드바·푸터)은 template.jsp/defaultLayout 제공. jQuery 는 template 에서 로드 --%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/dashboard.css">
<%-- patches 14: 대시보드 전면 재설계 — 지도가 콘텐츠 전체를 채우고, 정보는 지도 안 반투명 오버레이 6개로 배치.
     기존 grid(좌 리스트·중앙 지도·우 카드·하단 이벤트)는 제거. 오버레이는 #map-container 기준 absolute. --%>
<style>
	/* ===== 레이아웃: 지도가 콘텐츠 영역을 가득 채움 ===== */
	.content { padding: 16px !important; }
	.dashboard-wrap { padding: 0 !important; display: flex; flex-direction: column; flex: 1 1 auto; min-height: 0; }
	#map-container { position: relative; flex: 1 1 auto; min-height: 540px; border: 1px solid #e3e6ea; border-radius: 8px; overflow: hidden; }
	#map { width: 100%; height: 100%; border: none !important; border-radius: 0 !important; }

	/* ===== 오버레이 위젯 공용 (계획서 4-1) ===== */
	.overlay-widget { position: absolute; z-index: 10; pointer-events: auto;
		background: rgba(255,255,255,0.85); backdrop-filter: blur(6px);
		border: 1px solid rgba(105,85,162,0.15); border-radius: 8px;
		box-shadow: 0 4px 12px rgba(0,0,0,0.10); overflow: hidden; }
	.overlay-widget .widget-header { display: flex; align-items: center; justify-content: space-between; gap: 8px;
		padding: 7px 10px; background: rgba(105,85,162,0.08); border-bottom: 1px solid rgba(105,85,162,0.15);
		cursor: pointer; user-select: none; }
	.overlay-widget .widget-title { font-size: 13px; font-weight: 600; color: #383351; white-space: nowrap; }
	.overlay-widget .widget-count { color: #6955A2; font-weight: 700; }
	.overlay-widget .header-actions { display: flex; align-items: center; gap: 6px; }
	.overlay-widget .toggle-btn { background: none; border: none; cursor: pointer; font-size: 12px; color: #6955A2; padding: 2px 4px; }
	.overlay-widget .widget-body { padding: 8px 10px; overflow-y: auto; transition: max-height .25s ease, padding .25s ease; }
	.overlay-widget.collapsed .widget-body { max-height: 0 !important; padding-top: 0; padding-bottom: 0; overflow: hidden; }
	.overlay-widget.collapsed .toggle-btn::before { content: '\25B2'; }        /* ▲ 확대 */
	.overlay-widget:not(.collapsed) .toggle-btn::before { content: '\25BC'; }  /* ▼ 축소 */

	/* ===== 우측 세로 스택 그룹 (마커 상태·날씨/처리·디바이스 상태) — 버튼 1개로 동시 축소/확대 ===== */
	/* (요청 2026-07-16) 지도 우상단 줌(+/-) 컨트롤을 가리지 않도록 오른쪽에서 62px 띄움 */
	.right-stack-group { position: absolute; top: 12px; right: 62px; width: 210px; z-index: 10; }
	.right-stack-group .group-toggle-btn { position: absolute; top: -6px; right: -6px; z-index: 11;
		background: rgba(105,85,162,0.92); color: #fff; border: none; padding: 3px 8px; border-radius: 4px; cursor: pointer; font-size: 11px; }
	.right-stack-group .overlay-widget { position: relative; top: auto; right: auto; width: 100%; margin-bottom: 8px; }
	.right-stack-group.collapsed .overlay-widget .widget-body { max-height: 0 !important; padding-top: 0; padding-bottom: 0; overflow: hidden; }

	/* ===== ① 좌상: 검색·디바이스 리스트 ===== */
	#deviceListOverlay { top: 12px; left: 12px; width: 285px; }
	#deviceListOverlay .widget-body { max-height: 330px; }
	.device-search-input { width: 100%; padding: 6px 10px; margin-bottom: 8px; border: 1px solid #D5D0E0; border-radius: 4px; font-size: 13px; box-sizing: border-box; background: #fff; }
	.device-search-input:focus { outline: none; border-color: #6955A2; }
	.dev-item { display: flex; gap: 8px; padding: 8px 6px; border-bottom: 1px solid rgba(0,0,0,0.06); cursor: pointer; }
	.dev-item:hover { background: rgba(245,242,255,0.9); }
	.dev-item.selected { background: rgba(236,231,251,0.95); }
	.dev-item-icon { font-size: 16px; margin-top: 1px; flex: 0 0 auto; }
	.dev-item-body { min-width: 0; }
	.dev-item-name { font-weight: 600; font-size: 12.5px; color: #222; }
	.dev-item-addr { font-size: 11.5px; color: #666; margin-top: 2px; }
	.dev-item-meta { font-size: 11px; color: #999; margin-top: 2px; }
	.dev-empty { padding: 14px 8px; color: #999; font-size: 12.5px; text-align: center; }
	/* 이름·주소 말줄임 + title 툴팁 (13번 정합 재사용) */
	.dev-item-name .cell-ellipsis, .dev-item-addr .cell-ellipsis { display: block; max-width: 100%; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }

	/* ===== ② 마커 상태 범례 (가로 압축) ===== */
	.marker-legend-widget .widget-body { display: flex; flex-wrap: wrap; gap: 6px 10px; }
	.marker-legend-widget .legend-row { display: flex; align-items: center; gap: 4px; font-size: 11px; color: #555; }
	.marker-legend-widget .marker-icon { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }

	/* ===== ③ 날씨·오늘 처리 (계도·단속 링크) ===== */
	.weather-summary-widget .weather-row { display: flex; align-items: center; gap: 6px; padding: 2px 0 6px;
		font-size: 13px; border-bottom: 1px solid rgba(105,85,162,0.1); margin-bottom: 6px; }
	.weather-summary-widget .weather-row i { color: #4F4A85; }
	.weather-summary-widget .weather-sub { margin-left: auto; font-size: 11px; color: #888; }
	.weather-summary-widget .split-row { display: flex; gap: 6px; }
	.weather-summary-widget .split-item { flex: 1; text-align: center; padding: 4px 0; background: rgba(252,251,255,0.7);
		border-radius: 4px; text-decoration: none; color: inherit; }
	.weather-summary-widget .split-item:hover { background: rgba(240,235,250,0.95); }
	.weather-summary-widget .split-item .label { display: block; font-size: 11px; color: #666; }
	.weather-summary-widget .split-item .value { display: block; font-size: 18px; font-weight: 700; }
	.weather-summary-widget .split-item.guide .value { color: #1a8a4a; }
	.weather-summary-widget .split-item.enforce .value { color: #d33333; }

	/* ===== ④ 디바이스 상태 (정상/이상 건수) ===== */
	.device-status-widget .status-row { display: flex; align-items: center; gap: 8px; padding: 3px 0; font-size: 12.5px; color: #555; }
	.device-status-widget .status-value { font-size: 19px; font-weight: 700; margin-left: auto; }
	.device-status-widget .status-value.normal { color: #28a745; }
	.device-status-widget .status-value.error { color: #dc3545; }
	.device-status-widget .status-unit { font-size: 11px; color: #999; }

	/* ===== ⑤ 좌하 최근 이벤트 / ⑥ 우하 응급 연락(SIP) ===== */
	#eventListOverlay { bottom: 12px; left: 12px; width: 430px; }
	#sipCallOverlay { bottom: 12px; right: 12px; width: 390px; }
	#eventListOverlay .widget-body, #sipCallOverlay .widget-body { max-height: 220px; }
	.view-all-btn { font-size: 11px; color: #6955A2; text-decoration: none; padding: 3px 8px; border: 1px solid #6955A2; border-radius: 4px; white-space: nowrap; }
	.view-all-btn:hover { background: #6955A2; color: #fff; }
	.event-mini-table, .sip-mini-table { width: 100%; border-collapse: collapse; font-size: 12px; }
	.event-mini-table th, .sip-mini-table th { background: rgba(245,240,250,0.95); padding: 5px 6px; text-align: left; font-weight: 600; color: #555; position: sticky; top: 0; }
	.event-mini-table td, .sip-mini-table td { padding: 5px 6px; border-bottom: 1px solid rgba(0,0,0,0.06); }
	.event-mini-table .empty-row, .sip-mini-table .empty-row { text-align: center; color: #999; padding: 12px 6px; }
	.act-guide { color: #1a8a4a; font-weight: 600; }
	.act-enforce { color: #d33333; font-weight: 600; }
	.act-fine { color: #b5179e; font-weight: 600; }
	.btn-mini-audio { border: 1px solid #cfc6ea; background: #fff; color: #4F4A85; border-radius: 4px; padding: 2px 7px; cursor: pointer; font-size: 11px; }
	.btn-mini-audio:hover { background: #ece7fb; }
	.sip-mini-audio-row > td { background: rgba(245,242,255,0.95); padding: 6px !important; }
	.no-audio { color: #bbb; }
</style>
<!-- Font Awesome (상태 아이콘) -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<!-- 카카오 지도 JavaScript SDK (services=Geocoder 등). autoload=false → kakao.maps.load 로 초기화 -->
<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoMapJsKey}&libraries=services,clusterer&autoload=false"></script>
<%-- patches 14(4-7): SIP 위젯 미니 파형 재생(7/9 인라인 재생 방식 재사용). UMD 빌드로 전역 WaveSurfer 노출 --%>
<script src="https://cdn.jsdelivr.net/npm/wavesurfer.js@7/dist/wavesurfer.min.js"></script>
<script>
	const CONTEXT_PATH = "${pageContext.request.contextPath}";
	const KAKAO_JS_KEY = "${kakaoMapJsKey}";
</script>

<div class="dashboard-wrap">
	<%-- patches 2026-07-09: 최상단 제목 제거(피드백). 마커 상태 범례는 우측 카드로 이동 --%>
	<div id="mapWarning" class="map-warning" style="display:none;">
		카카오 지도 키(kakao.map.js-key)가 설정되지 않았거나 지도를 불러올 수 없습니다.
		<br>globals.properties 의 <b>kakao.map.js-key</b>(환경변수 KAKAO_MAP_JS_KEY)를 확인하세요.
	</div>

	<%-- patches 14: 지도 전체 + 지도 안 오버레이 6개(하단 grid 제거). 초기 진입 시 전부 열림(효성 결정) --%>
	<div id="map-container">
		<div id="map"></div>

		<%-- ① 좌상: 검색 · 디바이스 리스트 --%>
		<div class="overlay-widget" id="deviceListOverlay">
			<div class="widget-header">
				<span class="widget-title">단속 장비 현황 <span class="widget-count" id="deviceListCount">0</span></span>
				<button class="toggle-btn" type="button"></button>
			</div>
			<div class="widget-body">
				<input type="text" id="deviceSearchInput" class="device-search-input" placeholder="이름·주소로 검색" />
				<div id="deviceListItems">
					<div class="dev-empty">불러오는 중...</div>
				</div>
			</div>
		</div>

		<%-- ②③④ 우측 세로 스택 그룹 — 토글 버튼 1개로 3개 위젯 동시 축소/확대(위치 유지) --%>
		<div class="right-stack-group" id="rightStackGroup">
			<button id="rightStackToggle" class="group-toggle-btn" type="button">&#9660;</button>

			<%-- ② 마커 상태 --%>
			<div class="overlay-widget marker-legend-widget">
				<div class="widget-header"><span class="widget-title">마커 상태</span></div>
				<div class="widget-body">
					<div class="legend-row"><span class="marker-icon" style="background:#28a745"></span><span>정상</span></div>
					<div class="legend-row"><span class="marker-icon" style="background:#ffc107"></span><span>이상 1~2</span></div>
					<div class="legend-row"><span class="marker-icon" style="background:#dc3545"></span><span>이상 3+</span></div>
					<div class="legend-row"><span class="marker-icon" style="background:#808080"></span><span>30분+ 미갱신</span></div>
				</div>
			</div>

			<%-- ③ 날씨 · 오늘 처리(계도/단속 → 오늘 날짜 + evAction 필터로 이동) --%>
			<div class="overlay-widget weather-summary-widget">
				<div class="widget-header"><span class="widget-title">날씨 · 오늘 처리</span></div>
				<div class="widget-body">
					<div class="weather-row">
						<i class="fas fa-cloud-sun"></i>
						<span id="weather-value">-</span>
						<span class="weather-sub" id="weather-sub"></span>
					</div>
					<div class="split-row">
						<a class="split-item guide"
							href="${pageContext.request.contextPath}/eventList/viewEventList.do?startDate=<%= today %>&endDate=<%= today %>&evAction=0">
							<span class="label">계도</span>
							<span class="value" id="guide-value">0</span>
						</a>
						<a class="split-item enforce"
							href="${pageContext.request.contextPath}/eventList/viewEventList.do?startDate=<%= today %>&endDate=<%= today %>&evAction=1">
							<span class="label">단속</span>
							<span class="value" id="enforce-value">0</span>
						</a>
					</div>
				</div>
			</div>

			<%-- ④ 디바이스 상태(정상/이상 건수) — 신규 --%>
			<div class="overlay-widget device-status-widget">
				<div class="widget-header"><span class="widget-title">디바이스 상태</span></div>
				<div class="widget-body">
					<div class="status-row">
						<span class="status-label">정상</span>
						<span class="status-value normal" id="deviceNormalCount">0</span>
						<span class="status-unit">건</span>
					</div>
					<div class="status-row">
						<span class="status-label">이상</span>
						<span class="status-value error" id="deviceErrorCount">0</span>
						<span class="status-unit">건</span>
					</div>
				</div>
			</div>
		</div>

		<%-- ⑤ 좌하: 최근 이벤트(3건) --%>
		<div class="overlay-widget event-list-widget" id="eventListOverlay">
			<div class="widget-header">
				<span class="widget-title">최근 이벤트</span>
				<span class="header-actions">
					<a href="${pageContext.request.contextPath}/eventList/viewEventList.do" class="view-all-btn">전체 보기</a>
					<button class="toggle-btn" type="button"></button>
				</span>
			</div>
			<div class="widget-body">
				<table class="event-mini-table">
					<thead>
						<tr><th>디바이스</th><th>차량 번호</th><th>처리</th><th>시각</th></tr>
					</thead>
					<tbody id="recentEventListItems">
						<tr><td colspan="4" class="empty-row">불러오는 중...</td></tr>
					</tbody>
				</table>
			</div>
		</div>

		<%-- ⑥ 우하: 최근 응급 연락(SIP) — 듣기 시 행 아래 미니 파형 인라인 재생 --%>
		<div class="overlay-widget sip-widget" id="sipCallOverlay">
			<div class="widget-header">
				<span class="widget-title">최근 응급 연락</span>
				<span class="header-actions">
					<a href="${pageContext.request.contextPath}/sipcall/sipCallLog" class="view-all-btn">전체 보기</a>
					<button class="toggle-btn" type="button"></button>
				</span>
			</div>
			<div class="widget-body">
				<table class="sip-mini-table">
					<thead>
						<tr><th>디바이스</th><th>통화 시각</th><th>듣기</th></tr>
					</thead>
					<tbody id="recentSipCallItems">
						<tr><td colspan="3" class="empty-row">불러오는 중...</td></tr>
					</tbody>
				</table>
			</div>
		</div>
	</div>
</div>

<script>
var map = null;
var markerMap = {};   // dv_id -> { marker, colorKey, device } — 부분 갱신용(전체 재생성 회피)
var overlays = [];
var clusterer = null; // MarkerClusterer (patches 2026-07-09(7): 겹친 마커 수 표시 → 확대 시 개별 마커)
var isPopupPinned = false; // patches 13(4-6): 마커/리스트 클릭으로 상세 팝업 고정 여부(고정 중 hover 무시, 지도 조작 시 해제)
var suppressUnpin = false; // focusDevice 의 프로그램적 setLevel/setCenter 가 유발하는 zoom_changed 로 즉시 해제되는 것 방지

// patches 13(4-6): 좌측 리스트 클릭·마커 클릭 공용 동작 — 지도 중심 이동·확대·항목 선택·팝업 고정
function focusDevice(id, lat, lng) {
	if (!map) return;
	var la = parseFloat(lat), ln = parseFloat(lng);
	if (isNaN(la) || isNaN(ln)) return;
	suppressUnpin = true;                             // 아래 setLevel/setCenter 로 인한 자동 해제 억제
	map.setLevel(3);                                  // 클러스터 해제 수준까지 확대 → 개별 마커 노출
	map.setCenter(new kakao.maps.LatLng(la, ln));     // 중심 이동
	$('.dev-item').removeClass('selected');
	$('.dev-item[data-id="' + id + '"]').addClass('selected');
	showDetailPopup(id);                              // 상세 팝업 표시
	isPopupPinned = true;                             // 고정(이후 사용자의 지도 drag/zoom 시 해제)
	setTimeout(function() { suppressUnpin = false; }, 300); // 프로그램적 이동 이벤트 정리 후 억제 해제
}

// patches 13(4-6): 지도 조작(드래그·줌) 시 고정 팝업 해제
function unpinPopup() {
	if (suppressUnpin) return;   // 프로그램적 이동은 무시
	if (isPopupPinned) {
		hideDetailPopup();
		isPopupPinned = false;
		$('.dev-item').removeClass('selected');
	}
}

// dv_status_updated 가 30분 이상 지났는지(미갱신 → 회색)
function isStale(device) {
	if (device.dv_status_updated) {
		var updated = new Date(device.dv_status_updated);
		if (!isNaN(updated.getTime()) && (Date.now() - updated.getTime() > 30 * 60 * 1000)) return true;
	}
	return false;
}
// 이상 개수 — 상태 5종 중 '정상(1)'이 아닌 값(이상 0 · null · 미보고)을 모두 '이상'으로 집계
//   → 디바이스 리스트의 "값 없으면 이상" 정책과 일치.
function deviceErrorCount(device) {
	return [
		device.dv_status_pc,
		device.dv_status_cctv,
		device.dv_lens,
		device.dv_status_speaker,
		device.dv_status_sip
	].filter(function(v) { return String(v) !== '1'; }).length;
}
// 상태 문자열 (리스트 표시용)
function statusText(device) {
	if (isStale(device)) return '미갱신';
	var e = deviceErrorCount(device);
	return e === 0 ? '정상' : ('이상 ' + e);
}

// 상태 색상 (DB v0.0.8: 상태 5종, dv_status_display 제외)
function getStatusColor(device) {
	if (isStale(device)) return "#808080";   // 회색: 30분+ 미갱신
	var errorCount = deviceErrorCount(device);
	if (errorCount === 0) return "#28a745"; // 초록: 5종 모두 정상
	if (errorCount <= 2) return "#ffc107";  // 노랑: 이상 1~2
	return "#dc3545";                        // 빨강: 이상 3+
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
			// 신규 마커 — 지도에 직접 붙이지 않고 클러스터러에 추가(겹칠 때 숫자 표시)
			var marker = new kakao.maps.Marker({
				position: new kakao.maps.LatLng(device.dv_lat, device.dv_lng),
				title: device.dv_name,
				image: markerImage(color)
			});
			// hover — 고정 팝업 상태면 무시(patches 13(4-6))
			kakao.maps.event.addListener(marker, "mouseover", function() { if (!isPopupPinned) showDetailPopup(id); });
			kakao.maps.event.addListener(marker, "mouseout", function() { if (!isPopupPinned) hideDetailPopup(); });
			// 마커 클릭 — 좌측 리스트 클릭과 동일 동작(중심 이동·확대·항목 선택·팝업 고정)
			kakao.maps.event.addListener(marker, "click", function() { focusDevice(id, device.dv_lat, device.dv_lng); });
			if (clusterer) clusterer.addMarker(marker);
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

	// 목록에서 사라진 디바이스의 마커만 제거(클러스터러에서도 제거)
	Object.keys(markerMap).forEach(function(id) {
		if (!seen[id]) {
			if (clusterer) clusterer.removeMarker(markerMap[id].marker);
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
			renderDeviceList(devices);
		}
	});
}

// (3) 지도 좌측 디바이스 목록 — 등록되어 있고 마커까지 정상 표시되는 디바이스만:
//     dv_name·dv_serial_number·dv_addr 가 null 아니고, lat·lng 도 null 아님.
//     클릭 시 지도 중심을 해당 디바이스 좌표로 이동.
function isPresent(v) { return v != null && String(v).trim() !== ''; }

var lastDeviceListSig = null;   // 목록 변경 없을 때 재렌더 생략(스크롤·선택 유지)
function renderDeviceList(devices) {
	var items = (devices || []).filter(function(d) {
		return isPresent(d.dv_name) && isPresent(d.dv_serial_number) && isPresent(d.dv_addr)
			&& d.dv_lat != null && d.dv_lng != null;
	});
	// 목록 구성(디바이스·상태색)이 이전과 동일하면 다시 그리지 않음 → 10초 폴링 시 스크롤/선택 유지
	var sig = items.map(function(d) { return d.dv_id + ':' + getStatusColor(d); }).join('|');
	if (sig === lastDeviceListSig) return;
	lastDeviceListSig = sig;

	$('#deviceListCount').text(items.length);
	if (!items.length) {
		$('#deviceListItems').html('<div class="dev-empty">표시할 디바이스가 없습니다.</div>');
		return;
	}
	// 속성값 안전 이스케이프(title 툴팁용): esc + 큰따옴표 처리
	function attr(s) { return esc(s).replace(/"/g, '&quot;'); }
	var html = '';
	items.forEach(function(d) {
		var color = getStatusColor(d);
		var addrText = (d.dv_addr || '') + (d.dv_addr_detail ? ' ' + d.dv_addr_detail : '');
		var addrHtml = esc(d.dv_addr) + (d.dv_addr_detail ? ' ' + esc(d.dv_addr_detail) : '');
		// patches 13(4-3): 이름·주소를 cell-ellipsis 말줄임 + title 툴팁(길면 hover 로 전체 확인)
		html += '<div class="dev-item" data-id="' + d.dv_id + '" data-lat="' + d.dv_lat + '" data-lng="' + d.dv_lng + '">'
			+ '<i class="fas fa-map-marker-alt dev-item-icon" style="color:' + color + '"></i>'
			+ '<div class="dev-item-body">'
			+   '<div class="dev-item-name"><span class="cell-ellipsis" title="' + attr(d.dv_name) + '">' + esc(d.dv_name) + '</span></div>'
			+   '<div class="dev-item-addr"><span class="cell-ellipsis" title="' + attr(addrText) + '">' + addrHtml + '</span></div>'
			+   '<div class="dev-item-meta">SN ' + esc(d.dv_serial_number) + ' · ' + statusText(d) + '</div>'
			+ '</div>'
			+ '</div>';
	});
	$('#deviceListItems').html(html);
	// 재렌더 후 현재 검색어 필터 재적용(폴링으로 목록이 갱신돼도 필터 유지)
	if ($('#deviceSearchInput').val()) $('#deviceSearchInput').trigger('input');
}

// 카카오맵 초기 위치 및 줌 설정
function initMap() {
	map = new kakao.maps.Map(document.getElementById("map"), {
		center: new kakao.maps.LatLng(35.1595, 126.8526), // 광주시청
		level: 7 // 초기 줌 
	});

	// (1) 줌 컨트롤(+/-) — 오른쪽 상단
	map.addControl(new kakao.maps.ZoomControl(), kakao.maps.ControlPosition.TOPRIGHT);

	// 지도 조작(드래그·줌) 시 고정 팝업 해제
	kakao.maps.event.addListener(map, "dragstart", unpinPopup);
	kakao.maps.event.addListener(map, "zoom_changed", unpinPopup);

	// (2) 마커 클러스터러 — 겹친 마커는 숫자로 묶고, 확대(레벨 < minLevel)하면 개별 마커 표시
	clusterer = new kakao.maps.MarkerClusterer({
		map: map,
		averageCenter: true,   // 묶인 마커들의 평균 위치에 클러스터 표시
		minLevel: 5,           // 지도 레벨 5 이상(축소 상태)에서 클러스터링. 확대하면 개별 마커
		gridSize: 60,
		disableClickZoom: false // 클러스터 클릭 시 확대
	});

	loadDevices();
	setInterval(loadDevices, 10000); // 10초 폴링 (04 정합)
	fitMapSoon();   // 생성 직후, 현재 카드 열 높이에 맞춰 1회 재배치(날씨가 먼저 로드된 경우 대비)
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

// 카드 열 높이가 바뀌면(날씨 로드 등) 지도 캔버스를 컨테이너 크기에 맞춰 재배치.
// (Kakao 지도는 컨테이너가 커져도 캔버스가 자동 확장되지 않아 relayout 필요 → 지도 하단 회색/여백 방지)
function fitMapSoon() {
	setTimeout(function() { if (map && map.relayout) map.relayout(); }, 60);
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
				fitMapSoon();
				return;
			}
			var s = data.slots[0];
			var label = (s.pty && s.pty !== '없음') ? s.pty : (s.sky || '-');
			$('#weather-value').text(label + (s.tmp ? ' · ' + s.tmp + '°C' : ''));
			$('#weather-sub').text('강수확률 ' + (s.pop || '0') + '%');
			fitMapSoon();   // 날씨 텍스트 생성으로 카드 열 높이 변동 → 지도 재배치
		},
		error: function() {
			$('#weather-value').text('-');
			$('#weather-sub').text('날씨 정보 없음');
			fitMapSoon();
		}
	});
}

// ===== patches 14(4-5): 디바이스 상태 요약(정상/이상 건수) =====
function loadDeviceStatus() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/deviceStatusSummary",
		method: "GET", dataType: "json",
		success: function(data) {
			$('#deviceNormalCount').text((data && data.normal_cnt != null) ? data.normal_cnt : 0);
			$('#deviceErrorCount').text((data && data.error_cnt != null) ? data.error_cnt : 0);
		},
		error: function() {
			$('#deviceNormalCount').text(0);
			$('#deviceErrorCount').text(0);
		}
	});
}

// ===== patches 14(4-7): 최근 응급 연락(SIP) 위젯 =====
// 통화 시각: sc_start_date(yyyyMMddHHmmss) → MM-DD HH:mm, 통화시간(초) 병기
function formatSipTime(v, duration) {
	var s = (v == null) ? '' : String(v).trim();
	var t = '-';
	if (/^\d{14}$/.test(s)) {
		t = s.substr(4,2) + '-' + s.substr(6,2) + ' ' + s.substr(8,2) + ':' + s.substr(10,2);
	} else if (s) {
		t = s;
	}
	return t + (duration != null ? ' (' + duration + '초)' : '');
}

function loadRecentSipCalls() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/recentSipCalls?limit=3",
		method: "GET", dataType: "json",
		success: function(list) {
			if (!list || !list.length) {
				$('#recentSipCallItems').html('<tr><td colspan="3" class="empty-row">최근 통화가 없습니다.</td></tr>');
				return;
			}
			var html = '';
			list.forEach(function(item) {
				var hasAudio = String(item.sc_has_audio) === '1' && item.sc_audio_path;
				var btn = hasAudio
					? '<button type="button" class="btn-mini-audio" data-scid="' + item.sc_id + '">듣기</button>'
					: '<span class="no-audio">-</span>';
				html += '<tr>'
					+ '<td>' + esc(item.dv_name || ('ID ' + (item.sc_dv_id != null ? item.sc_dv_id : '-'))) + '</td>'
					+ '<td>' + formatSipTime(item.sc_start_date, item.sc_duration) + '</td>'
					+ '<td>' + btn + '</td>'
					+ '</tr>';
			});
			$('#recentSipCallItems').html(html);
		},
		error: function() {
			$('#recentSipCallItems').html('<tr><td colspan="3" class="empty-row">통화 조회 오류</td></tr>');
		}
	});
}

// 미니 파형 인라인 재생 — 단일 인스턴스(다른 것 자동 정리), 같은 행 재클릭 시 닫기(토글)
var miniWavesurfer = null;
function closeMiniAudio() {
	if (miniWavesurfer) { miniWavesurfer.destroy(); miniWavesurfer = null; }
	$('.sip-mini-audio-row').remove();
}

// ===== patches 14(4-1): 오버레이 축소/확대 =====
function bindOverlayToggles() {
	// 헤더 클릭(토글 버튼 포함) → 해당 위젯 축소/확대. 링크(전체 보기) 클릭은 제외.
	// 우측 세로 스택 그룹의 3개 위젯은 그룹 버튼 1개로만 제어(§3-3 결정) → 개별 토글 제외.
	$(document).on('click', '.overlay-widget .widget-header', function(e) {
		if ($(e.target).closest('a').length) return;                 // '전체 보기' 링크는 이동만
		var $w = $(this).closest('.overlay-widget');
		if ($w.closest('.right-stack-group').length) return;         // 그룹 소속은 그룹 버튼으로만
		$w.toggleClass('collapsed');
	});
	// 우측 세로 스택 그룹 — 버튼 1개로 3개 동시 축소/확대(위치 유지)
	$('#rightStackToggle').on('click', function(e) {
		e.stopPropagation();
		var collapsed = $('#rightStackGroup').toggleClass('collapsed').hasClass('collapsed');
		$(this).html(collapsed ? '&#9650;' : '&#9660;');   // ▲ / ▼
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

// 좌하단 최근 이벤트 오버레이 (patches 14(4-6): 미니 테이블 — 디바이스·차량번호·처리·시각, 3건)
function loadRecentEvents() {
	$.ajax({
		url: CONTEXT_PATH + "/dashboard/recentEvents?limit=3",
		method: "GET", dataType: "json",
		success: function(events) {
			if (!events || !events.length) {
				$('#recentEventListItems').html('<tr><td colspan="4" class="empty-row">최근 이벤트가 없습니다.</td></tr>');
				return;
			}
			var html = '';
			events.forEach(function(e) {
				html += '<tr>'
					+ '<td>' + esc(e.ev_dv_name) + '</td>'
					+ '<td>' + esc(e.ev_car_num) + '</td>'
					+ '<td class="' + actionClass(e.ev_action) + '">' + convertEvAction(e.ev_action) + '</td>'
					+ '<td>' + formatEvDate(e) + '</td>'
					+ '</tr>';
			});
			$('#recentEventListItems').html(html);
		},
		error: function() {
			$('#recentEventListItems').html('<tr><td colspan="4" class="empty-row">이벤트 조회 오류</td></tr>');
		}
	});
}

$(document).ready(function() {
	// 오버레이 위젯 축소/확대 바인딩 (patches 14(4-1))
	bindOverlayToggles();

	// 위젯 데이터는 지도와 독립 로드 (지도 키가 없어도 동작). 진입 시 병렬 호출 — 순서 의존 X
	loadTodaySummary();
	loadRecentEvents();
	loadWeather();
	loadDeviceStatus();     // patches 14(4-5)
	loadRecentSipCalls();   // patches 14(4-7)
	setInterval(loadTodaySummary, 60000);   // 1분
	setInterval(loadRecentEvents, 30000);   // 30초
	setInterval(loadDeviceStatus, 30000);   // 30초 (디바이스 상태)
	setInterval(loadRecentSipCalls, 60000); // 1분 (최근 통화)

	// SIP 위젯 '듣기' — 해당 행 아래 미니 파형 인라인 재생(단일 인스턴스, 재클릭 시 닫기)
	$('#recentSipCallItems').on('click', '.btn-mini-audio', function() {
		var scId = $(this).attr('data-scid');
		var $tr = $(this).closest('tr');
		var $next = $tr.next('.sip-mini-audio-row');
		if ($next.length && String($next.attr('data-scid')) === String(scId)) { closeMiniAudio(); return; }
		closeMiniAudio();
		$tr.after('<tr class="sip-mini-audio-row" data-scid="' + scId + '"><td colspan="3">'
			+ '<div id="mini-waveform-' + scId + '"></div></td></tr>');
		miniWavesurfer = WaveSurfer.create({
			container: '#mini-waveform-' + scId,
			waveColor: '#4F4A85',
			progressColor: '#383351',
			height: 32,
			url: CONTEXT_PATH + '/sipcall/audio/' + scId
		});
		miniWavesurfer.on('ready', function() { miniWavesurfer.play(); });
		miniWavesurfer.on('error', function() {
			$('#mini-waveform-' + scId).html('<span class="no-audio" style="font-size:11px;">오디오를 불러오지 못했습니다.</span>');
		});
	});

	// (3) 좌측 디바이스 목록 클릭 → 마커 클릭과 동일 동작(공용 focusDevice, patches 13(4-6))
	$('#deviceListItems').on('click', '.dev-item', function() {
		focusDevice($(this).attr('data-id'), $(this).attr('data-lat'), $(this).attr('data-lng'));
	});

	// patches 13(4-2): 좌측 목록 이름·주소 실시간 필터(목록만, 지도 마커 미연동)
	$('#deviceSearchInput').on('input', function() {
		var kw = $(this).val().trim().toLowerCase();
		$('#deviceListItems .dev-item').each(function() {
			var name = ($(this).find('.dev-item-name').text() || '').toLowerCase();
			var addr = ($(this).find('.dev-item-addr').text() || '').toLowerCase();
			$(this).toggle(kw === '' || name.indexOf(kw) !== -1 || addr.indexOf(kw) !== -1);
		});
	});

	// 지도 (11번) — 키 있을 때만
	if (!KAKAO_JS_KEY || typeof kakao === "undefined" || !kakao.maps) {
		$('#mapWarning').show();
		return;
	}
	kakao.maps.load(function() { initMap(); });
});
</script>
