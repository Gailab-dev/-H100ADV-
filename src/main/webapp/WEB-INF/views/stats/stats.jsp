<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<!-- STATS_JSP_VERSION: 2026-01-16_0935 -->

<%-- [Tiles fragment] 공용 chrome(헤더/사이드바/푸터)은 defaultLayout 제공. 이하 이 페이지 전용 CSS/JS/콘텐츠 --%>
<meta charset="UTF-8">
 <link href="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.css" rel="stylesheet">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/stats.css?v=20260707">
<%-- patches 2026-07-07: 외부 CSS 캐시 대비 인라인 보정 — .page-wrapper 고정 height(100vh) 제거 →
     콘텐츠가 길어도 사이드바가 하단(푸터)까지 이어지도록(다른 화면과 동일) --%>
<%-- patches 2026-07-09: 디자이너 피드백 — 그래프/테이블 세로 축소로 오른쪽 스크롤 제거.
     외부 CSS(stats.css #chart:504px) 캐시 대비 인라인 !important 로 확실히 덮어씀 --%>
<style>
	/* patches 2026-07-09(2): 인라인 .page-wrapper{min-height:100vh} 제거.
	   사이드바 하단 연장은 바깥 page-wrapper(layout.css, 100vh)가 담당. 본문 내부 page-wrapper 를 100vh 로
	   두면 헤더 높이만큼 뷰포트 초과 → 하단 여백/스크롤 발생. → template.jsp 전역 규칙(.content .page-wrapper{min-height:0})에 위임 */
	#chart{ height:260px !important; }               /* 504px → 260px (c3 실제높이 250 에 맞춤, 하단 빈공간 제거) */
	.graph-group{ gap:14px !important; }
	.graph-table .subTitle{ margin:6px 0 8px !important; }
	.title-box{ margin-bottom:10px !important; }
	.stats-table th, .stats-table td{ padding:6px 8px !important; }  /* 행 높이 축소 */
</style>
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
	let chart = null;
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
		
		chart = c3.generate({
			bindto:'#chart', // 바인팅할 html 태그의 id
			size:{
				width:null,
				height:250
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

	});
	let resizeTimer;
	window.addEventListener('resize', function() {
	    clearTimeout(resizeTimer);
	    resizeTimer = setTimeout(function() {
	        if (chart) {
	            chart.flush();  // C3.js 차트 리사이즈
	        }
	    }, 250);
	});

	
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

	<div class=page-wrapper>
		<!-- 헤더 -->
		
		
			
			
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
		

