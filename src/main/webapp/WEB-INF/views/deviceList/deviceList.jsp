<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!-- 
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
 -->
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
		
		function displayController(display){
			let controller = document.getElementsByClassName("controller");
			controoer.style.display = display;
		}
		
		function sendCommand(command) {
			
			const params = new URLSearchParams();
			params.append('type',command);
			params.append('id',1);
			
	    	fetch('/gov-disabled-web-gs/deviceList/sendCommand', {
	      		method: 'POST',
	      		headers: {
	        		'Content-Type': 'application/json'
	      		},
	      		body: JSON.parse(params);
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
	    			display = "block";
	    		} else{
	    			stopVideo();
	    			display = "none";
	    		}
	    		displayController(display);
	    		
	    	})
	    	.catch(error => {
	    		alert('오류: ' + error);
	    		stopVideo();
	    	});
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
	<!-- 
</head>
 
<body>
-->
	<div>
		<h1>실시간 디바이스 화면 출력</h1>
		<video id="video" width="720" controls autoplay>
			
		</video>
		
		<button onClick="sendCommand('start')">start</button>
		<button onclick="sendCommand('end')">end</button>
		 
		
	</div>
	
		<!-- 주소와 주소별로 그룹화 된 디바이스 리스트 출력 -->
		<c:forEach var="addr" items="${deviceList}">
			<!-- 주소 출력 -->
			<h3> ${addr.key } </h3>
			<ul>
				<!-- 주소별 그룹화 된 디바이스 리스트 출력-->
				<c:forEach var="device" items="${addr.value}">
					<li data-dvid = "${device.dv_id }">
						${device.dv_name }
					</li>
				</c:forEach>
			</ul>
		</c:forEach>
		
		<div>
			<div class="controller" id="up" display="none">up</div>
			<div class="controller" id="down" display="none">down</div>
			<div class="controller" id="left" display="none">left</div>
			<div class="controller" id="right" display="none">right</div>
			
		</div>
	
<!-- 
</body>
</html>
 -->