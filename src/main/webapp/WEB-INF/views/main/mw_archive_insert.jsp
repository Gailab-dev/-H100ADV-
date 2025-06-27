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
				<h3 class="col-md-4">자료실 등록</h3>
			</div>
			<form id="insertArchiveForm" method="post"
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
							<td><textarea name="a_title" id="a_title" class="textarea"
									wrap="on" placeholder="제목(200자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="border-blue point">내용</th>
							<td><textarea name="a_content" id="a_content"
									class="textarea" style="min-height: 450px;" wrap="on"
									placeholder="내용을 입력해주세요.(3000자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point">파일 첨부</th>
							<td>
								<div class="custom-file">
									<input type="file" id="a_files" name="a_files"
										aria-describedby="inputGroupFileAddon04" multiple>
								</div>
							</td>
						</tr>
					</tbody>
				</table>
			</form>
			<div class="button-wrapper">

				<button id="btnInsertArchive" type="button" class="btn btn-bule">
					등록</button>
				<button type="button" class="btn btn-secondary"
					onclick='location.href="/main/mw_archive_board.do"'>취소</button>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$(document).ready(
				function() {
					$("#btnInsertArchive").click(
							function() {
								var title = $("#a_title").val();
								if (title === "") {
									alert("공지사항 제목을 입력해주세요.");
									return;
								}
								var content = $("#a_content").val();
								if (content === "") {
									alert("공지사항 내용을 입력해주세요.");
									return;
								}
								let fileList = $("#insertArchiveForm")[0][2].files;
								
								for (var file of fileList) {
									if (file.size >= 50000000) {
										alert("파일의 용량이 50MB 초과하였습니다.");
										return;
									}
								}
								
								if (confirm("등록하시겠습니까?")) {
									$("#insertArchiveForm").attr("action",
											"/main/insert_archive.do");
									$("#insertArchiveForm").submit();
								}
							});
				})
	</script>
</body>
</html>
