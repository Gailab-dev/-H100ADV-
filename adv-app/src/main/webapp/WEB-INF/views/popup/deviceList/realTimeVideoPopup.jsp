<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

	<script>

	</script>
	

<!-- 배경 오버레이 -->
<div class="video-modal-overlay" onclick="closeRealTimeVideoPopup()"></div>

<!-- 영상 모달 본체 -->
<div class="video-modal">
  <!-- 상단 헤더 -->
  <div class="video-modal-header">
    <span class="video-modal-title">실시간 영상</span>
    <button class="video-modal-close" onclick="closeRealTimeVideoPopup()">✕</button>
  </div>

  <!-- 비디오 영역 -->
  <div class="video-container">
    <video id="video" controls autoplay playsinline>
      <source src="" type="application/x-mpegURL">
      이 브라우저에서는 실시간 영상을 재생할 수 없습니다.  
	  Chrome, Edge, 또는 Safari를 사용해주세요.
    </video>
  </div>
</div>