<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<div class="topTitle">
    <h3 class="detail-title">불법주차 리스트 상세</h3>
    <div class="title-text">
        <div class="event-navigation"><button type="button" id="btnPrevEvent" title="이전 항목">이전</button><button type="button" id="btnNextEvent" title="다음 항목">다음</button></div>
        <button type="button" id="btnDeleteEvent" class="case-delete" title="삭제">삭제</button>
        <button id="btnExcel" type="button" title="엑셀 다운로드">엑셀 다운로드</button>
        <button type="button" onclick="goToEventList()" class="back-btn">목록으로 돌아가기</button>
    </div>
</div>
<section class="vehicle-overview" aria-label="차량 정보">
    <div class="vehicle-identity"><span class="vehicle-label">차량 번호</span><strong><c:out value="${eventListDetail.ev_car_num}" /></strong></div>
    <c:if test="${vehicleContext.identified}">
        <dl><dt>전체 발생</dt><dd><c:out value="${vehicleContext.summary.total_count}" /><small>건</small></dd></dl>
        <dl><dt>발생 장비</dt><dd><c:out value="${vehicleContext.summary.location_count}" /><small>곳</small></dd></dl>
        <dl class="vehicle-last-seen"><dt>최근 발생</dt><dd><c:out value="${vehicleContext.summary.last_seen_display}" /></dd></dl>
    </c:if>
    <dl><dt>처리 상태</dt><dd class="vehicle-action"><c:choose><c:when test="${eventListDetail.ev_action == 0}">계도</c:when><c:when test="${eventListDetail.ev_action == 1}">단속</c:when><c:when test="${eventListDetail.ev_action == 2}">과태료</c:when></c:choose></dd></dl>
</section>
<div class="inspection-layout">
    <section class="visual-workbench" aria-label="차량 보기">
        <div class="workbench-heading">
            <h4>차량 보기</h4>
            <div class="view-switch" role="group" aria-label="차량 보기 전환">
                <button type="button" data-vehicle-view="photos" aria-pressed="true">촬영 사진</button>
                <button type="button" data-vehicle-view="model" aria-pressed="false">차량 모형</button>
                <button type="button" data-vehicle-view="space" aria-pressed="false" disabled>주차 공간</button>
            </div>
        </div>
        <div id="vehiclePhotoPanel">
            <div class="evidence-toolbar" role="group" aria-label="사진 비교">
                <button type="button" data-evidence-mode="side" aria-pressed="true">나란히 보기</button>
                <button type="button" data-evidence-mode="overlay" aria-pressed="false" disabled>겹쳐 보기</button>
                <input id="evidenceCompare" type="range" min="0" max="100" value="50" aria-label="1분 후 사진 비교 비율" hidden>
            </div>
            <div class="image-wrapper" id="vehicleEvidence">
                <c:forEach var="slot" begin="0" end="1">
                    <c:set var="imagePath" value="${slot == 0 ? eventListDetail.ev_img_path : eventListDetail.ev_img_path2}" />
                    <div class="image-container"><div class="img-box">
                        <div class="imgeTitle">${slot == 0 ? '진입 시' : '1분 후'}</div>
                        <button type="button" class="evidence-expand" data-expand-evidence="${slot}" aria-label="${slot == 0 ? '진입 시' : '1분 후'} 사진 확대" disabled>확대</button>
                        <c:choose><c:when test="${not empty imagePath}">
                            <img src="${pageContext.request.contextPath}/imgFile/<c:out value='${fn:replace(imagePath, ".enc", "")}' />" alt="불법주차 리스트 상세 이미지" class="detail-image" onerror="this.onerror=null;this.src='${pageContext.request.contextPath}/resources/images/default-image.svg';">
                        </c:when><c:otherwise>
                            <img src="${pageContext.request.contextPath}/resources/images/default-image.svg" alt="불법주차 리스트 상세 이미지" class="detail-image">
                        </c:otherwise></c:choose>
                    </div></div>
                </c:forEach>
            </div>
        </div>
        <div id="vehicleScenePanel" class="vehicle-scene" hidden data-event-id="${eventListDetail.ev_id}" data-context-path="${pageContext.request.contextPath}">
            <div class="scene-heading"><span id="sceneModeLabel">차량 모형</span><span id="sceneManualLabel" hidden>수동 배치</span><button type="button" id="editSpatialContext" disabled>구역·배치 편집</button></div>
            <canvas id="vehicleSceneCanvas" tabindex="0" aria-label="차량 3D 보기. 방향키로 회전하고 더하기와 빼기 키로 확대 및 축소" role="img"></canvas>
            <div class="scene-controls" role="group" aria-label="3D 시점">
                <button type="button" data-scene-preset="perspective">원근</button><button type="button" data-scene-preset="front">정면</button><button type="button" data-scene-preset="side">측면</button><button type="button" data-scene-preset="top">위에서</button>
                <button type="button" data-scene-zoom="in" aria-label="3D 확대">＋</button><button type="button" data-scene-zoom="out" aria-label="3D 축소">−</button>
            </div>
        </div>
    </section>
    <section class="detail-table-wrapper" aria-labelledby="caseInfoTitle">
        <div class="case-heading"><h4 id="caseInfoTitle">단속 정보</h4><span class="case-event-id">#<c:out value="${eventListDetail.ev_id}" /></span></div>
        <ul class="detail-table">
            <li><div class="value-area"><label>유형</label><div class="value event-type-value"><c:choose>
                <c:when test="${eventListDetail.ev_cd == 0}">정상</c:when><c:when test="${eventListDetail.ev_cd == 1}">미등록차량</c:when><c:when test="${eventListDetail.ev_cd == 4}">위험상황</c:when><c:when test="${eventListDetail.ev_cd == 5}">물건적재</c:when><c:when test="${eventListDetail.ev_cd == 6}">이중주차</c:when><c:otherwise>기타</c:otherwise>
                </c:choose><c:if test="${not empty eventListDetail.ev_mov_path}"><button type="button" class="video-icon-btn" data-video="${pageContext.request.contextPath}/videoFile/<c:out value='${fn:replace(eventListDetail.ev_mov_path, ".enc", "")}' />" aria-controls="photoModal" aria-expanded="false"><img alt="상세영상 보기" src="${pageContext.request.contextPath}/resources/images/영상 버튼.png" width="25" height="25"></button></c:if></div></div></li>
            <li><div class="value-area"><label>날짜</label><div class="value"><c:out value="${eventListDetail.ev_date_display}" /></div></div></li>
            <li><div class="value-area"><label>디바이스명</label><div class="value"><c:out value="${eventListDetail.ev_dv_name}" /></div></div></li>
            <li><div class="value-area"><label>디바이스 주소</label><div class="value"><c:out value="${eventListDetail.ev_dv_addr}" /></div></div></li>
            <li><div class="value-area"><label>차량 번호</label><div class="value"><c:out value="${eventListDetail.ev_car_num}" /></div></div></li>
            <li><div class="value-area"><label>비고</label><div class="value">-</div></div></li>
        </ul>
    </section>
