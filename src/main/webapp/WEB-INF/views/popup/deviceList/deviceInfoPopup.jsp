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
		<label>디바이스명 <span class="required">*</span></label>
		<input type="text" id="dvName" placeholder="디바이스명" value="${dvInfo.dv_name}" >

		<label>디바이스 주소 <span class="required">*</span></label>
		<input type="text" id="dvAddr" placeholder="디바이스 주소" value="${dvInfo.dv_addr}" >

		<label>도메인 <span class="required">*</span></label>
		<input type="text" id="dvIp" placeholder="도메인" value="${dvInfo.dv_ip}" >
		
		<label>serial number <span class="required">*</span></label>
		<input type="text" id="serialNumber" placeholder="serial number" value="${dvInfo.dv_serial_number}">
	
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

</div>
