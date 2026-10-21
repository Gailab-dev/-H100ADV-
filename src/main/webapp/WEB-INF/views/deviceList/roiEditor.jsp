<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- [Tiles fragment] 웹 ROI 설정 편집 화면 (34번 작업계획서). 공용 chrome(헤더/사이드바/푸터)은 defaultLayout 제공.
     NAV 에 노출하지 않고 장비 관리 화면의 ROI 버튼(장비관리자 25·최고관리자 30 에게만 표시)으로만 진입한다.
     값은 모두 data-* 속성으로 넘기고(c:out 으로 이스케이프) 스크립트에 직접 문자열을 끼워 넣지 않는다. --%>
<meta charset="UTF-8">
<title>ROI 설정</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/roiEditor.css?v=20261020">

<div id="roiPage" class="roi-page"
	data-ctx="<c:out value='${pageContext.request.contextPath}' escapeXml='true'/>"
	data-device-id="<c:out value='${deviceId}' escapeXml='true'/>"
	data-device-name="<c:out value='${deviceName}' escapeXml='true'/>"
	data-serial="<c:out value='${serial}' escapeXml='true'/>"
	data-csrf="<c:out value='${roiCsrf}' escapeXml='true'/>"
	data-uid="<c:out value='${loginUid}' escapeXml='true'/>">

	<div class="roi-topbar">
		<a class="roi-back" href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">&larr; 장비 목록</a>
		<h2>ROI 설정
			<span class="roi-device"><c:out value="${deviceName}" escapeXml="true" /> (<c:out value="${serial}" escapeXml="true" />)</span>
		</h2>
		<div class="roi-top-actions">
			<span id="roiDraftState" class="roi-draft-state" aria-live="polite"></span>
			<button type="button" id="btnHistory" class="roi-btn">이력</button>
		</div>
	</div>

	<div id="roiBanner" class="roi-banner" hidden role="status"></div>

	<div class="roi-toolbar">
		<div class="roi-tabs" role="tablist" aria-label="카메라 선택">
			<button type="button" role="tab" data-cam="Cam1" class="active">Cam1 (불릿)</button>
			<button type="button" role="tab" data-cam="Cam2">Cam2 (PTZ)</button>
		</div>
		<div class="roi-newshape" aria-label="새 도형 그리기">
			<span class="roi-label">새 도형</span>
			<button type="button" class="roi-btn kind-parking" data-kind="parking">+ 주차칸</button>
			<button type="button" class="roi-btn kind-driveway" data-kind="driveway">+ 통로</button>
			<button type="button" class="roi-btn kind-ignore" data-kind="ignore">+ 식별 제외 영역</button>
		</div>
		<div class="roi-edit-actions">
			<button type="button" id="btnUndo" class="roi-btn" title="되돌리기 (Ctrl+Z)">되돌리기</button>
			<button type="button" id="btnRedo" class="roi-btn" title="다시 실행 (Ctrl+Y)">다시 실행</button>
			<button type="button" id="btnClearCam" class="roi-btn">현재 카메라 전체 삭제</button>
			<button type="button" id="btnResnap" class="roi-btn">스냅샷 다시 받기</button>
		</div>
	</div>

	<div class="roi-main">
		<div class="roi-stage-wrap">
			<div id="roiStage" class="roi-stage"></div>
			<p class="roi-guide">도형을 클릭해 선택 &middot; 점을 끌어 이동 &middot; 선(변)을 클릭하면 점 추가 &middot; 점을 더블클릭(또는 오른쪽 클릭)하면 삭제 &middot; 좌표는 1920&times;1080 기준입니다.</p>
		</div>
		<aside class="roi-side">
			<div id="roiList"></div>
			<div id="roiProblems"></div>
		</aside>
	</div>

	<div class="roi-footer">
		<span id="roiHint" class="roi-hint" aria-live="polite"></span>
		<button type="button" id="btnReload" class="roi-btn">장비 값 다시 불러오기</button>
		<button type="button" id="btnSave" class="roi-btn primary">저장 (장비에 적용)</button>
	</div>

	<div id="roiToast" class="roi-toast" role="status" aria-live="polite"></div>

	<%-- 확인/안내 모달 --%>
	<div id="roiModal" class="roi-overlay" hidden role="dialog" aria-modal="true" aria-labelledby="roiModalTitle">
		<div class="roi-dialog">
			<h3 id="roiModalTitle"></h3>
			<div id="roiModalBody" class="roi-dialog-body"></div>
			<div id="roiModalFoot" class="roi-dialog-foot"></div>
		</div>
	</div>

	<%-- 대기 팝업(최대 15초) --%>
	<div id="roiWait" class="roi-overlay wait" hidden role="alertdialog" aria-modal="true" aria-live="assertive">
		<div class="roi-dialog small">
			<div class="roi-spinner" aria-hidden="true"></div>
			<p id="roiWaitText"></p>
			<p class="roi-wait-left">제한 시간 <span id="roiWaitLeft">15초</span></p>
		</div>
	</div>

	<%-- 이력 모달 --%>
	<div id="roiHistoryModal" class="roi-overlay" hidden role="dialog" aria-modal="true" aria-label="ROI 적용 이력">
		<div class="roi-dialog wide">
			<div class="roi-dialog-head">
				<h3>ROI 적용 이력</h3>
				<button type="button" id="roiHistoryClose" class="roi-btn small">닫기</button>
			</div>
			<div class="roi-history-body">
				<div id="roiHistoryList" class="roi-history-list"></div>
				<div id="roiHistoryDetail" class="roi-history-detail"></div>
			</div>
		</div>
	</div>
</div>

<%-- Konva 는 폐쇄망 대비로 프로젝트에 포함(MIT, resources/js/vendor/konva/LICENSE·VERSION.txt 참조) --%>
<script src="${pageContext.request.contextPath}/resources/js/vendor/konva/konva.min.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/roi/roiGeometry.js?v=20261020"></script>
<script src="${pageContext.request.contextPath}/resources/js/roi/roiEditorCore.js?v=20261020"></script>
<script src="${pageContext.request.contextPath}/resources/js/roi/roiEditor.js?v=20261020"></script>
