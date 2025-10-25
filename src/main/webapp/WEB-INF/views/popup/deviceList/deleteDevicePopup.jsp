<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!-- 모달 오버레이 -->
<div class="modal-overlay" onclick="removeDeletePopup()"></div>

<!-- 모달 본체 -->
<div class="modal">
	<p class="modal-text">정말 디바이스를 삭제하시겠습니까?</p>
	<div class="modal-buttons">
		<button class="modal-btn cancel" onClick="removeDeletePopup()">취소</button>
		<button class="modal-btn delete" onClick="deleteSelectedRows()">삭제</button>
	</div>
</div>