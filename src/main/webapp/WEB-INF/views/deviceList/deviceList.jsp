<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 
 
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>diviceList</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/deviceList.css">
	<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
	<script
  src="https://code.jquery.com/jquery-3.7.1.js"
  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
  crossorigin="anonymous"></script>
  
	<script>
			
	    const table = document.getElementById('boardTable');
	    const countEl = document.getElementById('selectedCount');
	    const btnClear = document.getElementById('btnClear');
	    const btnDelete = document.getElementById('btnDelete');
	
	    // 아코디언 토글 기능: 정상작동하도록 유지
	    document.addEventListener('DOMContentLoaded', () => {
	        const accordions = document.getElementsByClassName("accordion");
	        for (let acc of accordions) {
	            acc.addEventListener("click", function () {
	                this.classList.toggle("active");
	                const content = this.nextElementSibling;
	                content.style.display = content.style.display === "block" ? "none" : "block";
	            });
	        }
	    });
		
		
	 // -------------------------------- pagination 활용한 페이지 이동 ----------------------------
	    
		// 디바이스 및 주소 검색
		window.searchDeviceList = function(pageNo){
			
			let form = document.getElementById('deviceListSearchForm');
		  	const searchKeyword   = form.elements['searchKeyword'].value;
		  	
		  	if( searchKeyword.length >= 100 ){
		  		alert("검색어는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
			
			location.href = "viewDeviceList.do?page=" + pageNo + "&searchKeyword=" + searchKeyword;
			
		}
		
		// pagination 객체를 활용한 페이지 이동
		window.goPage = function(pageNo){
	    	let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
			location.href = "viewDeviceList.do?page=" + pageNo + "&searchKeyword=" + searchKeyword;
		}
		
		//  Pagination 
		document.addEventListener('DOMContentLoaded', function () {
			  const $wrap = document.querySelector('.pagination');
			  if (!$wrap) return;

			  const links = Array.from($wrap.querySelectorAll('a'));
			  const current = $wrap.querySelector('strong'); 
			  const curPage = current ? parseInt(current.textContent.trim(), 10) : NaN;

			  // 유틸: goPage(숫자)에서 숫자만 뽑기
			  const getPageFromHref = (a) => {
			      const href = a.getAttribute('href') || '';
			      const m = href.match(/goPage\(\s*'?(\d+)'?\s*\)/);
			      return m ? parseInt(m[1], 10) : null;
			  };

			  // 이동 버튼 텍스트 치환 및 클래스 세팅
			  links.forEach(a => {
			    const txt = a.textContent.replace(/\s+/g,'').trim();
			    const page = getPageFromHref(a);

			    if (/\[처음\]/.test(txt)) {
			      a.textContent = '«';
			      a.classList.add('pg-first');
			      if (curPage && curPage <= 1) a.classList.add('is-disabled');
			    } else if (/\[이전\]/.test(txt)) {
			      a.textContent = '‹';
			      a.classList.add('pg-prev');
			      if (curPage && curPage <= 1) a.classList.add('is-disabled');
			    } else if (/\[다음\]/.test(txt)) {
			      a.textContent = '›';
			      a.classList.add('pg-next');
			      // 다음이 마지막을 넘어가면 비활성
			      if (curPage && page && page <= curPage) a.classList.add('is-disabled');
			    } else if (/\[마지막\]/.test(txt)) {
			      a.textContent = '»';
			      a.classList.add('pg-last');
			      // 마지막 페이지 계산이 어려우니 “goPage(n)” 값이 현재와 같거나 작으면 비활성
			      if (curPage && page && page <= curPage) a.classList.add('is-disabled');
			    } else {
			      // 숫자 링크는 그대로 두되 불필요한 공백 제거
			      if (/^\d+$/.test(txt)) a.textContent = txt;
			    }
			  });
			});
		
		// -------------------------------- pagination 활용한 페이지 이동 ----------------------------
		
		// ----------------------------- 디바이스 리스트에서 리스트 복수 선택, 갱신 -------------------
		
	    // 전체 선택 해제
	    function clearAllSelection() {
	      table.querySelectorAll('tbody .row-check:checked').forEach(cb => cb.checked = false);
	      updateSelectedCount();
	    }
	    
	    // 공통: 선택 수 갱신
	    function updateSelectedCount() {
	      const checked = table.querySelectorAll('tbody .row-check:checked').length;
	      countEl.textContent = `${checked}개 선택됨`;
	      btnDelete.disabled = checked === 0; // 아무것도 없으면 삭제 비활성화(선택)
	    }

	    // 행 체크박스 변경(실시간 카운트 갱신) - 이벤트 위임
	    table.addEventListener('change', (e) => {
	      if (e.target.classList.contains('row-check')) {
	        updateSelectedCount();
	      }
	    });

	    // 버튼 핸들러 바인딩
	    btnClear.addEventListener('click', clearAllSelection);
	    btnDelete.addEventListener('click', deleteSelectedRows);

	    // 초기 상태 동기화
	    updateSelectedCount();
	    
	 // ----------------------------- 디바이스 리스트에서 리스트 복수 선택, 갱신 -------------------------
	    
		// -----------------------------  디바이스 삭제 팝업 ------------------------------------------
		
	    // 디바이스 삭제 팝업
		function viewDeleteDevicePopup(){
			
			axios.post('/deviceList/viewDeleteDevicePopup')
			.then(function(r){
				console.log(r);
				
				let rtDiv = document.getElementById("deleteDeivcePopup");
				
				rtDiv.innerHTML = r.data;
				
				rtDiv.style.display = 'block';
				
			})
			.catch(function(error) {
				console.log(error);
			})
		}
		
	    // 삭제 버튼 클릭 
	    function deleteSelectedRows() {
			
	    	const table = document.getElementById('deviceTable');
	    	const checkedRows = Array.from(table.querySelectorAll('tbody .row-check:checked'))
	        .map(cb => cb.closest('tr'));
		      if (checkedRows.length === 0) return;
	
		      const dvIds = checkedRows.map(tr => tr.getAttribute('data-dv-id')); // 서버에 보낼 PK들
		      console.log('삭제 요청 보낼 dvIds:', dvIds);
				
				axios.post('/deviceList/deleteDevicePopup',{
					dvIds : dvIds,
				})
				.then(function(r){
					
					console.log(r);
					
					if(r.ok){
						removeDeletePopup();
						
					}else{
						alert(r.msg);
					}
					
				})
				.catch(function(e) {
					console.log(e);
				})
	    }
	    
	    // 삭제 팝업 삭제
	    function removeDeletePopup() {
	    	let rdDiv = document.getElementById("deletedevicePopup");
	    	rdDiv.innerHTML = "";
	    	rdDiv.style.display = 'none';
	    	location.reload();
	    }
	    
	 // ------------------------------------- 디바이스 삭제 팝업 ------------------------------------------


	    
	    // -------------------------------- 디바이스 등록, 수정 ------------------------------
	    
	    // 디바이스 정보 팝업 열기
		function viewDeviceInfoPopup(dvId){
			axios.post('/deviceList/viewDeviceInfoPopup',{
				dvId : dvId
    		})
    		.then(function(r)){
    			console.log(r);
    			
				let riDiv = document.getElementById("deviceInfoPopup");
				
				riDiv.innerHTML = r.data;
				
				riDiv.style.display = 'block';
    		}
    		.error(function(e)){
    			console.log(e);
    		}
	    }
	 
    	// 디바이스 수정
    	function updateDeviceInfo(dvId){
    		
    		let dvName = document.getElementById("dvName").value;
    		if(dvName == null || dvName == undefined || dvName == ""){
    			alert("디바이스명은 필수입니다.");
    			return;
    		}
    		let dvAddr = document.getElementById("dvAddr").value;
    		if(dvAddr == null || dvAddr == undefined || dvAddr == ""){
    			alert("주소는 필수입니다.");
    			return;
    		}
    		let dvIp = document.getElementById("dvIp").value;
    		if(dvIp == null || dvIp == undefined || dvIp == ""){
    			alert("ip는 필수입니다.");
    			return;
    		}
    		
    		axios.post('/deviceList/updateDeviceInfo',{
    			new URLSearchParams(dvId : dvid
    			, dvName : dvName
    			, dvAddr : dvAddr
    			, dvIp : dvIp)
    		})
    		.then(function(r)){
    			console.log(r);
    			if(r.data?.ok){
    				removeDeviceInfoPopup();
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		}
    		.error(function(e)){
    			console.log(e);
    			alert("수정 중 오류가 발생했습니다.");
    		}
    	}
    	
    	// 디바이스 등록
    	function insertDeviceInfo(){
    		
    		let dvName = document.getElementById("dvName").value;
    		if(dvName == null || dvName == undefined || dvName == ""){
    			alert("디바이스명은 필수입니다.");
    			return;
    		}
    		let dvAddr = document.getElementById("dvAddr").value;
    		if(dvAddr == null || dvAddr == undefined || dvAddr == ""){
    			alert("주소는 필수입니다.");
    			return;
    		}
    		let dvIp = document.getElementById("dvIp").value;
    		if(dvIp == null || dvIp == undefined || dvIp == ""){
    			alert("ip는 필수입니다.");
    			return;
    		}
    		
    		axios.post('deviceList/insertDeviceInfo',{
    			new URLSearchParams(dvName : dvName
    			, dvAddr : dvAddr
    			, dvIp : dvIp)
    		})
    		.then(function(r)){
    			console.log(r);
    			
    			if(r.data?.ok){
    				removeDeviceInfoPopup();
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		}
    		.error(function(e)){
    			console.log(e);
    			alert("등록 중 오류가 발생했습니다.");
    		}
    	}
    	
    	// 디바이스 등록, 수정 팝업창 닫기
    	function removeDeviceInfoPopup(){
			diDiv = document.getElementById("deviceInfoPopup");
			diDiv.innerHTML = "";
			diDiv.style.display = none;
			location.reload();
    	}
	    	
    	// -------------------------------- 디바이스 등록, 수정 ------------------------------
    	
	 	    
	    // ---------------------------- 실시간 영상 팝업 -------------------------------
	    
	    // 실시간 영상 팝업
		function viewRealTimeVideoPopup(dvId){
			axios.post('/deviceList/viewRealTimeVideo',{
				dvId : dvId,
			})
			.then(function(r){
				console.log(r);
				
				let rtDiv = document.getElementById("realTimeVideoPopup");
				
				rtDiv.innerHTML = r.data;
				
				rtDiv.style.display = 'block';
				
			})
			.catch(function(e) {
				console.log(e);
			})
		}
		
		// ---------------------------- 실시간 영상 팝업 -------------------------------   
	 
	  	
    </script>
</head>
<body>
	<!-- 헤더 -->
    <header class="header">
        <div class="logo">
        	<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
        </div>
        <div class="user">
        	<img src="${pageContext.request.contextPath}/resources/images/user.png" alt="유저" class="user-image">
        	<span class="user-name">hskim</span>
        </div>
        <div class="logout">
        	<button onclick="location.href = '/gov-disabled-web-gs/stats/logout'">
        		로그아웃
        	</button>
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
            <!--  
            <div class="device-navi">
                <h3>디바이스 리스트</h3>
				<c:forEach var="addr" items="${groupAddrByDeviceList}">
				    <button class="accordion">
				        <span class="accordion-label">${addr.key}</span>
				        <span class="accordion-arrow">&#9662;</span> <%-- ▼ (열림 표시) --%>
				    </button>
				    <div class="accordion-content">
				        <ul>
				            <c:forEach var="device" items="${addr.value}">
				                <li class="device-item" >
				                	<a href="javascript:void(0);" onclick="deviceBtnClick('start','${device.dv_id}')">${device.dv_name}</a>
				                </li>
				            </c:forEach>
				        </ul>
				    </div>
				</c:forEach>
            </div>
            -->
			<main class="main">
				<h1>실시간 영상</h1>	
			    <!-- 
			    <div class="video-controller-group">
				    <video id="video" width="720" controls autoplay>
				    	<source src="https://www.geyeparking.shop/index.m3u8" type="application/x-mpegURL">
				    </video>
					
					// 디바이스 컨트롤러 
					  
				    <div class="controller-center-wrapper">
				        <div class="controller-wrapper">
				            <div class="controller-button up" onclick="tiltingBtnClick('U')">▲</div>
				            <div class="controller-button left" onclick="tiltingBtnClick('L')">◀</div>
				            <div class="controller-center" onclick="deviceBtnClick('stop')">⏸</div>
				            <div class="controller-button right" onclick="tiltingBtnClick('R')">▶</div>
				            <div class="controller-button down" onclick="tiltingBtnClick('D')">▼</div>
				        </div>
				    </div>
				    
				</div>
				 -->
				<!-- 컨트롤러 버튼 -->
				<!-- 
			    <div class="controller-buttons">
			        <button onclick="tiltingBtnClick('zoomIn')">zoomIn</button>
			        <button onclick="tiltingBtnClick('zoomOut')">zoomOut</button>
			    </div>
			     -->
			     
			     <!-- 디바이스 리스트 -->
			     <div>
			     	<div>
			     		<button>+ 디바이스 등록</button>
				     	<form id="deviceListSearchForm">
				     		<button class="search-btn" onclick="searchDeviceList()"> </button>
				     		<input type="text" name="searchKeyword" value="${searchKeyword}" placeholder="디바이스명 및 주소 검색">
				     	</form>
			     	</div>
					<div>
						<input type="checkbox">
						
						<button type="button" onclick="viewDeleteDevicePopup()"> 삭제 버튼</button>
					</div>
					<table id="deviceTable" class="event-table">
						<thead>
							<tr>
								<th><input type="checkbox" id="checkAllHeader" /></th>
								<th>디바이스명</th>
								<th>디바이스주소</th>
								<th>디바이스상태</th>
								<th>실시간영상</th>
								<th>디바이스수정</th>
							</tr>
						</thead>
						<tbody>
							<c:forEach var="item" items="${deviceList}">
								<tr data-dv-id="${item.dv_id}">
									<td>
										<input type="checkbox" class="row-check" />
									</td>
									<td>${item.dv_name}</td>
									<td>${item.dv_addr}</td>
									
									<td>
										<c:choose>
											<c:when test="${item.dv_status eq 0}">OFF</c:when>
											<c:when test="${item.dv_status eq 1}">ON</c:when>
										</c:choose>
									</td>
									<!-- 추후 고도화 시 이렇게 가야 함, 지금은 위에 것으로 해주기 
									<td>
										<c:choose>
											<c:when test="${item.dv_status eq 0}">Jetson 통신 불가</c:when>
											<c:when test="${item.dv_status eq 1}">정상 </c:when>
											<c:when test="${item.dv_status eq 2}">CCTV 통신 불가</c:when>
											<c:when test="${item.dv_status eq 3}">전광판 통신 불가</c:when>
											<c:when test="${item.dv_status eq 4}">알림소리 통신 불가</c:when>
											<c:when test="${item.dv_status eq 5}">안전버튼 통신 불가</c:when>
										</c:choose>
									</td>
									 -->
									<td>
										<button type="button" onclick="viewRealTimeVideoPopup(${item.dv_id})"> 📽 </button>
									</td>
									<td><button type="button" onclick="viewDeviceInfoPopup(${item.dv_id})"> 수정 </button></td>
								</tr>
							</c:forEach>
						</tbody>
					</table>
					<div class="pagination">
						<ui:pagination paginationInfo="${paginationInfo}" type="text" jsFunction="goPage"/>
					</div>
					
					<!-- 실시간 영상 버튼 클릭시 위 div 하단에 팝업 창 -->
					<div id="realTimeVideoPopup" style="display:none">
					
					</div>
					
					<!-- 수정 버튼 클릭시 위 div 하단에 팝업 창 -->
					<div id="deviceInfoPopup" style="display:none">
					
					</div>
					
					<!-- 삭제 버튼 클릭시 위 div 하단에 팝업 창 -->
					<div id="deletedevicePopup" style="display:none">
					
					</div>
					
			     </div>
			     
			</main>
		</div>
	</div>	
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>