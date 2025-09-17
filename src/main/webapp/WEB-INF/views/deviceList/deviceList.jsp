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
  
  	<!-- 디바이스 리스트의 첫번째 디바이스의 ID -->
  	<c:forEach var="entry" items="${deviceList}" varStatus="status">
    	<c:if test="${status.first}">
        	<c:set var="firstDeviceList" value="${entry.value}" />
        	<c:if test="${not empty firstDeviceList}">
    			<c:set var="deviceId" value="${firstDeviceList[0].dv_id}" />
			</c:if>
    	</c:if>
	</c:forEach>
  	
	<script>
		
		// 현재 스트리밍 중인 deviceId
		var deviceId = null;
		
		// 현재 스트리밍중인지 아닌지 여부
		var isStreamingActive = false;
		
		
		/*
		* 실시간 스트리밍 실행
		*/
		function playVideo(){
			
			hls = new Hls({
				maxBufferLength:10,
				maxBufferSize: 60 * 1000 * 1000
			});
			
			const video = document.getElementById('video');
			// jetson : 192.168.0.31, 개발 : 192.18.0.15
			// ccty : 192.168.0.39
			const videoSrc = 'https://www.geyeparking.shop/index.m3u8';
			
			if(Hls.isSupported()){
				
				hls.loadSource(videoSrc);
				hls.attachMedia(video);
				
				hls.on(Hls.Events.MANIFEST_PARSED,() => {
					video.play();
				});
				
				hls.on(Hls.Events.ERROR,function(event,data){
					// alert("🔴 HLS Error:" + data.type + " / " + data.details + " / " + data);
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
				video.src = videoSrc;
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
			
			const video = document.getElementById('video');
			
			if(hls){
				hls.destroy();
			}
			
			video.pause();
			video.load();
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
	    *  - id : 명령어를 보낼 device의 id
	    * @return
	    */
		async function sendCommand(command,id) {
			
	    	// id값 검증하여 없다면 return
	    	if(id == null || id == undefined || id == 0 || id == ""){
	    		alert("먼저 디바이스 리스트에서 디바이스를 선택해주세요");
	    		return;
	    	}
	    	
	    	
	    	// 정지 버튼의 data-device-id 속성에 저장, 추후 고도화시 다시 구현
	        // document.getElementById("stopStreamBtn").dataset.deviceId = id;
	    	
			const body = {
				'type': command,
				'id': id
			};
			
	    	fetch('/gov-disabled-web-gs/deviceList/sendCommandToJSON', {
	      		method: 'POST',
	      		headers: {
	        		'Content-Type': 'application/json'
	      		},
	      		body: JSON.stringify(body)
	    		})
	    	.then(response => {
	      		if (!response.ok) throw new Error('요청 실패');
	      		return response.text();
	    	})
	    	.then(text => {

	    		if(command == "start"){
	    			playVideo(); 
	    		} else if (command == "end"){
	    			stopVideo();
	    		}else{
	    			// 다른 버튼도 추가 구현해야 함
	    		}

	    	})
	    	.catch(error => {
	    		alert('오류: ' + error);
	    		stopVideo();
	    	});
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
	  	
	  	// 버튼 클릭시 조건에 따라 start, stop 명령어 실행
	  	function deviceBtnClick(command,newDeviceId){
	  		
	  		// 이미 다른 디바이스 실행되고 있는 경우
	  		if(deviceId != null){
	  			sendCommand('stop',deviceId);
	  			deviceId == null;
	  			isStreamingActive = false;
	  		}
	  		
	  		deviceId = newDeviceId;
	  		
	  		sendCommand(command,newDeviceId);
	  		isStreamingActive = true;
	  		
	  	}
	  	
	  	// 페이지 시작시 자동 실행
	    document.addEventListener('DOMContentLoaded', function() {
	    
	    	// deviceId값이 null이면 자동실행 금지
	    	if(deviceId == null){
	    		deviceId = '${deviceId}';
	    		
	    		return;
	    	}
	    	
	    	sendCommand('start',deviceId);
	    	isStreamingActive = true;
	    });
	    

	 	// 기존 스크립트에 추가할 페이지 이탈 처리 코드

	 	// 페이지 종료 전 이벤트 처리
		 window.addEventListener('beforeunload', function(event) {
		     
		     // 현재 스트리밍이 활성화되어 있으면 종료 명령 전송
		     if (isStreamingActive && deviceId) {
		         // 동기 방식으로 end 명령 전송 (페이지 종료 시에는 비동기 요청이 취소될 수 있음)
		    	 sendCommand('end',deviceId);
		     }
		 });
	 	
	    
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
				                	<a href="javascript:void(0);" onclick="sendCommand('start','${device.dv_id}')">${device.dv_name}</a>
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
					<!-- 
				    <div class="controller-center-wrapper">
				        <div class="controller-wrapper">
				            <div class="controller-button up">▲</div>
				            <div class="controller-button left">◀</div>
				            <div id = "stopStreamBtn" class="controller-center" data-device-id="" onclick="sendCommand('end',this.dataset.deviceId)">⏸</div>
				            <div class="controller-button right">▶</div>
				            <div class="controller-button down">▼</div>
				        </div>
				    </div>
				     -->
				</div>
				<!-- 컨트롤러 버튼 -->
				<!-- 
			    <div class="controller-buttons">
			        <button onclick="sendCommand('start')">Start</button>
			        <button onclick="sendCommand('end')">End</button>
			    </div>
			     -->
			</main>
		</div>
	</div>	
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>