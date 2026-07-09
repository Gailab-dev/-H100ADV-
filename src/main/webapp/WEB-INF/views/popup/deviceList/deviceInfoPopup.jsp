<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="modal-overlay" onclick="closeDeviceInfoPopup()"></div>

<div class="modal">
	<c:choose>
		<c:when test="${empty dvId}">
			<p class="modal-title">디바이스 등록</p>
		</c:when>
		<c:otherwise>
			<p class="modal-title">디바이스 수정</p>
		</c:otherwise>
	</c:choose>
	
	<div class="modal-content">
		<div class="modal-labelGroup">
			<label>디바이스명 <span class="required">*</span></label>
			<input type="text" id="dvName" placeholder="디바이스명" value="${dvInfo.dv_name}" >
		</div>
		
		<div class="modal-labelGroup">
		<label>디바이스 주소 <span class="required">*</span></label>
		<div style="display:flex; gap:8px; align-items:center;">
			<input type="text" id="dvAddr" placeholder="주소 검색을 눌러 입력" value="${dvInfo.dv_addr}" readonly style="flex:1;">
			<button type="button" onclick="searchDeviceAddress()"
				style="white-space:nowrap; padding:0 14px; height:44px; border:1px solid #6955A2; background:#6955A2; color:#fff; border-radius:8px; cursor:pointer;">주소 검색</button>
		</div>
		</div>

		<div class="modal-labelGroup">
		<label>상세 주소</label>
		<input type="text" id="dvAddrDetail" placeholder="상세 주소 (건물명·동/호수 등)" value="${dvInfo.dv_addr_detail}" maxlength="200">
		</div>

		<%-- patches 2026-07-07: 주소 검색 시 지오코딩으로 자동 채움(대시보드 지도 마커용). 빈 값이면 0(지도 미표시) --%>
		<input type="hidden" id="dvLat" value="${empty dvInfo.dv_lat ? '0' : dvInfo.dv_lat}">
		<input type="hidden" id="dvLng" value="${empty dvInfo.dv_lng ? '0' : dvInfo.dv_lng}">

		<div class="modal-labelGroup">
		<label>serial number <span class="required">*</span></label>
		<input type="text" id="serialNumber" placeholder="serial number" value="${dvInfo.dv_serial_number}">
		</div>
		
		<div class="modal-labelGroup">
		<label>IP <span class="required">*</span></label>
		<input type="text" id="dvIp" placeholder="IP" value="${dvInfo.dv_ip}" >
		</div>
	</div>
	<div class="modal-buttons">
			<button class="modal-btn cancel" onclick="closeDeviceInfoPopup()">취소</button>
	
			<c:if test="${empty dvId}">
				<button class="modal-btn save" onclick="insertDeviceInfo()">등록</button>
			</c:if>
	
			<c:if test="${not empty dvId}">
				<button class="modal-btn save" onclick="updateDeviceInfo('${dvId}')">수정</button>
			</c:if>
		</div>

</div>
