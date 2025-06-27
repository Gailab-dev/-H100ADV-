<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<html lang="kr">
<head>
<meta charset="utf-8">
<meta name="viewport"
	content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="">

<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/lib.jsp"%>

</head>

<body>
	<%@ include file="../include/header.jsp"%>

	<div class="container-fluid">
		<div class="row">
			<%@ include file="../include/nav.jsp"%>

			<main role="main"
				class="col-md-9 ml-sm-auto col-lg-10 d-flex flex-column"
				style="height: calc(100vh - 91px)">
				
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
			</form>
			<div class="button-wrapper">

				<button id="btnUpdateNotice" type="button" class="btn btn-bule">공지사항
					수정</button>
				<button id="btnDeleteNotice" type="button" class="btn btn-bule">공지사항
					삭제</button>
				<button type="button" class="btn btn-secondary"
					onclick='location.href="/admin/mw_notice_list.do"'>목록</button>
			</div>
		</div>
				
				<%@ include file="../include/footer.jsp"%>
			</main>
		</div>
	</div>
	<script>
	$(document).ready(
			function() {
				$("#btnUpdateNotice").click(
						function() {
							if (confirm("공지사항을 수정하시겠습니까?")) {
								$("#updateNoticeForm").attr("action",
										"/admin/mw_notice_update.do");
								$("#updateNoticeForm").submit();
								alert("수정되었습니다.");
							}
						});
				$("#btnDeleteNotice").click(
						function() {
							if (!confirm("공지사항을 삭제하시겠습니까?")) return;
							location.href="/admin/mw_notice_delete.do?id=${notice.n_id}";
						});
			})
	</script>
</body>
</html>
