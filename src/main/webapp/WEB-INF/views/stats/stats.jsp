<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>


<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/stats.css">
<title>home</title>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%=session.getMaxInactiveInterval()%>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script
	src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<script>
	  <c:if test="${not empty errorMsg}">
	    alert('<c:out value="${errorMsg}" />');
	  </c:if>
	</script>
<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
</head>
<style>
.container {
	overflow: hidden;
}

.left {
	float: left;
	width: 1200px;
	border: 1px soild black;
}

.c3-area {
	fill: none !important;
}

.c3-chart {
	fill: none !important;
}

/* 기본: 보이는 시리즈의 이름은 진한 검은색 */
.c3-legend-item text {
	fill: #000000;
	opacity: 1;
}

/* 숨겨진 시리즈: 그래프도 안 보이고, 이름도 회색/옅게 */
.c3-legend-item-hidden text {
	fill: #aaaaaa;
	opacity: 0.5;
}
</style>

<!-- 
<c:set var="xData" value="['x'" />
<c:set var="yData" value="['data1'" />
<c:forEach var="row" items="${statsByMonth}">
    <c:set var="xData" value="${xData}, '${row.st_date}'" />
    <c:set var="yData" value="${yData}, ${row.st_cnt}" />
</c:forEach>
<c:set var="xData" value="${xData}]" />
<c:set var="yData" value="${yData}]" />
 -->

<script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
<script src="https://d3js.org/d3.v5. min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.js"></script>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<script>
  <c:if test="${not empty errorMsg}">
    alert('<c:out value="${errorMsg}" />');
  </c:if>
</script>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<script>
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
  });
</script>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<script>
	$(document).ready(function () {
		
		// 차트 초기화
		d3.select("#chart").html("");
		
		// 변수 선언 및 배열로 정렬
		let xData = ['x' 
				<c:forEach var="row" items="${statsByMonth}" varStatus="month">
					<c:if test = "${month.index % 6 == 0}">
						, '${row.st_date}'
					</c:if>	
				</c:forEach>
			];
		let yData1 = ['data1'
				<c:forEach var="row" items="${statsByMonth}">
					<c:if test="${row.st_cd == 1}">
						, ${row.st_cnt}
					</c:if>	
				</c:forEach>
			];
		let yData2 = ['data2'
				<c:forEach var="row" items="${statsByMonth}">
					<c:if test="${row.st_cd == 2}">
						, ${row.st_cnt}
					</c:if>	
				</c:forEach>
			];
		let yData3 = ['data3'
			<c:forEach var="row" items="${statsByMonth}">
				<c:if test="${row.st_cd == 3}">
					, ${row.st_cnt}
				</c:if>	
			</c:forEach>
		];
		let yData4 = ['data4'
			<c:forEach var="row" items="${statsByMonth}">
				<c:if test="${row.st_cd == 4}">
					, ${row.st_cnt}
				</c:if>	
			</c:forEach>
		];
		let yData5 = ['data5'
			<c:forEach var="row" items="${statsByMonth}">
				<c:if test="${row.st_cd == 5}">
					, ${row.st_cnt}
				</c:if>	
			</c:forEach>
		];
		let yData6 = ['data6'
			<c:forEach var="row" items="${statsByMonth}">
				<c:if test="${row.st_cd == 6}">
					, ${row.st_cnt}
				</c:if>	
			</c:forEach>
		];

		
		// 차트 생성
		// 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가
		let chart = c3.generate({
			bindto:'#chart', // 바인팅할 html 태그의 id
		    data: {  // 데이터에 관한 속성값
		        x: 'x', // x축 데이터를 식별하는 식별자
		        columns: [  // 각 컬럼별 배열
		        	xData,
		        	yData1,
		        	// yData2,
		        	// yData3,
		        	yData4,
		        	yData5,
		        	yData6
		        ],
		        type:'line', // 그래프 종류(라인 그래프)
		        names :{  // 데이터 별 이름
		        	data1: '미등록차량', 
		        	// data2: '장애인미탑승',
	        		// data3: '스티커 불법 사용',
        			data4: '위험상황',
        			data5: '물건적재',
        			data6: '이중주차'
		        }
		    },
		    area: {
		    	show: false
		    },
		    axis: {
		    	x: {
		    		type: 'category', 
		    		tick: {
		    			fit: true,
		    			rotate: 45,
		    			multiline: false
		    		}
		    	},
		    	y : {
		    		label: {
		    			text: '건수',
		    			position: 'outer-middle'
		    		},
		    		min: 0,
		    		padding : {
		    			bottom: 0
		    		}
		    	}
		    },
		    legend: {
		    	position: 'right'
		    },
		    padding: {
		        right: 150  // 우측 여백 확보
		    },
		    line: {
		        connectNull: true
		    },
		    tooltip: {
		        grouped: true  // 여러 시리즈 함께 보기
		    },
		    color: {
		        pattern: ['#7a7978', '#87cbac','#90ffdc','#8de4ff','#8ac4ff']  // 비장애인, 장애인 선 색상 지정
		    }
		    
		});
	})
