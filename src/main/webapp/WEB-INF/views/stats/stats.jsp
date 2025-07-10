<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!-- 
<!DOCTYPE html>
<html>
 -->
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
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

<script>
	$(document).ready(function () {
		
		// 차트 초기화
		d3.select("#chart").html("");
		
		// 변수 선언 및 배열로 정렬
		let xData = ['x' 
				<c:forEach var="row" items="${statsByMonth}" step="2">
					, '${row.st_date}'
				</c:forEach>
			];
		let yData1 = ['data1'
				<c:forEach var="row" items="${statsByMonth}">
					<c:if test="${row.st_cd == '1'}">
						, ${row.st_cnt}
					</c:if>	
				</c:forEach>
			];
		let yData2 = ['data2'
				<c:forEach var="row" items="${statsByMonth}">
					<c:if test="${row.st_cd == '2'}">
						, ${row.st_cnt}
					</c:if>	
				</c:forEach>
			];
		
		
		console.log(xData);
		console.log(yData1);
		console.log(yData2);
		console.log(typeof xData[1]);
		console.log(typeof yData1[1]);
		console.log(typeof yData2[1]);
		
		// 차트 생성
		let chart = c3.generate({
			bindto:'#chart', // 바인팅할 html 태그의 id
		    data: {  // 데이터에 관한 속성값
		        x: 'x', // x축 데이터를 식별하는 식별자
		        columns: [  // 각 컬럼별 배열
		        	xData,
		        	yData1,
		        	yData2
		        ],
		        type:'line', // 그래프 종류(라인 그래프)
		        names :{  // 데이터 별 이름
		        	data1: '비장애인주차', 
		        	data2: '장애인 비등록차량'
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
		    }
		    
		});
	})
</script>
<body>
	<h1> 통계 화면</h1>
	<div id="container">
		<div id="left">
			left
		</div>
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
						<c:forEach var="row" items="${statsByMonth}" step="2">
							<td>
								${fn:substring(row.st_date,4,6)}월
							</td>
						</c:forEach>
					</tr>
					<tr>
						<td>
							비장애인주차
						</td>
						<c:forEach var="row" items="${statsByMonth}">
							<c:if test="${row.st_cd == '1'}" >
								<td>	
									${row.st_cnt}
								</td>
							</c:if>
						</c:forEach>
					</tr>
					<tr>
						<td>
							장애인 비등록차량
						</td>
						<c:forEach var="row" items="${statsByMonth}">
							<c:if test="${row.st_cd == '2'}">
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
	
</body>
<!-- 
</html>
-->