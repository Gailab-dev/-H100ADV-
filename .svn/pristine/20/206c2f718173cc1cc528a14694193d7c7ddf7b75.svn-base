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
.file-list {
            list-style: none;
            text-align: left;
        }
        .file-list li {
            padding: 0.25rem 0;
      }
</style>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">
		<div class="container">
			<div class="row">
				<h3 class="col-md-4">자료실 수정</h3>
			</div>
			<form id="updateArchiveForm" method="post"
				encType="multipart/form-data">
				<input type="hidden" name="a_id" id="a_id" value="${archive.a_id }" />
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
									wrap="on" placeholder="제목(200자 이내)">${archive.a_title }</textarea></td>
						</tr>
						<tr>
							<th class="border-blue point">내용</th>
							<td><textarea name="a_content" id="a_content"
									class="textarea" style="min-height: 450px;" wrap="on"
									placeholder="내용을 입력해주세요.(3000자 이내)">${archive.a_content }</textarea></td>
						</tr>
						<tr>
							<th class="point">파일 첨부</th>
							<td>
								<div class="custom-file">
									<input type="file" id="a_files" name="a_files"
										aria-describedby="inputGroupFileAddon04" multiple>
								</div>
								<ul class="file-list">
									<c:forEach items="${archiveFiles }" var="file">
										<li><a href="/static/archive_files/${file.af_file_name }">${file.af_file_name }</a></li>
									</c:forEach>
								</ul>
							</td>
							
						</tr>
					</tbody>
				</table>
			</form>
			<div class="button-wrapper">

				<button id="btnUpdateArchive" type="button" class="btn btn-bule">
					수정</button>
				<button type="button" class="btn btn-secondary"
					onclick='location.href="/main/mw_archive_board.do"'>취소</button>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$(document).ready(
				function() {
					$("#btnUpdateArchive").click(
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
								if (confirm("수정하시겠습니까?")) {
									$("#updateArchiveForm").attr("action",
											"/main/update_archive.do");
									$("#updateArchiveForm").submit();
								}
							});
				})
	</script>
</body>
</html>
