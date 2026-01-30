<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<!-- STATS_JSP_VERSION: 2026-01-16_0935 -->

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
 <link href="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.css" rel="stylesheet">
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

<script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
<script src="https://d3js.org/d3.v5.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.js"></script>
<script
	src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>
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
	    stCd: ${row.st_cd == null ? 0 : row.st_cd},
	    
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
	
	$(document).ready(function () {
		
		console.log("statsByMonth:", window.statsByMonth);
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
		
	    const xData = ['x', ...xLabels.slice(0, 12).map(d => d.substring(0, 4) + '.' + d.substring(5, 7))];

	    const yColumns = Object.keys(window.statusMap).map(cd => {
	        return [
	            'data' + cd,
	            ...xLabels.slice(0,12).map(date => dataMatrix[cd][date])
	        ];
	    });
	    
		console.log("xData : " + xData);
		console.log("yColumns : " + yColumns);
		
		let chart = c3.generate({
			bindto:'#chart', // 바인팅할 html 태그의 id
			size:{
				width:1533,
				height:321.6
			},
		    data: {  // 데이터에 관한 속성값
		    	 //  x: 'x',x축 데이터를 식별하는 식별자
		        columns: [  // 각 컬럼별 배열
		        	//xData,
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
		    		type: 'indexed', 
		    		tick: {
		    			format: function(d) {
		    		        const labels = xLabels.slice(0, 12).map(date => 
		    		            date.substring(0, 4) + '.' + date.substring(5, 7)
		    		        );
		    		        return labels[d] || '';
		    		    },
		    			culling: false,
		    			fit: true,  
		                count: 12      // ✅ tick 개수 명시
		    		},
		    		padding:{
		    			left:0.1,
		    			right:0.025
		    		},
		    		extent: [0, 11] 
		    	},
		    	y : {
		    		show: true ,
		    		min: 0,
		    		max:100,
		    		tick:{
		    			values:[0,25,50,75,100],
		    	 outer: false,
		    		},
		    		padding:{
		    			top:0.05,
		    			bottom:0
		    			
		    		}, 		    		
		    	}
		    },
		    grid: {  
		    	x:{show:true},
    	        y: {
    	            show: true,
    	            lines: [
    	            	{value: 25, class: 'grid-25'},  // 클래스 추가 가능
    	                {value: 50, class: 'grid-50'},
    	                {value: 75, class: 'grid-75'}
    	            ]
    	        }
    	    },
		    legend: {
		    	position: 'right'
		    },
		    padding: {
		        right: 150,
		        
		    },
		    line: {
		        connectNull: true
		    },
		    tooltip: {
		    	show: true,
		        grouped: false,  // 여러 시리즈 함께 보기
		        contents: function(d, defaultTitleFormat, defaultValueFormat, color) {
		            const labels = xLabels.slice(0, 12).map(date => 
		                date.substring(0, 4) + '.' + date.substring(5, 7)
		            );
		            
		            let html = '<div class="custom-tooltip">';
		            html += '<div class="tooltip-header">' + labels[d[0].index] + '</div>';
		            html += '<div class="tooltip-grid">';
		            
		            d.forEach(function(item) {
		                const bgColor = color(item.id);
		                html += '<div class="tooltip-item">';
		                html += '<span class="color-box" style="background-color:' + bgColor+ ';"></span>';
		                html += '<span class="item-name">' + item.name + '</span>';
		                html += '<span class="item-value">' + item.value + '</span>';
		                html += '</div>';
		            });
		            
		            html += '</div></div>';
		            return html;
		        }
		    },
		    color: {
		        pattern: ['#21B5B3', '#4993AA','#7172A2','#995099','#8ac4ff']  // 비장애인, 장애인 선 색상 지정
		    },
		});
		
	   	/** =========================
	     *  테이블 생성
	     * ========================= */

		buildStatsTable();

	})
	
	// 검색 조건에 따른 검색
	window.searchStatistics = function(){
		
		let form = document.getElementById('StatsSearchForm');
	  	const startDate = form.elements['startDate']?.value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate']?.value;
	  	let stCd = form.elements['stCd']?.value;
	  	stCd = stCd ? Number(stCd) : "";
	  	
		
		if(startDate != null && endDate != null && startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
		// 검색 파라티터 설정
	    const params = new URLSearchParams();
		  if (startDate) params.set('startDate', startDate);
		  if (endDate)   params.set('endDate', endDate);

		  // stCd가 숫자일 때만 붙임
		  if (stCd !== "") params.set('stCd', String(Number(stCd)));
		  
		  // location.href = `viewStat.do?${params.toString()}`;
	
		  console.log(params);
		  location.href = "viewStat.do?" + params;
		
		// location.href = "viewStat.do?startDate=" + startDate + "&endDate=" + endDate + "&stCd=" + stCd;
		
	}
	
	// 통계 데이터를 통한 테이블 재생성
	function buildStatsTable(){
	     const months = [...new Set(window.statsByMonth.map(d => d.stDate).filter(d => d))].sort();
			
	   	 console.log("months : " + months);
	   	
	     const thead = document.querySelector('#statsTable thead');
	     let headHtml = "<tr><th></th>";

	     months.forEach(d => {
	    	 
	    	console.log("d : " + d);	 
	    	console.log(d.slice(0,4) + "." + parseInt(d.slice(5,7)));
	    	
	    	headHtml += "<th>" + d.slice(0,4) + "." + parseInt(d.slice(5,7)) + "</th>";
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
	
	// --------------------------- 엑셀 다운로드 -----------------------------
	
	/**
	 @opt
		endpoint: url 경로(contextPath는 고정)
	    formSelector: form Id
	    mapping : form 하위의 input 태그의 name 속성값 또는 #id 값을 json 형식으로 입력
	    예)
	    responseType: 함수 실행 결과를 받을 데이터 타입(기본값:blob)
		downloadFilename: 엑셀 파일명
	*/
	document.addEventListener('DOMContentLoaded', function () {
		document.getElementById('btnExcel').addEventListener('click',function(){
			ExcelDownloader.excelDownload({
				endpoint:'/stats/excelDownload',
				formSelector:'#StatsSearchForm',
				mapping: {
					startDate:'startDate',
					endDate:'endDate',
					stCd:'stCd'
				},
				responseType:'blob',
				downloadFilename:'불법주차_월별_통계현황.xlsx'
			}).catch(function(e){alert(e.message);});
		})
	});

	
	/*
	async function excelDownload(){
		
		
		
		let form = document.getElementById('StatsSearchForm');
	  	let val1 = form.elements['stCd']?.value;
	  	let stCd = encodeURIComponent(val1);
	  	let val2 = form.elements['startDate']?.value;
	  	let startDate = encodeURIComponent(val2);
	  	let val3 = form.elemntes['endDate']?.value;
	  	let endDate = encodeURIComponet(val3);
	  	let pageSize = document.getElementById('pageSize')?.value;
		
		const body = {
				'startDate': startDate,
				'endDate': endDate,
				'stCd':stCd
			};
			
			try{
		    	const response = await fetch('${pageContext.request.contextPath}/deviceList/excelDownload', {
		      		method: 'POST'
		      		, headers: { 'Content-Type': 'application/json' }
		      		, body: JSON.stringify(body)
		      		, credentials : 'same-origin'
		      		, cache:'no-store'
		    		});
		    	
		    	// fetch는 항상 response 객체로 리턴
		    	if (!response.ok) return;
				
		    	// response에서 json값 가져오기
		    	let data = await response.json();
		    	await sleep(2000);
		    	
		    	return;
			}catch(e){
				return;
			}

	}
	*/
	// --------------------------- 엑셀 다운로드 -----------------------------

	
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
				 	<span class="user-name">
				 		<c:out value="${uName}" escapeXml="true" />
			 		</span>
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
					<li><a
						href="${pageContext.request.contextPath}/myInfo/viewMyInfo.do">
							<svg width="20" height="20" viewBox="0 0 12 12" fill="none"
								xmlns="http://www.w3.org/2000/svg">
								<circle cx="6" cy="6" r="5.5" stroke="currentColor" />
								<path
									d="M9.33335 9.75V8.91667C9.33335 8.47464 9.15776 8.05072 8.8452 7.73816C8.53264 7.4256 8.10871 7.25 7.66669 7.25H4.33335C3.89133 7.25 3.4674 7.4256 3.15484 7.73816C2.84228 8.05072 2.66669 8.47464 2.66669 8.91667V9.75M7.66669 3.91667C7.66669 4.83714 6.92049 5.58333 6.00002 5.58333C5.07955 5.58333 4.33335 4.83714 4.33335 3.91667C4.33335 2.99619 5.07955 2.25 6.00002 2.25C6.92049 2.25 7.66669 2.99619 7.66669 3.91667Z"
									stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" />
							</svg> 내 정보
					</a></li>



					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<div class="content">
				<div class="title-box">
					<h1>월별 불법주차 현황(1년)</h1>
					<button id="btnExcel" type="button" class="excel-btn"
						title="엑셀 다운로드">
						<img
							src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
							alt="엑셀 다운로드">
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
					<div class="filter-input-group">
						<select name="stCd">
							<option value="" ${stCd == null ? 'selected' : '' }>유형</option>
							<option value="1" ${stCd == '1' ? 'selected' : ''}>미등록차량</option>
							<%-- 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가 --%>
							<%-- 
						<option value="2" ${stCd == '2' ? 'selected' : ''}>불법주차(장애인미탑승)</option>
						<option value="3" ${stCd == '3' ? 'selected' : ''}>스티커 불법 사용</option>
						 --%>
							<option value="4" ${stCd == '4' ? 'selected' : ''}>위험상황</option>
							<option value="5" ${stCd == '5' ? 'selected' : ''}>물건적재</option>
							<option value="6" ${stCd == '6' ? 'selected' : ''}>이중주차</option>
						</select>
					</div>
					<button type="button" class="search-btn"
						onclick="searchStatistics()">조회</button>
				</form>


				<div class="graph-group">
					<!-- 장애인, 비장애인 별 이벤트 발생 현황(라인 그래프) -->
					<div class="graph-table">
						<p class="subTitle">불법주차 유형별 통계(그래프)</p>
						<div id="chart" ></div>
					</div>

					<div class="graph-table">
						<p class="subTitle">불법주차 유형별 통계(테이블)</p>
						<!-- 불법주차 유형별 통계(테이블) -->
						<table id="statsTable" class="stats-table">
							<thead class="tableTitle"></thead>
							<tbody></tbody>
						</table>

					</div>
				</div>
			</div>
		</div>
</body>
</html>