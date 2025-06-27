<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/main_lib.jsp"%>
<style>
/* 노트 : css 폴더로 이동 부탁드립니다  */
.list-wrapper {
	min-height: 510px;
}

.table-list td.notice-file, .table-list td.notice-tag {
	padding: 0;
}

.notice-tag span {
	display: inline-block;
	background-color: #0066b3;
	padding: 4px 6px;
	border-radius: 5%;
	font-size: 12px;
	font-weight: 500;
	color: #fff;
}
</style>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">
		<div class="container">
			<div class="row">
				<h3 class="col-md-4 ">공지사항 등록</h3>
			</div>
			<form id="insertNoticeForm" method="post"
				encType="multipart/form-data">
				<table
					class="table table-input table-pc table-sm table-bordered mt-4">
					<colgroup>
						<col width="15%" />
						<col width="85%" />
					</colgroup>
					<tbody>

						<tr>
							<th class="border-blue point">제목</th>
							<td><textarea name="n_title" id="n_title" class="textarea"
									wrap="on" placeholder="제목(200자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="border-blue point">내용</th>
							<td><textarea name="n_content" id="n_content"
									class="textarea" style="min-height: 450px;" wrap="on"
									placeholder="내용을 입력해주세요.(3000자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point">파일 첨부</th>
							<td>
								<div class="custom-file">
									<input type="file" id="n_files" name="n_files"
										aria-describedby="inputGroupFileAddon04" multiple>
								</div>
							</td>
						</tr>
					</tbody>
				</table>
				<div class="button-wrapper">
				<div class="  mr-4">
					<input class="form-check-input" type="checkbox" id="n_importance" name="n_importance"> <label class="form-check-label" for="">
						공지사항 여부 </label>
				</div>
				<button id="btnInsertNotice" type="button" class="btn btn-bule">공지사항
					등록</button>
				<button type="button" class="btn btn-secondary"
					onclick='location.href="/main/mw_notice_board.do"'>취소</button>
			</div>
			</form>

			
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$(document).ready(
				function() {
					$("#btnInsertNotice").click(
							function() {
								var title = $("#n_title").val();
								if (title === "") {
									alert("공지사항 제목을 입력해주세요.");
									return;
								}
								var content = $("#n_content").val();
								if (content === "") {
									alert("공지사항 내용을 입력해주세요.");
									return;
								}
								let fileList = $("#insertNoticeForm")[0][2].files
								
								for (var file of fileList) {
									if (file.size >= 50000000) {
										alert("파일의 용량이 50MB 초과하였습니다.");
										return;
									}
								}
								
								if (confirm("공지사항을 등록하시겠습니까?")) {
									$("#insertNoticeForm").attr("action",
											"/main/insert_notice.do");
									$("#insertNoticeForm").submit();
								}
							});
				})
	</script>
</body>
</html>