</div>
<jsp:include page="vehicleContext.jsp" />
<dialog id="evidenceViewer" class="evidence-viewer" aria-labelledby="evidenceViewerTitle">
    <div class="evidence-viewer-toolbar"><strong id="evidenceViewerTitle"></strong><input id="evidenceZoom" type="range" min="100" max="300" step="25" value="100" aria-label="사진 확대 비율"><output for="evidenceZoom" id="evidenceZoomValue">100%</output><button type="button" id="closeEvidenceViewer" aria-label="사진 닫기">닫기</button></div>
    <div class="evidence-viewer-scroll"><img id="evidenceViewerImage" alt=""></div>
</dialog>
<dialog id="spatialEditor" class="spatial-editor" aria-labelledby="spatialEditorTitle">
    <form id="spatialForm">
        <div class="spatial-editor-heading"><h3 id="spatialEditorTitle">주차 공간 편집</h3><button type="button" id="closeSpatialEditor" aria-label="주차 공간 편집 닫기">닫기</button></div>
        <div class="spatial-editor-layout">
            <div class="spatial-plan-panel">
                <div class="plan-toolbar" role="group" aria-label="공간 편집 도구"><button type="button" data-plan-mode="boundary" aria-pressed="true">경계 그리기</button><button type="button" data-plan-mode="pose" aria-pressed="false">차량 배치</button><button type="button" id="undoBoundary">되돌리기</button><button type="button" id="clearBoundary">경계 지우기</button></div>
                <canvas id="spatialPlanCanvas" aria-label="주차구역 좌표 평면" role="img"></canvas>
                <label class="plan-scale">표시 범위 <select id="spatialPlanRange"><option value="20">20m</option><option value="50">50m</option><option value="100">100m</option><option value="500">500m</option></select></label>
            </div>
            <div class="spatial-fields">
                <fieldset><legend>장비 주차구역</legend><label for="spatialBoundary">경계 좌표 (경도, 위도)</label><textarea id="spatialBoundary" rows="6" spellcheck="false"></textarea></fieldset>
                <fieldset><legend>이 차량의 수동 배치</legend><label for="spatialVehicleLat">위도</label><input id="spatialVehicleLat" type="number" step="any" min="-90" max="90"><label for="spatialVehicleLng">경도</label><input id="spatialVehicleLng" type="number" step="any" min="-180" max="180"><label for="spatialVehicleHeading">방향 (°)</label><input id="spatialVehicleHeading" type="number" step="0.01" min="0" max="359.99"><button type="button" id="clearVehiclePose">차량 배치 지우기</button></fieldset>
            </div>
        </div>
        <div class="spatial-editor-footer"><output id="spatialError" role="alert" hidden></output><button type="submit" id="saveSpatialContext">저장</button></div>
    </form>
</dialog>
<script src="${pageContext.request.contextPath}/resources/js/eventList/vehicleContext.js" defer></script>
<script src="${pageContext.request.contextPath}/resources/js/eventList/vehicleScene3d.js" defer></script>
