<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" session="false"%>
<%
	// 오류 페이지 (H100 전용). 이미지·외부 리소스에 의존하지 않는다(리소스 경로 자체가 오류일 때도 보이도록).
	// 요청 URL·예외 메시지·스택은 화면에 출력하지 않는다(정보 노출 방지).
	Object attr = request.getAttribute("javax.servlet.error.status_code");
	int code = (attr instanceof Integer) ? ((Integer) attr).intValue() : 500;
	String heading;
	String message;
	switch (code) {
		case 400:
			heading = "잘못된 요청입니다";
			message = "요청 형식이 올바르지 않습니다. 주소를 확인한 뒤 다시 시도해 주세요.";
			break;
		case 403:
			heading = "접근 권한이 없습니다";
			message = "이 페이지를 볼 수 있는 권한이 없습니다. 관리자에게 문의해 주세요.";
			break;
		case 404:
			heading = "페이지를 찾을 수 없습니다";
			message = "요청하신 페이지가 없거나 이동되었습니다. 주소를 확인해 주세요.";
			break;
		case 405:
			heading = "허용되지 않는 요청입니다";
			message = "이 주소에서는 해당 방식의 요청을 사용할 수 없습니다.";
			break;
		case 503:
			heading = "서비스를 일시적으로 이용할 수 없습니다";
			message = "잠시 후 다시 시도해 주세요.";
			break;
		default:
			heading = "일시적인 오류가 발생했습니다";
			message = "요청하신 정보를 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.";
	}
	String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>G-Eye Parking H100</title>
<link rel="icon" href="data:,">
<style>
	html, body { height: 100%; margin: 0; }
	body { display: flex; align-items: center; justify-content: center; background: #f4f6f9;
		font-family: "Noto Sans KR", "Malgun Gothic", "Apple SD Gothic Neo", sans-serif; color: #2b3445; }
	.box { width: 92%; max-width: 520px; background: #fff; border-radius: 12px; padding: 40px 32px;
		text-align: center; box-shadow: 0 4px 20px rgba(0, 0, 0, .08); }
	.brand { font-size: 14px; letter-spacing: .08em; color: #6b7a90; margin-bottom: 20px; }
	.code { font-size: 56px; font-weight: 700; color: #3a6ea5; line-height: 1; margin: 0 0 12px; }
	h1 { font-size: 20px; margin: 0 0 12px; }
	p { font-size: 15px; line-height: 1.6; color: #55627a; margin: 0 0 28px; }
	.btns a, .btns button { display: inline-block; margin: 0 4px; padding: 10px 20px; border-radius: 8px;
		border: 1px solid #3a6ea5; background: #3a6ea5; color: #fff; font-size: 14px; text-decoration: none; cursor: pointer; }
	.btns button { background: #fff; color: #3a6ea5; }
</style>
</head>
<body>
	<div class="box">
		<div class="brand">G-EYE PARKING H100</div>
		<div class="code"><%= code %></div>
		<h1><%= heading %></h1>
		<p><%= message %></p>
		<div class="btns">
			<button type="button" onclick="history.back()">이전 페이지</button>
			<a href="<%= ctx %>/">처음으로</a>
		</div>
	</div>
</body>
</html>
