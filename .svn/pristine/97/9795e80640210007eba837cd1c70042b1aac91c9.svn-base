<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="page" value="${applicationScope.page }" />
<c:set var="userGrade" value="${sessionScope.userGrade }" />
<div>
	<nav class="navbar navbar-expand-lg navbar-light border-bottom">
		<div class="container">
			<a class="mr-2 py-2" href="main.do"> <img
				src="${path}/resources/images/footer_logo.png" alt=""
				class="d-inline-block align-text-top" width="250px" />
			</a>

			<div class="d-flex justify-content-end align-items-center">
				<button class="search-btn btn mr-2 rounded" type="button"
					onclick="location.href='mw_search_list.do'">
					<span><svg width="16" height="16"
							class="DocSearch-Search-Icon mr-2" viewBox="0 0 20 20">
							<path
								d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z"
								stroke="currentColor" fill="none" fill-rule="evenodd"
								stroke-linecap="round" stroke-linejoin="round"></path></svg></span>검색
				</button>
				<div class="text-end">
					<button type="button" class="btn btn-bule" id="register"
						onclick='location.href="certificateRequest.do"'>인증서 연결</button>
					<span class="pl-4 pr-2">${sessionScope.userDepartment}
						${sessionScope.userName}님</span>
					<button type="button" class="btn btn-light text-dark me-2"
						onclick='location.href="logout.do"'>로그아웃</button>
				</div>
			</div>
		</div>
	</nav>
	<nav class="navbar navbar-expand-lg navbar-light border-bottom">
		<div class="container">
			<div class="collapse navbar-collapse d-lg-none">
				<ul class="nav navbar-nav m-auto">
					<li class="nav-item"><a class="nav-link"
						href="mw_notice_board.do"
						style="${page eq 'mw_notice' ? 'color: #0066b3' : ''}">공지사항</a></li>
					<li class="dropdown-hover"><a
						class="nav-link dropdown-toggle-hover"
						style="${page eq 'mw_insert' ? 'color: #0066b3' : ''}" href="#">신규등록</a>
						<div class="dropdown-menu-list">
							<a class="dropdown-menu-item" href="mw_insert.do">개별등록</a> <a
								class="dropdown-menu-item" href="mw_insert_excel.do">일괄등록(엑셀)</a>
							<a class="dropdown-menu-item" href="mw_insert_temp_list.do">임시저장
								목록</a>
						</div></li>
					<li class="nav-item"><a class="nav-link"
						href="mw_process_list.do"
						style="${page eq 'mw_process' ? 'color: #0066b3' : ''}">이력관리</a></li>
					<li class="nav-item"><a class="nav-link"
						href="mw_not_completed_list.do"
						style="${page eq 'mw_not_completed' ? 'color: #0066b3' : ''}">처리진행</a></li>
					<li class="nav-item"><a class="nav-link"
						href="mw_completed_list.do"
						style="${page eq 'mw_completed' ? 'color: #0066b3' : ''}">처리완료</a></li>
					<li class="nav-item"><a class="nav-link"
						href="mw_archive_board.do"
						style="${page eq 'mw_archive' ? 'color: #0066b3' : ''}">자료실</a></li>
					<li class="nav-item"><a class="nav-link"
						href="mw_reply_list.do"
						style="${page eq 'mw_reply' ? 'color: #0066b3' : ''}">최근댓글</a></li>
				</ul>

			</div>
			<div class="menu-bar">
				<input type="checkbox" id="check_box" /> <label for="check_box">
					<span></span> <span></span> <span></span>
				</label>

				<div id="side_menu">
					<div class="d-flex justify-content-end">
						<input type="checkbox" id="check_box" checked /> <label
							for="check_box"> <span></span> <span></span> <span></span>
						</label>
					</div>
					<ul class="main-menu">
						<li class="nav-item dropdown"><a class="nav-link " href="#"
							data-toggle="dropdown" aria-expanded="false">신규등록</a></li>
						<li>
							<ul class="sub-menu">
								<li class="nav-item"><a class="nav-link"
									href="mw_insert.do">개별등록</a></li>
								<li class="nav-item"><a class="nav-link"
									href="mw_insert_excel.do">일괄등록(엑셀)</a></li>
								<li class="nav-item"><a class="nav-link"
									href="mw_insert_temp_list.do">임시저장 목록</a></li>
							</ul>
						</li>
						<li class="nav-item"><a class="nav-link"
							href="mw_process_list.do">등록민원목록</a></li>
						<li class="nav-item"><a class="nav-link"
							href="mw_completed_list.do">처리완료</a></li>
						<li class="nav-item"><a class="nav-link"
							href="mw_not_completed_list.do">처리중</a></li>
						<li class="nav-item"><a class="nav-link"
							href="mw_reply_list.do">최근댓글</a></li>
						<li class="nav-item"><a class="nav-link" href="#">공지사항</a></li>
						<li class="nav-item"><a class="nav-link" href="#">자료실</a></li>
					</ul>
				</div>
			</div>
		</div>
	</nav>
</div>
