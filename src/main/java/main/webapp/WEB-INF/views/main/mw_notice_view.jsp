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
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<input type="hidden" id="notice_id" value="${notice.n_id }" />
	<div class="wrapper main-page">
		<div class="container">
			<div class="row">
				<h3 class="col-md-4">공지사항 상세</h3>
			</div>
			<table class="table table-input table-sm table-bordered mt-4" style="table-layout: fixed;">
				<colgroup>
					<col width="15%" />
					<col width="85%" />
				</colgroup>
				<tbody>
					<tr>
					<th class="border-blue point">제목</th>
                        <td >
                            <div class="d-sm-flex justify-content-between align-items-end n p-2 d-block">
                                <h4 class="col-sm-8 d-block m-0 text-truncate" style="text-align: left; ">${notice.n_title }</h4>
                                <p class="col-sm-4 text-secondary mt-2">
                                    <span class="mr-2">[${notice.dp_name }] ${notice.u_name }</span>
                                    ${notice.date }</p>
                            </div>
                        </td>
                    </tr>
					<tr>
					<th class="border-blue point">내용</th>
						<td >
                            <p class="p-2" style="min-height: 450px; text-align: left; white-space: break-spaces;">${notice.n_content }</p>
                        </td>
					</tr>
					<tr>
						<th class="point">파일 첨부</th>
						<td>
							<ul class="file-list">
								<c:choose>
									<c:when test="${fn:length(noticeFiles) == 0 }">
										첨부된 파일이 존재하지 않습니다.
									</c:when>
									<c:otherwise>
										<c:forEach items="${noticeFiles }" var="file">
											<li><a href="/static/notice_files/${file.nf_file_name }">${file.nf_file_name }</a></li>
										</c:forEach>
									</c:otherwise>
								</c:choose>
							</ul>
						</td>
					</tr>
				</tbody>
			</table>
			<div class="button-wrapper">
				<button type="button" class="btn btn-bule" onclick='location.href="/main/mw_notice_board.do"'>목록</button>
				<c:if test="${notice.u_id == sessionScope.userId }">
					<button type="button" class="btn btn-red" onclick='location.href="/main/mw_notice_update.do?id=${notice.n_id}"'>수정</button>
				</c:if>
				<c:if test="${notice.u_id == sessionScope.userId }">
					<button id="btnDeleteNotice" type="button" class="btn btn-red">삭제</button>
				</c:if>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$(document).ready(
				function() {
					$("#btnDeleteNotice").click(
							function() {
								if (!confirm("삭제하시겠습니까?")) return;
								location.href="/main/delete_notice.do?id=${notice.n_id}"
 							});
				})
	</script>
</body>
</html>
