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
	<script>	
		const hls = new Hls();
		
		function playVideo(){
			console.log("playVideo in");
			
			const video = document.getElementById('video');
			// jetson : 192.168.0.31, 개발 : 192.18.0.15
			const videoSrc = 'http://192.168.0.15:8087/index.m3u8';
			
			if(Hls.isSupported()){
				
				console.log("Hls supported");
				
				hls.loadSource(videoSrc);
				hls.attachMedia(video);
				
				console.log("Hls on");
				
				hls.on(Hls.Events.MANIFEST_PARSED,() => {
					console.log("video play hls");
					video.play();
				});
			} else if(video.canPlayType('application/vnd.apple.mpegurl')){
				
				console.log("Hls not supported");
				
				video.src = videoSrc;
				video.addEventListener('loadedmetadata',() => {
					console.log("video play mpegurl");
					video.play();
				});
			} else {
				alert('HLS를 지원하지 않는 브라우저입니다.')
			}
		}
		
		function stopVideo(){
			
			const video = document.getElementById('video');
			
			if(hls){
				console.log("hls destroy");
				hls.destroy();
			}
			
			video.pause();
			video.load();
		}
		
	    function displayController(display) {
	        const controller = document.getElementsByClassName("controller")[0].children;
	        for (let btn of controller) {
	            btn.style.display = display;
	        }
	    }
		
		function sendCommand(command) {
			
			const params = new URLSearchParams();
			params.append('type',command);
			params.append('id',1);
			
	    	fetch('/gov-disabled-web-gs/deviceList/sendCommand', {
	      		method: 'POST',
	      		headers: {
	        		'Content-Type': 'application/x-www-form-urlencoded'
	      		},
	      		body: params.toString()
	    		})
	    	.then(response => {
	      		if (!response.ok) throw new Error('요청 실패');
	      		return response.text();
	    	})
	    	.then(res => {
	    		console.log(res);
	    		let msg = JSON.parse(res);
	    		console.log(msg.message);
	    		
	    		/*
	    		console.log("blob 타입 : ",blob.type,"blob 크기 : ",blob.size);
	    		const videoUrl = URL.createObjectURL(blob);
	    		document.getElementById('video').src = videoUrl;
	    		*/
	    		let display = "";
	    		if(msg.message == "video start" ){
	    			playVideo();
	    			displayController("block");
	    		} else{
	    			stopVideo();
	    			displayController("none");
	    		}
	    		displayController(display);
	    		
	    	})
	    	.catch(error => {
	    		alert('오류: ' + error);
	    		stopVideo();
	    	});
	  	}
		
			    // 아코디언 기능: 정상작동하도록 유지
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
	<header class="header">
        <div class="logo">GAILAB</div>
        <div class="user">ghskim</div>
    </header>
    <div class="container">
    	<aside class="sidebar">
            <ul class="menu">
                <li><a href="#">홈</a></li>
                <li><a href="#">디바이스 리스트</a></li>
                <li><a href="#">불법주차 리스트</a></li>
                <li><a href="#">통계</a></li>
            </ul>
        </aside>
        <div class="content">
        	<nav class="device-navi">
        		 <h3>디바이스 리스트</h3>
        		 <!-- 주소와 주소별로 그룹화 된 디바이스 리스트 출력 -->
				<c:forEach var="addr" items="${deviceList}">
					<button class="accordion">${addr.key}</button>
					<div class="accordion-content">
						<ul>
						<!-- 주소별 그룹화 된 디바이스 리스트 출력-->
							<c:forEach var="device" items="${addr.value}">
								<li data-dvid = "${device.dv_id }"> ${device.dv_name } </li>
							</c:forEach>
						</ul>
					</div>	
				</c:forEach>
			</nav>
			<main class="main">
				<h1>실시간 영상</h1>	
				<video id="video" width="720" controls autoplay></video>
				<div class="controller-buttons">
					<button onclick="sendCommand('start')">Start</button>
                    <button onclick="sendCommand('end')">End</button>
				</div>
                <div class="controller">
                    <div id="up">↑</div>
                    <div id="left">←</div>
                    <div id="right">→</div>
                    <div id="down">↓</div>
                </div>
			</main>
		</div>
	</div>	
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>
