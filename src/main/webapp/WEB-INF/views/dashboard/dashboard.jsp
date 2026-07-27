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
	.content { padding: 16px !important;}
	.dashboard-wrap { padding: 0 !important; display: flex; flex-direction: column; flex: 1 1 auto; height:100%; gap:16px;}
	#map-container { position: relative; flex: 1 1 auto; width:calc(100% - 316px); height:100%; border: 1px solid #e3e6ea; border-radius: 8px; overflow: hidden; }
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
	<%-- overflow 는 !important — 좌측 통합 컨테이너가 id 선택자로 visible 을 지정하므로,
	     접었을 때 내용이 밖으로 삐져나오지 않도록 여기서 반드시 이겨야 한다 (15번 4-1) --%>
	.overlay-widget.collapsed .widget-body { max-height: 0 !important; padding-top: 0; padding-bottom: 0; overflow: hidden !important; }
	.overlay-widget.collapsed .toggle-btn::before { content: '\25B2'; }        /* ▲ 확대 */
	.overlay-widget:not(.collapsed) .toggle-btn::before { content: '\25BC'; }  /* ▼ 축소 */

	/* ===== 우측 세로 스택 그룹 (마커 상태·날씨/처리·디바이스 상태) — 버튼 1개로 동시 축소/확대 ===== */
	/* (요청 2026-07-16) 지도 우상단 줌(+/-) 컨트롤을 가리지 않도록 오른쪽에서 62px 띄움 */
	.right-stack-group { position: absolute; top: 12px; right: 62px; width: 210px; z-index: 10; }
	.right-stack-group .group-toggle-btn { position: absolute; top: -6px; right: -6px; z-index: 11;
		background: rgba(105,85,162,0.92); color: #fff; border: none; padding: 3px 8px; border-radius: 4px; cursor: pointer; font-size: 11px; }
	.right-stack-group .overlay-widget { position: relative; top: auto; right: auto; width: 100%; margin-bottom: 8px; }
	.right-stack-group.collapsed .overlay-widget .widget-body { max-height: 0 !important; padding-top: 0; padding-bottom: 0; overflow: hidden; }

	/* ===== ① 좌측 통합 컨테이너: 검색·디바이스 리스트 + 하위 2컬럼 (15번 4-1) ===== */
	/* 기존 좌상 리스트 오버레이를 확장. 목록만 스크롤하고 하위 2컬럼은 항상 보이도록
	   widget-body 가 아닌 #deviceListItems 에 max-height 를 준다. */
	#leftUnifiedOverlay { top: 12px; left: 12px; width: 320px; }
	#leftUnifiedOverlay .widget-body { overflow: visible; }
	#deviceListItems { max-height: 260px; overflow-y: auto; }
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

	/* ===== ①-하위 2컬럼: 계도/단속 · 디바이스 상태 (15번 4-1) ===== */
	.sub-columns-group { display: flex; gap: 8px; margin-top: 10px; padding-top: 10px;
		border-top: 1px solid rgba(105,85,162,0.15); }
	.sub-column { flex: 1; background: rgba(252,251,255,0.6); border-radius: 6px; padding: 8px; }
	.sub-column .split-row { display: flex; gap: 6px; }
	.sub-column .split-item { flex: 1; text-align: center; text-decoration: none; color: inherit;
		border-radius: 4px; padding: 2px 0; }
	.sub-column .split-item:hover { background: rgba(240,235,250,0.95); }
	.sub-column .split-item .label { display: block; font-size: 11px; color: #666; }
	.sub-column .split-item .value { display: block; font-size: 16px; font-weight: 700; color: #383351; }
	.sub-column .split-item.guide .value { color: #1a8a4a; }
	.sub-column .split-item.enforce .value { color: #d33333; }
	.sub-column .status-row { display: flex; justify-content: space-between; align-items: center;
		padding: 3px 0; font-size: 12px; color: #555; }
	.sub-column .status-value { font-size: 16px; font-weight: 700; }
	.sub-column .status-value.normal { color: #28a745; }
	.sub-column .status-value.error { color: #dc3545; }

	/* ===== ③ 날씨 =====
	   (15번 4-1) 계도·단속 split-item 과 디바이스 상태 위젯 스타일은 좌측 .sub-column 으로 이관되어 제거 */
	.weather-summary-widget .weather-row { display: flex; align-items: center; gap: 6px; padding: 2px 0;
		font-size: 13px; }
	.weather-summary-widget .weather-row i { color: #4F4A85; }
	.weather-summary-widget .weather-sub { margin-left: auto; font-size: 11px; color: #888; }

	/* ===== ⑤ 좌하 최근 이벤트 / ⑥ 우하 응급 연락(SIP) ===== */
	.list-area {display:flex; gap:16px; height:163px;}
	#eventListOverlay {position:relative; width:100%; height:100%;}
	#sipCallOverlay {position:relative; width:100%; height:100%;}
	#eventListOverlay .widget-body, #sipCallOverlay .widget-body { height:calc(100% - 38px); overflow-y:scroll; }
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

	/* 260724 서희원 추가 */
	.main-content-wrap {width:100%; height:calc(100% - 179px); display:flex; gap:16px;}
	.checkdown-state {width: 200px;height: 100%;margin: 0;list-style: none;padding: 0;display: grid;grid-template-rows: repeat(4, 1fr);gap: 8px;}
	.checkdown-state li {width: 100%;background: #fff;border: 1px solid rgba(105, 85, 162, 0.15);border-radius: 8px;box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);display: flex;padding: 16px;gap: 10px;}
	.checkdown-state li > div {height:100%;}
	.ico-checkdown {width: 54px;display: flex;align-items: center;justify-content: center;}
	.ico-checkdown.unregistered {color:#4b33a5;}
	.ico-checkdown.noDisability {fill:#1091ab;}
	.ico-checkdown.illegalStickers {color:#388321;}
	.ico-checkdown.warning {color:#cd5757;}
	.ico-checkdown.carrying {color:#5f65bd;}
	.ico-checkdown.doubleParking {color:#af5aa0;}
	.checkdown-text {display: flex;flex-wrap: wrap;align-content: center;justify-content: center;gap:.2rem;width:calc(100% - 44px);}
	.checkdown-text > div {width:100%; text-align: center;}
	.checkdown-text .label {font-size: 14px;font-weight: 400;color: #8d8d8d;}
	.checkdown-text .value {font-size:1.2rem;font-weight:600;}
</style>
<!-- Font Awesome (상태 아이콘) -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<!-- 카카오 지도 JavaScript SDK (services=Geocoder 등). autoload=false → kakao.maps.load 로 초기화 -->
<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoMapJsKey}&libraries=services,clusterer&autoload=false"></script>
<%--<script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=155ad6c4666c437c10968bd237df751d&libraries=services,clusterer&autoload=false"></script>--%>
<%-- patches 14(4-7): SIP 위젯 미니 파형 재생(7/9 인라인 재생 방식 재사용). UMD 빌드로 전역 WaveSurfer 노출 --%>
<script src="https://cdn.jsdelivr.net/npm/wavesurfer.js@7/dist/wavesurfer.min.js"></script>
<script>
	const CONTEXT_PATH = "${pageContext.request.contextPath}";
	const KAKAO_JS_KEY = "${kakaoMapJsKey}";
	// const KAKAO_JS_KEY = "155ad6c4666c437c10968bd237df751d";

</script>

<div class="dashboard-wrap">
	<div class="main-content-wrap">
		<%-- patches 2026-07-24: 주차 단속 현황 --%>
		<ul class="checkdown-state">
			<li>
				<div class="ico-checkdown unregistered">
					<svg viewBox="0 0 24 24" fill="currentColor">
						<path d="M22.207 20.793L20.793 22.207L19.5859 21H16V17.4141L15 16.4141V21H9V10.4141L1.79297 3.20703L3.20703 1.79297L22.207 20.793ZM8 21H2V13H8V21ZM4 19H6V15H4V19ZM11 19H13V14.4141L11 12.4141V19ZM22 17.7578L20 15.7578V5H18V13.7578L16 11.7578V3H22V17.7578ZM15 10.7578L12.2422 8H15V10.7578Z"/>
					</svg>
				</div>
				<div class="checkdown-text">
					<div class="label">미등록차량</div>
					<div class="value"><span id="eventCount1">0</span>건</div>
				</div>
			</li>
<%--			<li>--%>
<%--				<div class="ico-checkdown noDisability">--%>
<%--					<svg viewBox="0 0 19.04 20.79">--%>
<%--						<g>--%>
<%--							<path d="M9.52,15.14h1.14l-4.14-4.6v1.6c0,1.66,1.34,3,3,3Z"/>--%>
<%--							<path d="M12.52,10.72v-2.59c0-1.66-1.34-3-3-3-.59,0-1.14.18-1.6.47l4.6,5.11Z"/>--%>
<%--							<path d="M9.52,5.14c1.38,0,2.5-1.12,2.5-2.5S10.9.14,9.52.14s-2.5,1.12-2.5,2.5,1.12,2.5,2.5,2.5Z"/>--%>
<%--							<path d="M11.56,16.14h-.58c-.69,1.2-1.98,2-3.46,2-2.21,0-4-1.79-4-4,0-1.48.8-2.77,2-3.46v-1.25s-.61-.67-.61-.67c-2,.97-3.39,3.01-3.39,5.39,0,3.31,2.69,6,6,6,2.15,0,4.02-1.14,5.08-2.84l-1.04-1.16Z"/>--%>
<%--						</g>--%>
<%--						<rect x="8.35" y="-2.53" width="2.35" height="25.86"--%>
<%--							  transform="translate(-4.51 9.04) rotate(-41.98)"/>--%>
<%--					</svg>--%>
<%--				</div>--%>
<%--				<div class="checkdown-text">--%>
<%--					<div class="label">장애인미탑승</div>--%>
<%--					<div class="value"><span id="eventCount2">0</span>건</div>--%>
<%--				</div>--%>
<%--			</li>--%>
<%--			<li>--%>
<%--				<div class="ico-checkdown illegalStickers">--%>
<%--					<svg viewBox="0 0 24 24" fill="currentColor">--%>
<%--						<path d="M21.9024 10.5976C21.4442 10.5333 20.976 10.5 20.5 10.5C17.2404 10.5 14.3455 12.0604 12.5212 14.471C12.3501 14.4887 12.1763 14.4978 12 14.4978C10.7188 14.4978 9.55217 14.0172 8.66691 13.2248L7.33309 14.7151C8.41871 15.6868 9.81141 16.3253 11.3466 16.4676C10.8023 17.7016 10.5 19.0662 10.5 20.5C10.5 20.976 10.5333 21.4442 10.5976 21.9024C5.7387 21.2205 2 17.0469 2 12C2 6.47715 6.47715 2 12 2C17.0469 2 21.2205 5.7387 21.9024 10.5976ZM21.8707 12.617C21.4254 12.5401 20.9674 12.5 20.5 12.5C17.7656 12.5 15.3512 13.8709 13.9068 15.9675C13.0194 17.2556 12.5 18.8156 12.5 20.5C12.5 20.9674 12.5401 21.4254 12.617 21.8707L21.8707 12.617ZM8.5 11.5C9.32843 11.5 10 10.8284 10 10C10 9.17157 9.32843 8.5 8.5 8.5C7.67157 8.5 7 9.17157 7 10C7 10.8284 7.67157 11.5 8.5 11.5ZM15.5 11.5C16.3284 11.5 17 10.8284 17 10C17 9.17157 16.3284 8.5 15.5 8.5C14.6716 8.5 14 9.17157 14 10C14 10.8284 14.6716 11.5 15.5 11.5Z"/>--%>
<%--					</svg>--%>
<%--				</div>--%>
<%--				<div class="checkdown-text">--%>
<%--					<div class="label">스티커 불법 사용</div>--%>
<%--					<div class="value"><span id="eventCount3">0</span>건</div>--%>
<%--				</div>--%>
<%--			</li>--%>
			<li>
				<div class="ico-checkdown warning">
					<svg viewBox="0 0 24 24" fill="currentColor">
						<path d="M4.00001 20V14C4.00001 9.58172 7.58173 6 12 6C16.4183 6 20 9.58172 20 14V20H21V22H3.00001V20H4.00001ZM6.00001 14H8.00001C8.00001 11.7909 9.79087 10 12 10V8C8.6863 8 6.00001 10.6863 6.00001 14ZM11 2H13V5H11V2ZM19.7782 4.80761L21.1924 6.22183L19.0711 8.34315L17.6569 6.92893L19.7782 4.80761ZM2.80762 6.22183L4.22183 4.80761L6.34315 6.92893L4.92894 8.34315L2.80762 6.22183Z"/>
					</svg>
				</div>
				<div class="checkdown-text">
					<div class="label">위험상황</div>
					<div class="value"><span id="eventCount4">0</span>건</div>
				</div>
			</li>
			<li>
				<div class="ico-checkdown carrying">
					<svg viewBox="0 0 24 24" fill="currentColor">
						<path d="M12 1L21.5 6.5V17.5L12 23L2.5 17.5V6.5L12 1ZM6.49896 9.97089L11 12.5768V17.6252H13V12.5768L17.501 9.9709L16.499 8.24005L12 10.8447L7.50104 8.24004L6.49896 9.97089Z"/>
					</svg>
				</div>
				<div class="checkdown-text">
					<div class="label">물건적재</div>
					<div class="value"><span id="eventCount5">0</span>건</div>
				</div>
			</li>
			<li>
				<div class="ico-checkdown doubleParking">
					<svg viewBox="0 0 24 24" viewBox="0 0 24 24" fill="currentColor">
						<path d="M19 21H5V22C5 22.5523 4.55228 23 4 23H3C2.44772 23 2 22.5523 2 22V13L4.4174 8.97099C4.77884 8.36858 5.42986 7.99998 6.13238 7.99998H17.8676C18.5701 7.99998 19.2212 8.36858 19.5826 8.97099L22 13V22C22 22.5523 21.5523 23 21 23H20C19.4477 23 19 22.5523 19 22V21ZM4.33238 13H19.6676L17.8676 9.99998H6.13238L4.33238 13ZM6.5 18C7.32843 18 8 17.3284 8 16.5C8 15.6716 7.32843 15 6.5 15C5.67157 15 5 15.6716 5 16.5C5 17.3284 5.67157 18 6.5 18ZM17.5 18C18.3284 18 19 17.3284 19 16.5C19 15.6716 18.3284 15 17.5 15C16.6716 15 16 15.6716 16 16.5C16 17.3284 16.6716 18 17.5 18ZM5.43934 3.43932L6.5 2.37866L7.56066 3.43932C7.83211 3.71077 8 4.08577 8 4.49998C8 5.32841 7.32843 5.99998 6.5 5.99998C5.67157 5.99998 5 5.32841 5 4.49998C5 4.08577 5.16789 3.71077 5.43934 3.43932ZM10.9393 3.43932L12 2.37866L13.0607 3.43932C13.3321 3.71077 13.5 4.08577 13.5 4.49998C13.5 5.32841 12.8284 5.99998 12 5.99998C11.1716 5.99998 10.5 5.32841 10.5 4.49998C10.5 4.08577 10.6679 3.71077 10.9393 3.43932ZM16.4393 3.43932L17.5 2.37866L18.5607 3.43932C18.8321 3.71077 19 4.08577 19 4.49998C19 5.32841 18.3284 5.99998 17.5 5.99998C16.6716 5.99998 16 5.32841 16 4.49998C16 4.08577 16.1679 3.71077 16.4393 3.43932Z"/>
					</svg>
				</div>
				<div class="checkdown-text">
					<div class="label">이중주차</div>
					<div class="value"><span id="eventCount6">0</span>건</div>
				</div>
			</li>
		</ul>

		<%-- patches 2026-07-09: 최상단 제목 제거(피드백). 마커 상태 범례는 우측 카드로 이동 --%>
		<div id="mapWarning" class="map-warning" style="display:none;">
		카카오 지도 키(kakao.map.js-key)가 설정되지 않았거나 지도를 불러올 수 없습니다.
		<br>globals.properties 의 <b>kakao.map.js-key</b>(환경변수 KAKAO_MAP_JS_KEY)를 확인하세요.
	</div>

		<%-- patches 14: 지도 전체 + 지도 안 오버레이 6개(하단 grid 제거). 초기 진입 시 전부 열림(효성 결정) --%>
		<div id="map-container">
			<div id="map"></div>

			<%-- ① 좌측 통합 컨테이너 (15번 4-1): 검색·리스트 상시 + 하위 2컬럼(계도·단속 / 디바이스 상태) --%>
			<div class="overlay-widget" id="leftUnifiedOverlay">
				<div class="widget-header" id="widget-header">
					<span class="widget-title">단속 장비 현황 <span class="widget-count" id="deviceListCount">0</span></span>
					<button class="toggle-btn" type="button"></button>
				</div>
				<div class="widget-body">
					<input type="text" id="deviceSearchInput" class="device-search-input" placeholder="이름·주소로 검색" />
					<div id="deviceListItems">
						<div class="dev-empty">불러오는 중...</div>
					</div>

					<%-- 하위 컬럼 그룹 — 우측 스택에서 이관(우측은 마커 범례·날씨 2개로 축소) --%>
					<div class="sub-columns-group">
						<%-- 하위 컬럼 1: 오늘 계도·단속 (클릭 시 오늘 날짜 + evAction 필터로 이동) --%>
						<div class="sub-column split-item-column">
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

						<%-- 하위 컬럼 2: 디바이스 상태(정상·이상 건수) --%>
						<div class="sub-column device-status-column">
							<div class="status-row">
								<span class="status-label">정상</span>
								<span class="status-value normal" id="deviceNormalCount">0</span>
							</div>
							<div class="status-row">
								<span class="status-label">이상</span>
								<span class="status-value error" id="deviceErrorCount">0</span>
							</div>
						</div>
					</div>
				</div>
			</div>

			<%-- ②③ 우측 세로 스택 그룹 — 토글 버튼 1개로 동시 축소/확대(위치 유지).
				 (15번 4-1) 3개 → 2개로 축소: 계도·단속과 디바이스 상태는 좌측 통합 컨테이너로 이관 --%>
			<div class="right-stack-group" id="rightStackGroup">
				<button id="rightStackToggle" class="group-toggle-btn" type="button">&#9660;</button>

				<%-- ② 마커 상태 --%>
				<div class="overlay-widget marker-legend-widget">
					<div class="widget-header" id="widget-header"><span class="widget-title">마커 상태</span></div>
					<div class="widget-body">
						<div class="legend-row"><span class="marker-icon" style="background:#28a745"></span><span>정상</span></div>
						<div class="legend-row"><span class="marker-icon" style="background:#ffc107"></span><span>이상 1~2</span></div>
						<div class="legend-row"><span class="marker-icon" style="background:#dc3545"></span><span>이상 3+</span></div>
						<div class="legend-row"><span class="marker-icon" style="background:#808080"></span><span>30분+ 미갱신</span></div>
					</div>
				</div>

				<%-- ③ 날씨 (계도·단속은 좌측 통합 컨테이너로 이관) --%>
				<div class="overlay-widget weather-summary-widget">
					<div class="widget-header"><span class="widget-title">날씨</span></div>
					<div class="widget-body">
						<div class="weather-row">
							<i class="fas fa-cloud-sun"></i>
							<span id="weather-value">-</span>
							<span class="weather-sub" id="weather-sub"></span>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<div class="list-area">
		<%-- ⑤ 좌하: 최근 이벤트(3건) --%>
		<div class="overlay-widget event-list-widget" id="eventListOverlay">
			<div class="widget-header">
				<span class="widget-title">최근 이벤트</span>
				<span class="header-actions">
					<a href="${pageContext.request.contextPath}/eventList/viewEventList.do" class="view-all-btn">전체 보기</a>
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
	$(document).on('click', '.overlay-widget #widget-header', function(e) {
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

// ev_cd별 이벤트 총합
function loadEventCounts() {
	$.ajax({
		url: CONTEXT_PATH + "/eventList/eventCounts",
		method: "GET",
		dataType: "json",

		success: function(data) {
			console.log("이벤트 건수 조회:", data);

			for (var i = 1; i <= 6; i++) {
				$('#eventCount' + i).text(data[i] || 0);
			}
		},

		error: function(xhr, status, error) {
			console.error("이벤트 건수 조회 실패:", status, error);
			console.error("응답:", xhr.responseText);

			for (var i = 1; i <= 6; i++) {
				$('#eventCount' + i).text(0);
			}
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
	loadEventCounts(); //ev_cd 건별 총합 추가

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
