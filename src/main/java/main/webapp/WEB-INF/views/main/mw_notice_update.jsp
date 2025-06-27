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
				<h3 class="col-md-4">공지사항 수정</h3>
			</div>
			<form id="updateNoticeForm" method="post"
				encType="multipart/form-data">
				<input type="hidden" name="n_id" id="n_id" value="${notice.n_id }" />
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
									wrap="on" placeholder="제목(200자 이내)">${notice.n_title }</textarea></td>
						</tr>
						<tr>
							<th class="border-blue point">내용</th>
							<td><textarea name="n_content" id="n_content"
									class="textarea" style="min-height: 450px;" wrap="on"
									placeholder="내용을 입력해주세요.(3000자 이내)">${notice.n_content }</textarea></td>
						</tr>
						<tr>
							<th class="point">파일 첨부</th>
							<td>
								<div class="custom-file">
									<input type="file" id="n_files" name="n_files"
										aria-describedby="inputGroupFileAddon04" multiple>
								</div>
								<ul class="file-list">
									<c:forEach items="${noticeFiles }" var="file">
										<li><a href="/static/notice_files/${file.nf_file_name }">${file.nf_file_name }</a></li>
									</c:forEach>
								</ul>
							</td>

						</tr>
					</tbody>
				</table>
				<div class="button-wrapper">
					<div class="  mr-4">
						<input class="form-check-input" type="checkbox" id="n_importance"
							name="n_importance"
							<c:if test="${notice.n_importance == 1 }">checked</c:if>>
						<label class="form-check-label" for=""> 공지사항 여부 </label>
					</div>
					<button id="btnUpdateNotice" type="button" class="btn btn-bule">공지사항
						수정</button>
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
					$("#btnUpdateNotice").click(
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
								if (confirm("공지사항을 수정하시겠습니까?")) {
									$("#updateNoticeForm").attr("action",
											"/main/update_notice.do");
									$("#updateNoticeForm").submit();
								}
							});
				})
	</script>
</body>
</html>
