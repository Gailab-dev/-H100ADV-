<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!-- 
<!DOCTYPE html>
<html>
 -->
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<style>
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
		d3.select("#chart").html("");
		
		let xData = ['x' 
				<c:forEach var="row" items="${statsByMonth}">
					, '${row.st_date}'
				</c:forEach>
			];
		let yData = ['data1' 
			<c:forEach var="row" items="${statsByMonth}">
				, ${row.st_cnt}
			</c:forEach>
			];
		
		
		console.log(xData);
		console.log(yData);
		console.log(typeof xData[1]);
		console.log(typeof yData[1]);
		
		let xTest = ['x','1','2','3'];
		let yTest = ['data1',100,200,150];

		console.log(xTest);
		console.log(yTest);
		console.log(typeof xTest[1]);
		console.log(typeof yTest[1]);
		
		let chart = c3.generate({
			bindto:'#chart',
		    data: {
		        x: 'x',
		        columns: [
		        	xData,
		        	yData
		        ],
		        type:'line',
		        names :{
		        	data1: '비장애인주차'
		        }
		    },
		    area: {
		    	show: false
		    },
		    /*
		    color: {
		    	pattern: ['#f1392c','#27ec58']
		    },
		    point: {
		    	show: true,
		    	r: 3
		    } ,
		    */
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
	<div id="chart" style="width: 50%; height: 400px;">
		
	</div>
</body>
<!-- 
</html>
-->