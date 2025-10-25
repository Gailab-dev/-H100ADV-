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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css">
	<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
	<script
	  src="https://code.jquery.com/jquery-3.7.1.js"
	  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
	  crossorigin="anonymous">
	</script>
	<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
	<script>
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
		

	    
		// -----------------------------  디바이스 삭제 팝업 ------------------------------------------
		
	    // 디바이스 삭제 팝업
		function viewDeleteDevicePopup(){
			
			axios.post('${pageContext.request.contextPath}/deviceList/viewDeleteDevicePopup')
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
				
				axios.post('${pageContext.request.contextPath}/deviceList/deleteDevicePopup',{
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
			axios.post('${pageContext.request.contextPath}/deviceList/viewDeviceInfoPopup', { dvId })
			.then(function(r) {
			  console.log("팝업 데이터:", r);
			  const riDiv = document.getElementById("deviceInfoPopup");
			  riDiv.innerHTML = r.data;
			  riDiv.style.display = "block";
			})
			.catch(function(e) {
			  console.error("팝업 로드 중 오류 발생:", e);
			});
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
    		
    		axios.post('${pageContext.request.contextPath}/deviceList/updateDeviceInfo',
  			    new URLSearchParams({
  			        dvId: dvId,
  			        dvName: dvName,
  			        dvAddr: dvAddr,
  			        dvIp: dvIp
  			    })
  			)
    		.then(function(r){
    			console.log(r);
    			if(r.data?.ok){
    				removeDeviceInfoPopup();
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		})
    		.error(function(e){
    			console.log(e);
    			alert("수정 중 오류가 발생했습니다.");
    		});
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
    		
    		axios.post('${pageContext.request.contextPath}/deviceList/updateDeviceInfo',
   			    new URLSearchParams({
   			        dvId: dvId,
   			        dvName: dvName,
   			        dvAddr: dvAddr,
   			        dvIp: dvIp
   			    })
   			)
    		.then(function(r){
    			console.log(r);
    			
    			if(r.data?.ok){
    				removeDeviceInfoPopup();
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		})
    		.error(function(e){
    			console.log(e);
    			alert("등록 중 오류가 발생했습니다.");
    		});
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
			axios.post('${pageContext.request.contextPath}/deviceList/viewRealTimeVideo',{
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
		
		
		// ---------------------------- 체크박스 관련 자바스크립트 -------------------------------  		
		    window.onload = function() {
        const clearSelectionBtn = document.getElementById("clearSelectionBtn"); // SVG 버튼
        const checkAll = document.getElementById("checkAll"); // 테이블 헤더 체크박스
        const rowChecks = document.querySelectorAll(".row-check"); // 각 행 체크박스
        const selectedText = document.querySelector(".selected-text");

        // ✅ 선택 개수 갱신 함수
        function updateSelectedCount() {
            const checked = document.querySelectorAll(".row-check:checked").length;
            selectedText.textContent = `\${checked}개 선택됨`;
            checkAll.checked = (checked === rowChecks.length); // 전체선택 상태 반영
        }

        // ✅ 개별 체크박스 클릭 시 갱신
        rowChecks.forEach(chk => chk.addEventListener("change", updateSelectedCount));

        // ✅ 전체선택 (표 헤더 체크박스 클릭 시)
        checkAll.addEventListener("change", function() {
            rowChecks.forEach(chk => chk.checked = checkAll.checked);
            updateSelectedCount();
        });

        // ✅ SVG 버튼 클릭 시 → 전체 해제
        clearSelectionBtn.addEventListener("click", function() {
            rowChecks.forEach(chk => chk.checked = false);
            checkAll.checked = false;
            updateSelectedCount();
        });

        // 초기 표시
        updateSelectedCount();
    };
	// ---------------------------- 체크박스 관련 자바스크립트 -------------------------------  
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
		<!-- 사이드바 -->
		<aside class="sidebar">
			<ul class="menu">
				<li><a href="/gov-disabled-web-gs/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">홈</a></li>
				<li><a href="/gov-disabled-web-gs/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
				<li><a href="/gov-disabled-web-gs/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
			</ul>
		</aside>
		
		<!-- 메인 콘텐츠 -->
		<div class="content">
			<main class="main">
				<div class="device-top">
				  
				  <!-- 첫 번째 줄: 등록 버튼 + 검색창 -->
				  <div class="top-row">
				    <button class="add-btn">+ 디바이스 등록</button>
				
				    <form id="deviceListSearchForm" class="search-box" onsubmit="searchDeviceList(); return false;">
				      <input type="text" name="searchKeyword" value="${searchKeyword}" placeholder="디바이스명 및 주소 검색">
				      <button type="submit" class="search-btn">🔍</button>
				    </form>
				  </div>
				
				  <!-- 두 번째 줄: 전체선택 / 삭제 / 선택 개수 -->
				  <div class="bulk-actions">
				    <svg width="16" height="16" viewBox="0 0 16 16" fill="none"
				         xmlns="http://www.w3.org/2000/svg">
				      <rect width="16" height="16" rx="4" fill="#6955A2"/>
				      <path d="M4 9V7H12V9H4Z" fill="white"/>
				    </svg>
				    <span class="selected-text">0개 선택됨</span>
				    <button type="button" class="delete-btn" onclick="viewDeleteDevicePopup()" title="삭제">
				      <svg width="20" height="20" viewBox="0 0 20 20" fill="none"
				           xmlns="http://www.w3.org/2000/svg">
				        <path d="M11.75 9.11111V14.4444M8.25 9.11111V14.4444M4.75 5.55556V16.2222C4.75 16.6937 4.93437 17.1459 5.26256 17.4793C5.59075 17.8127 6.03587 18 6.5 18H13.5C13.9641 18 14.4092 17.8127 14.7374 17.4793C15.0656 17.1459 15.25 16.6937 15.25 16.2222V5.55556M3 5.55556H17M5.625 5.55556L7.375 2H12.625L14.375 5.55556"
				              stroke="black" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
				      </svg>
				    </button>
				  </div>
				</div>
				
				<table id="deviceTable" class="device-table">
					<thead>
						<tr>
							<th><input type="checkbox" id="checkAll" /></th>
							<th>디바이스명</th>
							<th>디바이스 주소</th>
							<th>실시간 영상</th>
							<th>디바이스 수정</th>
						</tr>
					</thead>
					<tbody>
						<c:forEach var="item" items="${deviceList}">
				<tr data-dv-id="${item.dv_id}">
				<td><input type="checkbox" class="row-check" /></td>
				<td>${item.dv_name}</td>
				<td>${item.dv_addr}</td>
				<!-- 추후 고도화 시 이렇게 가야 함, 지금은 위에 것으로 해주기 								
				<td>
					<c:choose>
						<c:when test="${item.dv_status eq 0}">OFF</c:when>
						<c:when test="${item.dv_status eq 1}">ON</c:when>
					</c:choose>
				</td>
				
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
				<td><button type="button" onclick="viewRealTimeVideoPopup(${item.dv_id})">📹</button></td>
				<td><button type="button" onclick="viewDeviceInfoPopup(${item.dv_id})">수정</button></td>
				</tr>
				</c:forEach>
					</tbody>
				</table>
				
				<div class="pagination">
					<ui:pagination paginationInfo="${paginationInfo}" type="text" jsFunction="goPage"/>
				</div>
				
				<!-- 팝업 placeholder -->
				<div id="realTimeVideoPopup" style="display:none;"></div>
				<div id="deviceInfoPopup" style="display:none;"></div>
				<div id="deletedevicePopup" style="display:none;"></div>
			</main>
		</div>
	</div>
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>