</script>
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


					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<div class="content">
				<div class="title-box">
					<h1>월별 불법주차 현황(1년)</h1>
					<form id="StatsExcelDownload"
						action="gov-disabled-web-gs/stats/excelDownload">
						<button type="submit" class="excel-btn" title="엑셀 다운로드">
							<img
								src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
								alt="엑셀 다운로드">
						</button>
					</form>
				</div>
				<form id="StatsSearchForm"
					action="/gov-disabled-web-gs/stats/stats.do" class="filter-form">
					<div class="filter-input-group">
						<input type="date" name="startDate" value="${startDate}" />
					</div>
					<p class="date-contect">~</p>
					<div class="filter-input-group">
						<input type="date" name="endDate" value="${endDate}" />
					</div>
					<div class="filter-input-group">
						<select id="pageSize" name="pageSize" onchange="searchEventList()">
							<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩
								보기</option>
							<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩
								보기</option>
							<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩
								보기</option>
						</select>
					</div>
					<button type="button" class="search-btn"
						onclick="searchEventList('${paginationInfo.currentPageNo != null ? paginationInfo.currentPageNo : 1}')">조회</button>
				</form>


				<div class="graph-group">
					<!-- 장애인, 비장애인 별 이벤트 발생 현황(라인 그래프) -->
					<div id="chart" class="graph-table" style="height: 402px;">
						<p class="subTitle">불법주차 유형별 통계(그래프 )</p>
					</div>

					<div class="graph-table">
						<p class="subTitle">불법주차 유형별 통계(테이블)</p>
						<!-- 불법주차 유형별 통계(테이블) -->
						<table>
							<tr>
								<td></td>
								<c:forEach var="row" items="${statsByMonth}" varStatus="month">
									<c:if test="${month.index % 1 == 0}">
										<td><c:out value="${fn:substring(row.st_date,5,7)}"
												escapeXml="true" />월</td>
									</c:if>
								</c:forEach>
							</tr>
							<tr>
								<td>미등록차량</td>
								<c:forEach var="row" items="${statsByMonth}">
									<c:if test="${row.st_cd == '1'}">
										<td><c:out value="${row.st_cnt}" escapeXml="true" /></td>
									</c:if>
								</c:forEach>
							</tr>
							<!-- 장애인 미탑승 2025. 10. 28. 판독 불가 -->
							<!-- 
						<tr>
							<td>
								장애인미탑승
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '2'}">
									<td>
										<c:out value="${row.st_cnt}" escapeXml ="true"/>
									</td>
								</c:if>	
							</c:forEach>
						</tr>
						 -->
							<!-- 스티커 불법 사용 2025. 10. 28. 판독 불가 -->
							<!-- 
						<tr>
							<td>
								스티커 불법 사용
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '3'}">
									<td>
										<c:out value="${row.st_cnt}" escapeXml ="true"/>
									</td>
								</c:if>	
							</c:forEach>
						</tr>
						 -->
							<tr>
								<td>위험상황</td>
								<c:forEach var="row" items="${statsByMonth}">
									<c:if test="${row.st_cd == '4'}">
										<td><c:out value="${row.st_cnt}" escapeXml="true" /></td>
									</c:if>
								</c:forEach>
							</tr>
							<tr>
								<td>물건적재</td>
								<c:forEach var="row" items="${statsByMonth}">
									<c:if test="${row.st_cd == '5'}">
										<td><c:out value="${row.st_cnt}" escapeXml="true" /></td>
									</c:if>
								</c:forEach>
							</tr>
							<tr>
								<td>이중주차</td>
								<c:forEach var="row" items="${statsByMonth}">
									<c:if test="${row.st_cd == '6'}">
										<td><c:out value="${row.st_cnt}" escapeXml="true" /></td>
									</c:if>
								</c:forEach>
							</tr>
						</table>
					</div>
				</div>
			</div>
		</div>
	</div>
</body>
</html>