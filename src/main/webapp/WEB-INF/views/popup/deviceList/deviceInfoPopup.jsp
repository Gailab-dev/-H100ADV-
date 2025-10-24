<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<script>
	// 팝업창 닫기
	function closeDeviceInfoPopup(){
		 let deviceInfoPopup = document.getElementById("deviceInfoPopup");
		 deviceInfoPopup.style.display = none;
		 location.reload; 
	}
	
	function 

</script>

<div>
	<c:if test="${empty dvId}">
		<P> 디바이스 등록</P>
	</c:if>
	<c:if test="${not empty dvId}">
		<P> 디바이스 수정</P>
	</c:if>
	
	<div>
		<div>
			<p>디바이스명</p>
			<input type="text" id="dvName" placeholder="디바이스명" value="${dvName}">
		</div>
		<div>
			<p>디바이스 주소</p>
			<input type="text" id="dvAddr" placeholder="디바이스명" value="${dvAddr}">
		</div>
		<div>
			<p>디바이스 IP</p>
			<input type="text" id="dvIp" placeholder="디바이스명" value="${dvIp}">
		</div>
		
		<button onclick="closeDeviceInfoPopup()">취소</button>
		<c:if test="${empty dvId}">
			<button>등록</button>
		</c:if>
		<c:if test="${not empty dvId}">
			<button>수정</button>
		</c:if>
	
	</div>


</div>
