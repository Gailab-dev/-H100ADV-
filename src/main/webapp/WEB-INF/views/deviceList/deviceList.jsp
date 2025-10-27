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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/popup/deleteDevicePopup.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/popup/deviceInfoPopup.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/popup/realTimeVideoPopup.css">
	<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
	<script>
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
		function viewDeleteDevicePopup() {
		  // 1️⃣ 선택된 디바이스 확인
		  const checkedRows = document.querySelectorAll(".row-check:checked");
		  if (checkedRows.length === 0) {
		    alert("삭제할 디바이스를 선택하세요.");
		    return;
		  }
		
		  // 2️⃣ 선택된 디바이스 ID 모으기
		  const dvIds = Array.from(checkedRows).map(cb =>
		    cb.closest("tr").getAttribute("data-dv-id")
		  );
		  console.log("삭제 대상 dvIds:", dvIds);
		
		  // 3️⃣ 서버에서 삭제 팝업 JSP 가져오기
		  axios
		    .post("${pageContext.request.contextPath}/deviceList/viewDeleteDevicePopup", { dvIds })
		    .then(function (r) {
		      console.log("삭제 팝업 JSP 응답:", r);
		      const popupDiv = document.getElementById("deleteDevicePopup");
		      popupDiv.innerHTML = r.data;
		      popupDiv.style.display = "block";
		    })
		    .catch(function (e) {
		      console.error("삭제 팝업 로드 실패:", e);
		    });
		}		

		
	    // 삭제 버튼 클릭 
		function deleteSelectedRows() {
		  const table = document.getElementById("deviceTable");
		  const checkedRows = Array.from(table.querySelectorAll("tbody .row-check:checked"))
		    .map(cb => cb.closest("tr"));
		
		  if (checkedRows.length === 0) {
		    alert("삭제할 디바이스를 선택하세요.");
		    return;
		  }
		
		  const dvIds = checkedRows.map(tr => tr.getAttribute("data-dv-id"));
		  console.log("삭제 요청 보낼 dvIds:", dvIds);
		
		  axios.post("${pageContext.request.contextPath}/deviceList/deleteDeviceInfo", {
		      dvIds: dvIds
		    })
		    .then(function (r) {
		      console.log("서버 응답:", r);
		
		      if (r.data?.ok) {
		        alert("삭제가 완료되었습니다.");
		        removeDeletePopup(); // 팝업 닫기
		        location.reload();   // 리스트 갱신
		      } else {
		        alert(r.data?.msg || "삭제 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function (e) {
		      console.error("삭제 요청 실패:", e);
		      alert("서버 통신 오류가 발생했습니다.");
		    });
		}
	    
	    // 삭제 팝업 삭제
	    function removeDeletePopup() {
	    	const popupDiv = document.getElementById("deleteDevicePopup");
	    	popupDiv.innerHTML = ""; 
	    	popupDiv.style.display = "none";
	    }
	    
	 // ------------------------------------- 디바이스 삭제 팝업 ------------------------------------------


	    
	    // -------------------------------- 디바이스 등록, 수정 ------------------------------

	    // 디바이스 정보 팝업 열기
		function viewDeviceInfoPopup(dvId){
			axios.get('${pageContext.request.contextPath}/deviceList/viewDeviceInfoPopup', { params : {dvId} })
			.then(function(r) {
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
    				closeDeviceInfoPopup();
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
		function insertDeviceInfo() {
		  let dvName = document.getElementById("dvName").value.trim();
		  let dvAddr = document.getElementById("dvAddr").value.trim();
		  let dvIp = document.getElementById("dvIp").value.trim();
		
		  if (!dvName) { alert("디바이스명은 필수입니다."); return; }
		  if (!dvAddr) { alert("주소는 필수입니다."); return; }
		  if (!dvIp) { alert("IP는 필수입니다."); return; }
		
		  axios.post("${pageContext.request.contextPath}/deviceList/insertDeviceInfo",
		      new URLSearchParams({
		        dvName: dvName,
		        dvAddr: dvAddr,
		        dvIp: dvIp
		      })
		    )
		    .then(function(r) {
		      if (r.data?.ok) {
		        alert("디바이스가 등록되었습니다.");
		        closeDeviceInfoPopup();
		        location.reload();
		      } else {
		        alert(r.data?.msg || "등록 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function(e) {
		      console.error("등록 오류:", e);
		      alert("서버 통신 오류가 발생했습니다.");
		    });
		}
    	
    	// 디바이스 등록, 수정 팝업창 닫기
		function closeDeviceInfoPopup(){
			const popup = document.getElementById("deviceInfoPopup");
			popup.innerHTML = "";
			popup.style.display = "none";
		}
	    	
    	// -------------------------------- 디바이스 등록, 수정 ------------------------------
    	
	 	    
	    // ---------------------------- 실시간 영상 팝업 -------------------------------
	    
	    // 실시간 영상 팝업
		async function viewRealTimeVideoPopup(dvId){
			axios.post('${pageContext.request.contextPath}/deviceList/viewRealTimeVideoPopup',{
				dvId : dvId,
			})
			.then(function(r){
				console.log(r);
				
				let rtDiv = document.getElementById("realTimeVideoPopup");
				
				rtDiv.innerHTML = r.data;
				
				rtDiv.style.display = 'block';
				
				// 팝업창 실행시 자동 시작
			    setTimeout(() => {
					    deviceBtnClick('start', dvId);
			    }, 0);
				
			})
			.catch(function(e) {
				console.log(e);
			})
		}
    	
		
		// 현재 스트리밍 중인 deviceId
		let deviceId = null;
		
		// 현재 스트리밍중인지 아닌지 여부
		let isStreamingActive = false;
		
		
		let teardownSent = false;
		
		// 전역 토큰 ID
		let tokenId  = null;
		
		// 전역 hls
		let hls = null;
		
		// video source tag id
		let video = null;
		
		
		/*
		* 1~2초 대기
		*/
		function sleep(ms) { return new Promise(r => setTimeout(r,ms));}
		
		/*
		* 실시간 스트리밍 실행
		*/
		async function playVideo(playUrl){
			

			video = document.getElementById('video');
			// jetson : 192.168.0.31, 개발 : 192.18.0.15
			// ccty : 192.168.0.39
			// 운영 = 'https://www.geyeparking.shop/index.m3u8';
			
			// 네이티브 로드를 차단
			  try { video.pause(); } catch(_) {}
			  video.removeAttribute('src');   // ★ 네이티브 로드를 먼저 차단
			  video.load();
			  if (hls) { try { hls.destroy(); } catch(_){} hls = null; }
			
			if(Hls.isSupported()){
				
				await sleep(3000); 
				
				hls = new Hls({
					autoStartLoad:false
					, maxBufferLength:10
					, maxBufferSize: 60 * 1000 * 1000
					, liveSyncDuration: 2            // or liveSyncDurationCount: 2~3
					, liveMaxLatencyDuration: 5     // or liveMaxLatencyDurationCount: 8~10
					, maxLiveSyncPlaybackRate: 1.5    // 살짝 가속해 엣지 추격
				});
				
				hls.attachMedia(video);
				
			  hls.on(Hls.Events.MEDIA_ATTACHED, async () => {
			    hls.loadSource(playUrl);        // 소스만 로드
			    await sleep(2000);            // 1~2초 대기
			    hls.startLoad(-1);               // ★ 실제 로드 시작(라이브 엣지)
			  });

				
				hls.on(Hls.Events.ERROR,function(event,data){
					  /*
					  * Hls.Events.ERROR 발생시 자세한 에러 로그 확인하는 코드, 오류 발생시에만 주석 풀어서 디버깅
						console.log('HLS ERROR', {
						    type: data.type,
						    details: data.details,
						    code: data.response?.code,
						    url: data.response?.url
						  });
					  */
				      if (data.fatal) {
				        switch (data.type) {
				          // 네트워크 오류인 경우
				          case Hls.ErrorTypes.NETWORK_ERROR:
				            hls.startLoad();
				            alert("⚠️ 네트워크 오류");
				            break;
				          // 미디어 오류인 경우
				          case Hls.ErrorTypes.MEDIA_ERROR:
				            hls.recoverMediaError();
				            alert("⚠️ 미디어 오류");
				            break;
				          // 그 외 오류, 스트리밍 중단
				          default:
				            hls.destroy();
				            alert("❌ 복구 불가, 스트리밍 중단");
				            break;
				        }
				      }
				});
			} else if(video.canPlayType('application/vnd.apple.mpegurl')){
				// video 타입이 hls가 아닌 경우 mpegurl 타입으로 video 실행
				video.src = playUrl;
				video.addEventListener('loadedmetadata',() => {
					
					video.muted = true;
					video.play().catch(err => {
						alert("비디오 플레이 중 오류 : " + err);
					});
				});
			} else {
				alert('HLS를 지원하지 않는 브라우저입니다.')
			}
		}
		
		function stopVideo(){
			
			video = document.getElementById('video');
			
			if(hls){
				hls.destroy();
				hls = null;
			}
			
			video.pause();
			video.load();
			video.removeAttribute('src');
		}
		
		/*
		* 디바이스 컨트롤러 버튼을 화면에 display 할 지 여부 설정, 
		* @param
		*  - display: 컨트롤러 div를 화면에 display하는 설정값(boolean) true면 display
		*/
		/*
	    function displayController(display) {
	        const controller = document.getElementsByClassName("controller")[0].children;
	        for (let btn of controller) {
	            btn.style.display = display;
	        }
	    }
		*/
		
	    /*
	    * 디바이스에 명령어를 보내 기능 수행
	    * @param
	    *  - command : 명령어(string)
	    *  - deviceId : 명령어를 보낼 device의 id
	    * @return : "error" | "end" | playUrl(String)
	    */
		async function sendCommand(command,deviceId) {
	    	
			const body = {
				'type': command,
				'id': tokenId,
				'deviceId':deviceId
			};
			
			try{
		    	const response = await fetch('/gov-disabled-web-gs/deviceList/sendCommandToJSON', {
		      		method: 'POST'
		      		, headers: { 'Content-Type': 'application/json' }
		      		, body: JSON.stringify(body)
		      		, keepalive: command === 'end'
		      		, credentials : 'same-origin'
		      		, cache:'no-store'
		    		});
		    	
		    	// fetch는 항상 response 객체로 리턴
		    	if (!response.ok) return "error";
				
		    	// response에서 json값 가져오기
		    	let data = await response.json();
		    	await sleep(2000);
		    	
		    	// start면 tokenId, playUrl 추가
		    	if(command === 'start'){ 
		    		tokenId = data.result || data.id || null;
		    		let playUrl = data.playUrl || null;
		    		return playUrl;
	    		}
		    	
		    	// end면 tokenId 초기화
		    	if(command === 'end'){ 
		    		tokenId = null; 
		    		return "end";	
		    	}
		    	
		    	// 화각변환
		    	if(command === 'U' || command === 'D' || command === 'L' || command === 'R'){
		    		return "ok";
		    	}
		    	
		    	// 줌 인, 줌 아웃
		    	if(command === 'zoomIn' || command === 'zoomOut'){
		    		return "ok";
		    	}
		    	
		    	
		    	return "error";
			}catch(e){
				return "error";
			}

	  	}
	    
	    // 페이지 종료되었을 때 종료 처리 함수
	    function sendEndBeaconOnce(){
	    	
		 	if(teardownSent) return;
		 	if(!isStreamingActive || !deviceId) return;
			 
		 	teardownSent = true;
		    	
    		// 보낼 데이터
    	    const body = JSON.stringify({ type: 'end', id: tokenId, deviceId: deviceId });
	    	
	    	// 실시간 스트리밍 종료 요청
    	    try {
    	    	// 1) sendBeacon 방식으로 브라우저 중도 요청 취소 방지
    	        const ok = navigator.sendBeacon(
    	          '/gov-disabled-web-gs/deviceList/sendCommandToJSON',
    	          new Blob([body], { type: 'application/json' })
    	        );
    	    	
    	        if (!ok) {
    	          // 2) sendBeacon 실패시 fetch에 keepalive true 속성 사용하여 실시간 스트리밍 종료 요청
    	          fetch('/gov-disabled-web-gs/deviceList/sendCommandToJSON', {
    	            method: 'POST',
    	            headers: { 'Content-Type': 'application/json' },
    	            body,
    	            keepalive: true
    	          });
    	        }
    	      
    	      // 페이지 밖으로 벗어남으로 에러 처리 없음
    	      } catch (_) {}
    	      
    	      // 로컬 플레이어는 즉시 정리 (네트워크 요청과 별개)
    	      try { if (hls) { hls.destroy(); hls = null; } } catch(_){}
    	      try {
    	        const v = document.getElementById('video');
    	        if (v) { v.pause(); v.removeAttribute('src'); v.load(); }
    	      } catch(_){}
    	      isStreamingActive = false;

	    }

	  	// 디바이스 리스트 버튼 클릭시 조건에 따라 start, stop 명령어 실행
	  	async function deviceBtnClick(command,newDeviceId){
	  		
	  		let result = "error";
	  		
	  		// 이미 다른 디바이스 실행되고 있는 경우 먼저 end command 보냄
	  		if(isStreamingActive && deviceId){
	  			
	  			result = await sendCommand('end',deviceId);
	  			
	  			if(result === "error"){
	  				alert("기존 디바이스와 통신 오류");
	  				return;
	  			}

  				stopVideo();
  				deviceId = null;
	  			isStreamingActive = false;
	  			tokenId = null;
	  			
	  			// 기존 디바이스 종료 명령이라면 여기에서 return
	  			if(command === 'end'){
	  				return;
	  			}
	  			
	  		}
	  		
	  		// 새로운 디바이스와 통신
	  		deviceId = newDeviceId;
	  		result = await sendCommand(command,deviceId);
	  		
	  		// 새로운 디바이스와 통신 중 오류 처리
	  		if(result === "error"){
	  			alert("새 디바이스와 통신 오류");
	  			isStreamingActive = false;
	  			deviceId = null;
	  			return;
	  			
  			// 새로운 디바이스와 연결 시 요청에 따른 videoPlayer 처리
	  		}else{
	  			if(command === 'start'){
	  				if (hls) { try{ hls.destroy(); }catch(_){} hls = null; } // 기존에 hls가 남아 있다면 제거
	  				playVideo(result); //playUrl
	  				isStreamingActive = true;
	  			}else if(command === 'end'){
	  				stopVideo();
	  				isStreamingActive = false;
	  			}
	  		}
	  		
	  		
	  	}
	  	
	  	
	  	// 페이지 시작시 자동 실행
	    document.addEventListener('DOMContentLoaded', function() {
	    	
	    	// deviceBtnClick('start','${deviceId}');
	    	
	    });
	  	

	 	// 페이지 종료 전 이벤트 처리
		 window.addEventListener('beforeunload', () => {
			 sendEndBeaconOnce();
			 
			 });
		 window.addEventListener('pagehide', () => { sendEndBeaconOnce(); }, { capture: true });
		 document.addEventListener('visibilitychange', () => {
			 
		     if (document.visibilityState === 'hidden') sendEndBeaconOnce();
		 });
		 window.addEventListener('unload', () => { 
			 sendEndBeaconOnce(); 
			  
		 });
		
		 
		 // 틸팅 관련 버튼 클릭시 명령어 디바이스에 송신
		 async function tiltingBtnClick(command){
			 
			 // 디바이스에 실시간 송출이 되고 있지 않다면 return
			 if(deviceId == null || deviceId == undefined || deviceId == ""){
				 alert("먼저 디바이스부터 실행해주세요.");
				 return;
			 }
			 
			 result = await sendCommand(command,deviceId);
			 
		  		// 새로운 디바이스와 통신 중 오류 처리
		  		if(result === "error"){
		  			alert("틸팅 실패");
		  			return;
		  		}
		  	
		  		await sleep(3000);
		  		
		 }
		 
		 // 팝업창 닫기
		 function closeRealTimeVideoPopup(){
			 if(isStreamingActive == true) stopVideo();
			 
			 let realTimeVideoPopup = document.getElementById("realTimeVideoPopup");
			 realTimeVideoPopup.innerHTML = "";
			 realTimeVideoPopup.style.display = 'none';
			 // location.reload();
			 
		 }
		
		// ---------------------------- 실시간 영상 팝업 -------------------------------   
		
		
		// ---------------------------- 체크박스 관련 자바스크립트 -------------------------------  		
		    window.onload = function() {
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
	      <button onclick="location.href='/gov-disabled-web-gs/stats/logout'">로그아웃</button>
	    </div>
	  </div>
	</header>
	<!-- 사이드바 -->
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
				    <button class="add-btn" onclick="viewDeviceInfoPopup()">+ 디바이스 등록</button>
						<form id="deviceListSearchForm" class="search-box" onsubmit="searchDeviceList('${page}'); return false;">
						  <input type="text" name="searchKeyword" value="${searchKeyword}" placeholder="디바이스명 및 주소 검색">
						  <button type="submit" class="search-btn" title="검색">
						    <svg width="20" height="20" viewBox="0 0 20 20" fill="none"
						         xmlns="http://www.w3.org/2000/svg">
						      <path d="M8.75065 14.1673C11.7422 14.1673 14.1673 11.7422 14.1673 8.75065C14.1673 5.75911 11.7422 3.33398 8.75065 3.33398C5.75911 3.33398 3.33398 5.75911 3.33398 8.75065C3.33398 11.7422 5.75911 14.1673 8.75065 14.1673Z"
						            stroke="#767676" stroke-width="1.5" stroke-miterlimit="10"/>
						      <path d="M16.1363 17.197C16.4292 17.4899 16.9041 17.4899 17.197 17.197C17.4899 16.9041 17.4899 16.4292 17.197 16.1363L16.6667 16.6667L16.1363 17.197ZM12.5 12.5L11.9697 13.0303L16.1363 17.197L16.6667 16.6667L17.197 16.1363L13.0303 11.9697L12.5 12.5Z"
						            fill="#767676"/>
						    </svg>
						  </button>
						</form>
				  </div>
				
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
				<div id="deleteDevicePopup" style="display:none;"></div>
			</main>
		</div>
	</div>
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>