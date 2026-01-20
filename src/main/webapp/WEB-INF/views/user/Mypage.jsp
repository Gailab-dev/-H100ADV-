<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/Mypage.css">
<title>내 정보</title>
</head>
<body>
	<div class=page-wrapper>
		<!-- 헤더 -->
		<header class="header">
			<div class="logo">
				<img
					src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
					alt="GAILAB" class="header-icon">
			</div>

			<div class="right-group">
				<c:if test="${useTblLog == false}">
					<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다.
						관리자에게 문의해주세요.</div>
				</c:if>
				<div class="user">
					<img
						src="${pageContext.request.contextPath}/resources/images/user.png"
						alt="유저" class="user-image"> <span class="user-name">hskim</span>
				</div>
				<div class="logout">
					<button
						onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
				</div>
			</div>
		</header>
		<div class="container">
			<aside class="sidebar">
				<ul class="menu">
					<li><a
						href="${pageContext.request.contextPath}/eventList/viewEventList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
						<path fill-rule="evenodd" clip-rule="evenodd"
									d="M2.70837 5.83203C2.70837 5.66627 2.77422 5.5073 2.89143 5.39009C3.00864 5.27288 3.16761 5.20703 3.33337 5.20703H16.6667C16.8325 5.20703 16.9914 5.27288 17.1086 5.39009C17.2259 5.5073 17.2917 5.66627 17.2917 5.83203C17.2917 5.99779 17.2259 6.15676 17.1086 6.27397C16.9914 6.39118 16.8325 6.45703 16.6667 6.45703H3.33337C3.16761 6.45703 3.00864 6.39118 2.89143 6.27397C2.77422 6.15676 2.70837 5.99779 2.70837 5.83203ZM2.70837 9.9987C2.70837 9.83294 2.77422 9.67397 2.89143 9.55676C3.00864 9.43955 3.16761 9.3737 3.33337 9.3737H12.5C12.6658 9.3737 12.8248 9.43955 12.942 9.55676C13.0592 9.67397 13.125 9.83294 13.125 9.9987C13.125 10.1645 13.0592 10.3234 12.942 10.4406C12.8248 10.5578 12.6658 10.6237 12.5 10.6237H3.33337C3.16761 10.6237 3.00864 10.5578 2.89143 10.4406C2.77422 10.3234 2.70837 10.1645 2.70837 9.9987ZM2.70837 14.1654C2.70837 13.9996 2.77422 13.8406 2.89143 13.7234C3.00864 13.6062 3.16761 13.5404 3.33337 13.5404H7.50004C7.6658 13.5404 7.82477 13.6062 7.94198 13.7234C8.05919 13.8406 8.12504 13.9996 8.12504 14.1654C8.12504 14.3311 8.05919 14.4901 7.94198 14.6073C7.82477 14.7245 7.6658 14.7904 7.50004 14.7904H3.33337C3.16761 14.7904 3.00864 14.7245 2.89143 14.6073C2.77422 14.4901 2.70837 14.3311 2.70837 14.1654Z"
									fill="currentColor" />
						</svg>불법주차 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/stats/viewStat.do"> <svg
								class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<g clip-path="url(#clip0_300_3167)">
								<path d="M18.3333 18.3359H1.66663" stroke="currentColor"
									stroke-width="1.4" stroke-linecap="round" />
								<path
									d="M17.5 18.3346V12.0846C17.5 11.7531 17.3683 11.4352 17.1339 11.2008C16.8995 10.9663 16.5815 10.8346 16.25 10.8346H13.75C13.4185 10.8346 13.1005 10.9663 12.8661 11.2008C12.6317 11.4352 12.5 11.7531 12.5 12.0846V18.3346V4.16797C12.5 2.98964 12.5 2.40047 12.1333 2.03464C11.7683 1.66797 11.1792 1.66797 10 1.66797C8.82083 1.66797 8.2325 1.66797 7.86667 2.03464C7.5 2.39964 7.5 2.9888 7.5 4.16797V18.3346V7.91797C7.5 7.58645 7.3683 7.26851 7.13388 7.03408C6.89946 6.79966 6.58152 6.66797 6.25 6.66797H3.75C3.41848 6.66797 3.10054 6.79966 2.86612 7.03408C2.6317 7.26851 2.5 7.58645 2.5 7.91797V18.3346"
									stroke="currentColor" stroke-width="1.4" />
							</g>
							<defs>
							<clipPath id="clip0_300_3167">
							<rect width="20" height="20" fill="white" />	</clipPath></defs>
						</svg>통계
					</a></li>

					<li><a
						href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<path
									d="M7.50004 15H12.5M15 2.5C15.4421 2.5 15.866 2.67559 16.1786 2.98816C16.4911 3.30072 16.6667 3.72464 16.6667 4.16667V15.8333C16.6667 16.2754 16.4911 16.6993 16.1786 17.0118C15.866 17.3244 15.4421 17.5 15 17.5H5.00004C4.55801 17.5 4.13409 17.3244 3.82153 17.0118C3.50897 16.6993 3.33337 16.2754 3.33337 15.8333V4.16667C3.33337 3.72464 3.50897 3.30072 3.82153 2.98816C4.13409 2.67559 4.55801 2.5 5.00004 2.5H15Z"
									stroke="currentColor" stroke-width="1.4" stroke-linecap="round"
									stroke-linejoin="round" />
						</svg>디바이스 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">
							<svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
							<circle cx="15" cy="15" r="14.5" fill="white" stroke="black"/>
							<path d="M23 24V22C23 20.9391 22.5786 19.9217 21.8284 19.1716C21.0783 18.4214 20.0609 18 19 18H11C9.93913 18 8.92172 18.4214 8.17157 19.1716C7.42143 19.9217 7 20.9391 7 22V24M19 10C19 12.2091 17.2091 14 15 14C12.7909 14 11 12.2091 11 10C11 7.79086 12.7909 6 15 6C17.2091 6 19 7.79086 19 10Z" stroke="#1E1E1E" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
							</svg>내 정보
					</a></li>


					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<div class="content">
				<div class="topTitle">
					<p class="mypageTitle">내 정보</p>
				</div>

				<form class="editForm">
					<div class="form-group">
						<label for="userId">아이디</label> <input type="text" id="userId"
							value="gailab" readonly>
					</div>

					<div class="form-group">
						<label for="userRole">회원권한</label> <input type="text"
							id="userRole" value="최고관리자" readonly>
					</div>

					<div class="form-group">
   						<label for="currentPw">기존 비밀번호</label>
    					<div class="inputBox">
        					<input type="password" id="currentPw">
        					<p class="hint-text">영문, 숫자, 특수문자 6-20자</p>
    					</div>
					</div>

					<div class="form-group">
    					<label for="newPw">새 비밀번호</label>
    					<div class="inputBox">
        					<input type="password" id="newPw">
        					<p class="hint-text">영문, 숫자, 특수문자 6-20자</p>
    					</div>
					</div>

					<div class="form-group">
						<label for="confirmPw">비밀번호 확인</label>
						<input type="password" id="confirmPw">
					</div>

					<div class="form-group">
						<label for="email">이메일</label>
						<div class="emailBox">
							<input type="email" id="email" readonly value="이메일 들어오기">
							<button class="editEmail">변경</button>
						</div>
					</div>
				</form>
				<div class="saveBox">
						<button type="submit" class="saveButton">저장</button>
				</div>
			</div>
		</div>
</body>
</html>