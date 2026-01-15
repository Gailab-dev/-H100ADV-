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
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%= session.getMaxInactiveInterval() %>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
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


<script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
<script src="https://d3js.org/d3.v5.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.js"></script>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<script>
  <c:if test="${not empty errorMsg}">
    alert('<c:out value="${errorMsg}" />');
  </c:if>
</script>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<%--
<script>
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
    document.ready(function(){
    	buildStatsTable();
    });
    
  });
</script>
--%>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<%--  전역 변수 선언부 --%>
<script>
	// ✅ 전역 통계 데이터 배열
	window.statsByMonth = [
	  <c:forEach var="row" items="${statsByMonth}" varStatus="s">
	  {
	    stDate: '${row.st_date == null ? "" : row.st_date}',
	    stCd: ${row.st_cd},
	    stCnt: ${row.st_cnt == null ? 0 : row.st_cnt}
	  }<c:if test="${!s.last}">,</c:if>
	  </c:forEach>
	];
	
	// ✅ 상태 코드
    window.statusMap = {
        1: '미등록차량',
        // 2: '장애인미탑승',
        // 3: '스티커 불법 사용',
        4: '위험상황',
        5: '물건적재',
        6: '이중주차'
    };
	
</script>
<%--  전역 변수 선언부 --%>

