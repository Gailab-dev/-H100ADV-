<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%-- 공용 사이드바 (Tiles defaultLayout). deviceList 하드코딩 사이드바 이관 + 대시보드·SIP CALL 신규 링크 추가.
     활성 메뉴는 요청 URI 로 판정(기존 CSS nth-child(3) 고정 대체) --%>
<c:set var="cp" value="${pageContext.request.contextPath}" />
<%-- patches 2026-07-09(6): active 미적용 진짜 원인 규명 — Spring 뷰 렌더 시 내부 forward 로 인해
     pageContext.request.requestURI 가 원래 URL 이 아니라 forward 대상(내부 JSP 경로)을 가리켜 '/dashboard' 매칭 실패.
     진짜 요청 URL 은 forward/include 속성에 남으므로 세 소스를 모두 합쳐 어디에 담기든 매칭되게 함. --%>
<c:set var="reqUri" value="${pageContext.request.requestURI}" />
<c:set var="fwdUri" value="${requestScope['javax.servlet.forward.request_uri']}" />
<c:set var="incUri" value="${requestScope['javax.servlet.include.request_uri']}" />
<c:set var="uri" value="${reqUri}|${fwdUri}|${incUri}" />
<%-- [debug] 문제 지속 시 페이지 소스에서 확인: req=[${reqUri}] fwd=[${fwdUri}] inc=[${incUri}] --%>
<%-- patches 2026-07-09(4→5): 현재 화면 메뉴를 'hover 했을 때와 똑같은 색'으로 항상 유지(요구 명확화).
     별도 강조색이 아니라 hover 배경(#f1edff)과 동일하게만 적용 → 마우스 위치와 무관하게 그 색 유지.
     CSS 파일 경유로는 계속 무력화되던 이력이 있어 각 링크에 인라인 !important 로 직접 부여(최상위 우선순위).
     linkPad(좌우 20px)는 사이드바 좌우 패딩 0 이후에도 텍스트 위치 유지 → 배경이 폭을 꽉 채움. --%>
<c:set var="linkPad" value="padding-left:20px;padding-right:20px;" />
<c:set var="actSty" />
<c:set var="onDashboard" value="${fn:contains(uri, '/dashboard')}" />
<c:set var="onEventList" value="${fn:contains(uri, '/eventList')}" />
<c:set var="onStats"     value="${fn:contains(uri, '/stats')}" />
<c:set var="onDevice"    value="${fn:contains(uri, '/deviceList')}" />
<c:set var="onSip"       value="${fn:contains(uri, '/sipcall')}" />
<c:set var="onMyInfo"    value="${fn:contains(uri, '/myInfo')}" />
<aside class="sidebar" style="padding-left:0 !important;padding-right:0 !important;">
	<ul class="menu">
		<%-- 대시보드 (신설) --%>
		<li><a class="${onDashboard ? 'active' : ''}" style="${linkPad}${onDashboard ? actSty : ''}" href="${cp}/dashboard">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M3 10.5L10 4l7 6.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
				<path d="M5 9.5V16h10V9.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>대시보드
		</a></li>

		<%-- 불법주차 리스트 --%>
		<li><a class="${onEventList ? 'active' : ''}" style="${linkPad}${onEventList ? actSty : ''}" href="${cp}/eventList/viewEventList.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path fill-rule="evenodd" clip-rule="evenodd" d="M2.70837 5.83203C2.70837 5.66627 2.77422 5.5073 2.89143 5.39009C3.00864 5.27288 3.16761 5.20703 3.33337 5.20703H16.6667C16.8325 5.20703 16.9914 5.27288 17.1086 5.39009C17.2259 5.5073 17.2917 5.66627 17.2917 5.83203C17.2917 5.99779 17.2259 6.15676 17.1086 6.27397C16.9914 6.39118 16.8325 6.45703 16.6667 6.45703H3.33337C3.16761 6.45703 3.00864 6.39118 2.89143 6.27397C2.77422 6.15676 2.70837 5.99779 2.70837 5.83203ZM2.70837 9.9987C2.70837 9.83294 2.77422 9.67397 2.89143 9.55676C3.00864 9.43955 3.16761 9.3737 3.33337 9.3737H12.5C12.6658 9.3737 12.8248 9.43955 12.942 9.55676C13.0592 9.67397 13.125 9.83294 13.125 9.9987C13.125 10.1645 13.0592 10.3234 12.942 10.4406C12.8248 10.5578 12.6658 10.6237 12.5 10.6237H3.33337C3.16761 10.6237 3.00864 10.5578 2.89143 10.4406C2.77422 10.3234 2.70837 10.1645 2.70837 9.9987ZM2.70837 14.1654C2.70837 13.9996 2.77422 13.8406 2.89143 13.7234C3.00864 13.6062 3.16761 13.5404 3.33337 13.5404H7.50004C7.6658 13.5404 7.82477 13.6062 7.94198 13.7234C8.05919 13.8406 8.12504 13.9996 8.12504 14.1654C8.12504 14.3311 8.05919 14.4901 7.94198 14.6073C7.82477 14.7245 7.6658 14.7904 7.50004 14.7904H3.33337C3.16761 14.7904 3.00864 14.7245 2.89143 14.6073C2.77422 14.4901 2.70837 14.3311 2.70837 14.1654Z" fill="currentColor"/>
			</svg>불법주차 리스트
		</a></li>

		<%-- 통계 --%>
		<li><a class="${onStats ? 'active' : ''}" style="${linkPad}${onStats ? actSty : ''}" href="${cp}/stats/viewStat.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<g clip-path="url(#clip0_300_3167)">
					<path d="M18.3333 18.3359H1.66663" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
					<path d="M17.5 18.3346V12.0846C17.5 11.7531 17.3683 11.4352 17.1339 11.2008C16.8995 10.9663 16.5815 10.8346 16.25 10.8346H13.75C13.4185 10.8346 13.1005 10.9663 12.8661 11.2008C12.6317 11.4352 12.5 11.7531 12.5 12.0846V18.3346V4.16797C12.5 2.98964 12.5 2.40047 12.1333 2.03464C11.7683 1.66797 11.1792 1.66797 10 1.66797C8.82083 1.66797 8.2325 1.66797 7.86667 2.03464C7.5 2.39964 7.5 2.9888 7.5 4.16797V18.3346V7.91797C7.5 7.58645 7.3683 7.26851 7.13388 7.03408C6.89946 6.79966 6.58152 6.66797 6.25 6.66797H3.75C3.41848 6.66797 3.10054 6.79966 2.86612 7.03408C2.6317 7.26851 2.5 7.58645 2.5 7.91797V18.3346" stroke="currentColor" stroke-width="1.4"/>
				</g>
				<defs><clipPath id="clip0_300_3167"><rect width="20" height="20" fill="white"/></clipPath></defs>
			</svg>통계
		</a></li>

		<%-- 디바이스 리스트 --%>
		<li><a class="${onDevice ? 'active' : ''}" style="${linkPad}${onDevice ? actSty : ''}" href="${cp}/deviceList/viewDeviceList.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M7.50004 15H12.5M15 2.5C15.4421 2.5 15.866 2.67559 16.1786 2.98816C16.4911 3.30072 16.6667 3.72464 16.6667 4.16667V15.8333C16.6667 16.2754 16.4911 16.6993 16.1786 17.0118C15.866 17.3244 15.4421 17.5 15 17.5H5.00004C4.55801 17.5 4.13409 17.3244 3.82153 17.0118C3.50897 16.6993 3.33337 16.2754 3.33337 15.8333V4.16667C3.33337 3.72464 3.50897 3.30072 3.82153 2.98816C4.13409 2.67559 4.55801 2.5 5.00004 2.5H15Z" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>디바이스 리스트
		</a></li>

		<%-- SIP CALL (신설) --%>
		<li><a class="${onSip ? 'active' : ''}" style="${linkPad}${onSip ? actSty : ''}" href="${cp}/sipcall/sipCallLog">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M5 3.5c-.8 0-1.5.7-1.4 1.5.4 6 5.4 11 11.4 11.4.8.1 1.5-.6 1.5-1.4v-2.1c0-.6-.4-1.1-1-1.3l-2-.5c-.5-.1-1 .1-1.3.5l-.6.8c-1.8-.9-3.3-2.4-4.2-4.2l.8-.6c.4-.3.6-.8.5-1.3l-.5-2c-.2-.6-.7-1-1.3-1H5Z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round"/>
			</svg>SIP CALL
		</a></li>

		<%-- 내 정보 --%>
		<li><a class="${onMyInfo ? 'active' : ''}" style="${linkPad}${onMyInfo ? actSty : ''}" href="${cp}/myInfo/viewMyInfo.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M9.99998 3.33325C10.884 3.33325 11.7319 3.68444 12.357 4.30956C12.9821 4.93468 13.3333 5.78253 13.3333 6.66659C13.3333 7.55064 12.9821 8.39849 12.357 9.02361C11.7319 9.64873 10.884 9.99992 9.99998 9.99992C9.11592 9.99992 8.26808 9.64873 7.64296 9.02361C7.01784 8.39849 6.66665 7.55064 6.66665 6.66659C6.66665 5.78253 7.01784 4.93468 7.64296 4.30956C8.26808 3.68444 9.11592 3.33325 9.99998 3.33325ZM9.99998 10.8333C12.225 10.8333 16.6666 11.9416 16.6666 14.1666V16.6666H3.33331V14.1666C3.33331 11.9416 7.77498 10.8333 9.99998 10.8333Z" fill="currentColor"/>
			</svg>내 정보
		</a></li>
	</ul>
</aside>
