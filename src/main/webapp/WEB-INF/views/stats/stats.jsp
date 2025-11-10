<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>


<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/stats.css">
<title>home</title>
</head>
<style>

	.container {
		overflow:hidden;
	}
	
  .left {
   	float:left;
   	width:1200px;
   	border:1px soild black;
   }	

  .c3-area {
    fill: none !important;
  }
  .c3-chart {
    fill: none !important;
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
<script src="https://d3js.org/d3.v5.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.js"></script>
<!-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<script>
  <c:if test="${not empty myInfoErrorMsg}">
    alert('<c:out value="${myInfoErrorMsg}" />');
  </c:if>
</script>
<!-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<!--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) -->
<script>
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
  });
</script>
<!--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) -->
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
	<!-- 헤더 -->
	<header class="header">
	  <div class="logo">
	    <img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
	         alt="GAILAB" class="header-icon">
	  </div>
	
	  <div class="right-group">
	    <div class="user">
	      <img src="${pageContext.request.contextPath}/resources/images/user.png"
	           alt="유저" class="user-image">
	      <span class="user-name">hskim</span>
	    </div>
	    <div class="logout">
	      <button onclick="location.href='/gov-disabled-web-gs/user/logout'">로그아웃</button>
	    </div>
	  </div>
	</header>
    <div class="container">
        <aside class="sidebar">
            <ul class="menu">
                <li><a href="/gov-disabled-web-gs/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">홈</a></li>
                <li><a href="/gov-disabled-web-gs/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <li><a href="/gov-disabled-web-gs/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
            </ul>
        </aside>    
    	<div class="content">
    		<h1>월별 불법주차 현황</h1>
			<div>
				<!-- 장애인, 비장애인 별 이벤트 발생 현황(라인 그래프) -->
				<div id="chart" style="width: 75%; height: 400px;">
			
				</div>
				<div>
					<!-- 장애인, 비장애인 별 이벤트 발생 현황(표) -->
					<table>
						<tr>
							<td> 
							</td>
							<c:forEach var="row" items="${statsByMonth}"  varStatus="month">
								<c:if test="${month.index % 6 == 0}">
									<td>
										${fn:substring(row.st_date,5,7)}월
									</td>
								</c:if>
							</c:forEach>
						</tr>
						<tr>
							<td>
								미등록차량
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '1'}" >
									<td>	
										${row.st_cnt}
									</td>
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
										${row.st_cnt}
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
										${row.st_cnt}
									</td>
								</c:if>	
							</c:forEach>
						</tr>
						 -->
						<tr>
							<td>
								위험상황
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '4'}">
									<td>
										${row.st_cnt}
									</td>
								</c:if>	
							</c:forEach>
						</tr>
						<tr>
							<td>
								물건적재
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '5'}">
									<td>
										${row.st_cnt}
									</td>
								</c:if>	
							</c:forEach>
						</tr>
						<tr>
							<td>
								이중주차
							</td>
							<c:forEach var="row" items="${statsByMonth}">
								<c:if test="${row.st_cd == '6'}">
									<td>
										${row.st_cnt}
									</td>
								</c:if>	
							</c:forEach>
						</tr>
					</table>
				</div>
			</div>
    	</div>
    </div>
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>