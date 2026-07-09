<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<!DOCTYPE html>
<!-- 템플릿 파일에서부터 시작합니다. -->
<html lang="ko">
<head>
	<!-- ---------------------- 공통 meta 설정----------------------------- -->
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<!-- ---------------------- 공통 라이브러리 ---------------------------- -->
	<script src="${pageContext.request.contextPath}/resources/js/jquery-3.3.1.min.js"></script>
	<script src="${pageContext.request.contextPath}/resources/js/c3.min.js"></script>
	<!-- ----------------------- 공통 스타일 ------------------------------- -->
	<%-- patches 2026-07-09: 존재하지 않는 common.css 링크 제거(404 콘솔 에러 정리). 실제 사용 안 함 --%>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css" />
	<!-- 공용 레이아웃(chrome) 스타일 -->
	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/layout.css" />
	<%-- patches 2026-07-07: 공용 레이아웃 보정(모든 Tiles 화면 일관, CSS 캐시 무관)
	     ① 세로 스크롤바 항상 표시 — 스크롤 유무로 폭이 달라져 틀 어긋나는 문제 방지
	     ② html/body 기본 여백 제거 — dashboard/SIP 은 페이지 CSS 의 '* margin:0' 리셋이 없어 좌·상단 여백이 생기던 문제 해소
	     ③ nav hover 일관 — 일부 페이지 CSS 가 hover 를 정상색(#FCFBFF)으로 무효화하던 것을 !important 로 통일 --%>
	<style>
		/* ① 세로 스크롤: 내용이 뷰포트를 넘을 때만 스크롤바 노출(리스트 조회 건수 늘리면 자연히 생김). 평소엔 안 보임 */
		html { overflow-y: auto; }
		html, body { margin: 0; padding: 0; }
		/* ② patches 2026-07-09(2): 본문 내부의 '중첩' page-wrapper(min-height:100vh) 무력화.
		   eventList/stats/myInfo 는 본문 조각 안에 또 .page-wrapper 를 가져, 바깥 헤더(80px)만큼 뷰포트를 초과 →
		   하단 여백 + 오른쪽 스크롤이 항상 생기던 문제. 바깥(body>.page-wrapper)은 100vh 유지(사이드바 하단까지). */
		.content .page-wrapper { min-height: 0 !important; height: auto !important; }
		/* ③ 메뉴 폰트 통일 + 좌우 패딩을 링크로 이전(사이드바 좌우 패딩 제거 → 배경이 폭을 꽉 채움) */
		.menu > li > a { font-family: Arial, sans-serif !important; line-height: 20px !important; padding-left: 20px !important; padding-right: 20px !important; }
		/* ④ 사이드바 좌우 여백 제거 → hover/active 배경이 사이드바 폭을 양쪽 여백 없이 꽉 채움 */
		.sidebar { padding-left: 0 !important; padding-right: 0 !important; }
		.menu > li > a:hover { background: #f1edff !important; }
		/* ⑤ 현재 화면(active) = hover 와 '똑같은 색(#f1edff)' 을 마우스 위치와 무관하게 항상 유지(요구사항).
		   실제 적용은 left.jsp 의 인라인 !important 가 담당(최상위 우선순위). 여기는 일관성용 보조 규칙. */
		.menu > li > a.active,
		.menu > li > a.active:hover { background: #f1edff !important; }
	</style>
	<!-- ---------------------- 공통 자바스크립트 함수 ---------------------- -->
	<script src="${pageContext.request.contextPath}/resources/js/common.js"></script>
	<!-- 화면별 추가 head (선택) -->
	<tiles:insertAttribute name="head" ignore="true"/>
</head>
<body>
	<div class="page-wrapper">
		<%-- 상단 헤더 --%>
		<tiles:insertAttribute name="header"/>
		<div class="container">
			<%-- 좌측 사이드바 --%>
			<tiles:insertAttribute name="left"/>
			<%-- 본문 --%>
			<div class="content">
				<tiles:insertAttribute name="body"/>
			</div>
		</div>
		<%-- 푸터 --%>
		<tiles:insertAttribute name="footer"/>
	</div>
</body>
</html>
