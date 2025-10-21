<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
 
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
	    	
	    	deviceBtnClick('start','${deviceId}');
	    	
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
	    
		/*
			1. video 태그에 넣을 url
  				- url  > http://[개발서버ip]:8087/index.m3u8
			2. start 버튼 누르면 요청할 restfulAPI
  				- url  > http://[개발서버ip]:8087/control
  				- data > start (body에 넣어주시면 됩니다)
			3. end 버튼 누르면 요청할 restfulAPI
  				- url  > http://[개발서버ip]:8087/control
  				- data > end (body에 넣어주시면 됩니다)
		*/
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
            <div class="device-navi">
                <h3>디바이스 리스트</h3>
				<c:forEach var="addr" items="${deviceList}">
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
			<main class="main">
				<h1>실시간 영상</h1>	
			    <div class="video-controller-group">
				    <video id="video" width="720" controls autoplay>
				    	<source src="https://www.geyeparking.shop/index.m3u8" type="application/x-mpegURL">
				    </video>
					<!-- 디바이스 컨트롤러  -->
					
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
				<!-- 컨트롤러 버튼 -->
				
			    <div class="controller-buttons">
			        <button onclick="tiltingBtnClick('zoomIn')">zoomIn</button>
			        <button onclick="tiltingBtnClick('zoomOut')">zoomOut</button>
			    </div>
			    
			</main>
		</div>
	</div>	
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>