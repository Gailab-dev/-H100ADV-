<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%-- 공용 헤더 (Tiles defaultLayout). deviceList 하드코딩 헤더를 공유 레이아웃으로 이관
     (요청 2026-07-16) 내 정보 진입점을 left 사이드바 → 헤더(사용자명 왼쪽 사람아이콘)로 이동, 클릭 시 모달로 표시 --%>
<style>
	/* 헤더 내 정보 아이콘 버튼 — left 메뉴와 동일 아이콘/색상(currentColor, 기본 #000) */
	.header-icon-btn {
		background: none; border: none; cursor: pointer; color: #000;
		padding: 6px; border-radius: 6px; line-height: 0;
		display: flex; align-items: center; transition: background .2s ease, color .2s ease;
	}
	.header-icon-btn:hover { background: #f1edff; color: #6955A2; }

	/* 내 정보 모달 — 내용(iframe)을 충분히 감쌀 정도의 크기만 */
	.gi-modal { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 1000; display: flex; align-items: center; justify-content: center; }
	.gi-modal-backdrop { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.35); }
	.gi-modal-dialog {
		position: relative; background: #fff; border-radius: 10px;
		box-shadow: 0 10px 30px rgba(0,0,0,0.25);
		width: 560px; max-width: 92vw; height: 640px; max-height: 88vh; overflow: hidden;
	}
	.gi-modal-close {
		position: absolute; top: 6px; right: 10px; z-index: 2;
		background: none; border: none; font-size: 24px; line-height: 1; color: #999; cursor: pointer; padding: 2px 6px;
	}
	.gi-modal-close:hover { color: #333; }
	.gi-modal-frame { width: 100%; height: 100%; border: 0; display: block; }
</style>

<header class="header">
	<div class="logo">
		<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
	</div>
	<div class="right-group">
		<c:if test="${useTblLog eq false}">
			<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.</div>
		</c:if>
		<%-- 내 정보 버튼(사용자명 왼쪽). 아이콘은 기존 left 사이드바의 '내 정보' 아이콘 그대로 --%>
		<button type="button" id="btnMyInfo" class="header-icon-btn" title="내 정보" aria-label="내 정보">
			<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M9.99998 3.33325C10.884 3.33325 11.7319 3.68444 12.357 4.30956C12.9821 4.93468 13.3333 5.78253 13.3333 6.66659C13.3333 7.55064 12.9821 8.39849 12.357 9.02361C11.7319 9.64873 10.884 9.99992 9.99998 9.99992C9.11592 9.99992 8.26808 9.64873 7.64296 9.02361C7.01784 8.39849 6.66665 7.55064 6.66665 6.66659C6.66665 5.78253 7.01784 4.93468 7.64296 4.30956C8.26808 3.68444 9.11592 3.33325 9.99998 3.33325ZM9.99998 10.8333C12.225 10.8333 16.6666 11.9416 16.6666 14.1666V16.6666H3.33331V14.1666C3.33331 11.9416 7.77498 10.8333 9.99998 10.8333Z" fill="currentColor"/>
			</svg>
		</button>
		<div class="user">
			<span class="user-name"><c:out value="${uName}" escapeXml="true" /></span>
		</div>
		<div class="logout">
			<button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
		</div>
	</div>
</header>

<%-- 내 정보 모달: iframe 으로 /myInfo/modal(공용 chrome 없는 문서) 로드 → 호출 화면과 CSS/JS 완전 분리 --%>
<div id="myInfoModal" class="gi-modal" style="display:none;" role="dialog" aria-modal="true" aria-label="내 정보">
	<div class="gi-modal-backdrop" data-myinfo-close></div>
	<div class="gi-modal-dialog">
		<button type="button" class="gi-modal-close" data-myinfo-close aria-label="닫기">&times;</button>
		<iframe id="myInfoFrame" class="gi-modal-frame" src="" title="내 정보"></iframe>
	</div>
</div>

<script>
(function() {
	var MYINFO_URL = "${pageContext.request.contextPath}/myInfo/modal";

	function openMyInfoModal() {
		$('#myInfoFrame').attr('src', MYINFO_URL);   // 열 때마다 최신 정보 로드
		$('#myInfoModal').css('display', 'flex');
		$('body').css('overflow', 'hidden');
	}
	function closeMyInfoModal() {
		$('#myInfoModal').hide();
		$('#myInfoFrame').attr('src', '');           // 입력값 정리(다음 오픈 시 새로 로드)
		$('body').css('overflow', '');
	}
	// iframe 내부(저장 완료 등)에서 parent.closeMyInfoModal() 로 닫을 수 있도록 전역 노출
	window.closeMyInfoModal = closeMyInfoModal;

	$(function() {
		$('#btnMyInfo').on('click', openMyInfoModal);
		$(document).on('click', '[data-myinfo-close]', closeMyInfoModal);
		$(document).on('keydown', function(e) {
			if (e.key === 'Escape' && $('#myInfoModal').is(':visible')) closeMyInfoModal();
		});
	});
})();
</script>