<script>
	
	console.log("statsByMonth : " + window.statsByMonth);

	$(document).ready(function () {
		
		console.log(document.querySelectorAll('#statsTable').length);
		
		// 데이터가 없는 경우 빈 표 표시
		if (!window.statsByMonth || window.statsByMonth.length === 0) {
		    document.getElementById('statsTable').innerHTML =
		        '<tr><td style="text-align:center;">조회된 데이터가 없습니다.</td></tr>';
		    return;
		}
		
		// 차트 초기화
		d3.select("#chart").html("");
		
	    // 1️⃣ x축 날짜 목록 (중복 제거)
	    const xLabels = [...new Set(window.statsByMonth.map(d => d.stDate))];
	    
	    // 2️⃣ 상태 코드 목록

	    // 3️⃣ 각 상태코드 별 y 데이터 생성
    	const dataMatrix = {};

        Object.keys(window.statusMap).forEach(cd => {
            dataMatrix[cd] = {};
            xLabels.forEach(date => {
                dataMatrix[cd][date] = 0;
            });
        });
        
        window.statsByMonth.forEach(d => {
        	const cd = Number(d.stCd);
            if (dataMatrix[cd]) {
                dataMatrix[cd][d.stDate] = d.stCnt;
            }
        });
		
		
		// 5️⃣ 차트 생성
		// 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가
		
	    const xData = ['x', ...xLabels.map(d => d.substring(5, 7) + '월')];

	    const yColumns = Object.keys(window.statusMap).map(cd => {
	        return [
	            'data' + cd,
	            ...xLabels.map(date => dataMatrix[cd][date])
	        ];
	    });
	    
		console.log("xData : " + xData);
		console.log("yColumns : " + yColumns);
		
		let chart = c3.generate({
			bindto:'#chart', // 바인팅할 html 태그의 id
		    data: {  // 데이터에 관한 속성값
		        x: 'x', // x축 데이터를 식별하는 식별자
		        columns: [  // 각 컬럼별 배열
		        	xData,
		        	...yColumns,
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
		
	   	/** =========================
	     *  테이블 생성
	     * ========================= */

		buildStatsTable();

	})
	
	// 검색 조건에 따른 검색
	window.searchStatistics = function(pageNo){
		
		let form = document.getElementById('StatsSearchForm');
	  	const startDate = form.elements['startDate']?.value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate']?.value;
	  	let stCd = form.elements['stCd']?.value;
	  	stCd = stCd ? Number(stCd) : null;
	 	const pageSize = document.getElementById('pageSize')?.value;
	  	
		
		if(startDate != null && endDate != null && startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
	  	// 검색 파라미터 변경으로 인한 페이지 번호 1로 변경
	  	pageNo = Math.max(1, Number.isFinite(+pageNo) ? Math.trunc(+pageNo) : 0);
		
		location.href = "viewStat.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&stCd=" + stCd +"&pageSize="+pageSize;
		
	}
	
	// 통계 데이터를 통한 테이블 재생성
	function buildStatsTable(){
	     const months = [...new Set(window.statsByMonth.map(d => d.stDate).filter(d => d))].sort();
			
	   	 console.log("months : " + months);
	   	
	     const thead = document.querySelector('#statsTable thead');
	     let headHtml = "<tr><th>유형</th>";

	     months.forEach(d => {
	    	 
	    	console.log("d : " + d);	 
	    	console.log(d.slice(5,7) + "월");
	    	
	    	//headHtml += `<th>${String(d).substring(5,7)}월</th>`;
	        headHtml += "<th>" + d.slice(5,7) + "월</th>";
	     });

	     headHtml += '</tr>';
	     thead.innerHTML = headHtml;
	     
	     const tbody = document.querySelector('#statsTable tbody');
	     tbody.innerHTML = '';

	     Object.keys(window.statusMap).forEach(cd => {
	        	 
	    	 let row = "<tr><td>" + statusMap[cd] + "</td>";

	       months.forEach(date => {
	    	   
	    	 console.log("date : " + date);
	    	 
	    	 console.log("cd : " + cd);
	    	 
	         const item = window.statsByMonth.find(
	           d => d.stDate === date && Number(d.stCd) === Number(cd)
	         );
	         
	         console.log("item : " + item);
	         
	         console.log("item.stCnt : " + item.stCnt);
				
	         // row += `<td>${item ? item.stCnt : 0}</td>`;
	         // row += `<td>${item.stCnt}</td>`;
	         // row += `<td>${item && item.stCnt != null ? item.stCnt : 0}</td>`;
	         row += "<td>" + (item ? item.stCnt : 0) + "</td>";
	       });

	       row += '</tr>';
	       tbody.innerHTML += row;
	     });
	}
	
</script>
<body>
	<div class=page-wrapper>
	<!-- 헤더 -->
	<header class="header">
	  <div class="logo">
	    <img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
	         alt="GAILAB" class="header-icon">
	  </div>
	
	  <div class="right-group">
  	  	<c:if test="${useTblLog == false}">
			<div class="alert alert-warning">
		    	현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.
		    </div>
		</c:if>
	    <div class="user">
	      <img src="${pageContext.request.contextPath}/resources/images/user.png"
	           alt="유저" class="user-image">
	      <span class="user-name">hskim</span>
	    </div>
	    <div class="logout">
	      <button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
	    </div>
	  </div>
	</header>
    <div class="container">
        <aside class="sidebar">
            <ul class="menu">
            	<li><a href="${pageContext.request.contextPath}/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
                <li><a href="${pageContext.request.contextPath}/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">통계</a></li>
                <li><a href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
            </ul>
        </aside>    
    	<div class="content">
    		<div class="title-box">
    			<h1>월별 불법주차 현황(1년)</h1>
    			<button type="submit" class="excel-btn" title="엑셀 다운로드">
    				<img src="${pageContext.request.contextPath}/resources/images/icon_excel.svg" alt="엑셀 다운로드">
    			</button>
    		</div>    	
			<form id="StatsSearchForm" class="filter-form">
				<div class="filter-input-group">
					<input type="date" name="startDate" value="${startDate}" />
				</div>
				<p class="date-contect">~</p>
				<div class="filter-input-group">
					<input type="date" name="endDate" value="${endDate}" />
				</div>
				<div class="filter-input-group search-field">
					<select name="stCd">
						<option value="" ${stCd == null ? 'selected' : '' }>유형</option>
						<option value="1" ${stCd == 1 ? 'selected' : ''}>미등록차량</option>
						<%-- 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가 --%>
						<%-- 
						<option value="2" ${stCd == 2 ? 'selected' : ''}>불법주차(장애인미탑승)</option>
						<option value="3" ${stCd == 3 ? 'selected' : ''}>스티커 불법 사용</option>
						 --%>
						<option value="4" ${stCd == 4 ? 'selected' : ''}>위험상황</option>
						<option value="5" ${stCd == 5 ? 'selected' : ''}>물건적재</option>
						<option value="6" ${stCd == 6 ? 'selected' : ''}>이중주차</option>
					</select>
				</div>
				<div class="filter-input-group">
					<select id="pageSize" name="pageSize" onchange="searchEventList()">
						<option value="" disabled ${empty pageSize ? 'selected' : ''}>갯수</option>
        				<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩 보기</option>
        				<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩 보기</option>
        				<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩 보기</option>
    				</select>
				</div>
				<button type="button" class="search-btn" onclick="searchStatistics('${paginationInfo.currentPageNo != null ? paginationInfo.currentPageNo : 1}')">조회</button>
			</form>
    	
    		
			<div class ="graph-group">
				<!-- 장애인, 비장애인 별 이벤트 발생 현황(라인 그래프) -->
				<div id="chart" class="graph-table" style="height: 402px;">
					<p class="subTitle">불법주차 유형별 통계(그래프 )</p>
				</div>
				
				<div class="graph-table">
					<p class="subTitle">불법주차 유형별 통계(테이블)</p>
					<!-- 불법주차 유형별 통계(테이블) -->
					<table id="statsTable">
					    <thead></thead>
    					<tbody></tbody>
					</table>
				</div>
			</div>
			</div>
    	</div>
    </div>
</body>
</html>