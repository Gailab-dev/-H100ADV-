<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%--
	(요청 2026-07-16) 헤더 사람아이콘 → 내 정보 모달 전용 문서.
	모달 안 iframe 으로 로드되어 CSS/JS 가 호출 화면과 완전히 분리된다(myinfo.css 의 chrome 규칙이 대시보드 등에 새지 않음).
	내용은 기존 myInfo.jsp 를 그대로 include → 검증·이메일 인증·저장 로직 100% 재사용(재작성 없음).
--%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>내 정보</title>
<style>
	/* iframe 문서 기준 보정 — myinfo.css 의 전체화면용 chrome 규칙 무력화 */
	html, body { margin: 0; padding: 0; background: #fff; }
	.page-wrapper {
		min-height: 0 !important;
		height: auto !important;
		display: block !important;
		padding: 22px 26px 18px 26px;
	}
	.topTitle { margin: 0 0 14px 0; }
	/* 저장 버튼: 왼쪽 아래 → 오른쪽 아래 (요청) */
	.saveBox {
		display: flex !important;
		justify-content: flex-end !important;
		align-items: center;
		gap: 16px;
		margin-top: 18px;
	}
</style>
</head>
<body>
	<jsp:include page="myInfo.jsp" />
</body>
</html>
