<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>diviceList</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/deviceList.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/pagination.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/deleteDevicePopup.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/deviceInfoPopup.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/realTimeVideoPopup.css">
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<script>
	  src="https://code.jquery.com/jquery-3.7.1.js"
	  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
	  crossorigin="anonymous"
	</script>

	<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
	<script src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>
	<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
	<script>
	  <c:if test="${not empty errorMsg}">
	    alert('<c:out value="${errorMsg}" />');
	  </c:if>
	</script>
<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<script>
	  window.addEventListener('pageshow', function (e) {
	    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
	  });
	</script>
<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   		window.SESSION_TIMEOUT_SECONDS = <%=session.getMaxInactiveInterval()%>;
   		const CONTEXT_PATH = "${pageContext.request.contextPath}";
	</script>
<script
	src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
	 // -------------------------------- pagination 활용한 페이지 이동 ----------------------------
	 
 		// 검색 input에서 100자 이상 입력시 알림 출력
	 	document.addEventListener('DOMContentLoaded', function () {
		  const MAX_LEN = 100;
		
		  // 1) 폼 찾기
		  const searchForm = document.getElementById('deviceListSearchForm');
		  if (!searchForm) {
		    // 이 페이지에는 검색 폼이 없으면 그냥 조용히 종료
		    return;
		  }
		
		  // 2) input 요소 찾기 (name="searchKeyword" 기준)
		  const searchElement = searchForm.elements['searchKeyword'];
		  if (!searchElement) {
		    // 요소 없으면 종료
		    return;
		  }
		
		  // 3) 길이 제한 + 경고 로직
		  let warnedOnce = false; // 계속 알람 뜨는 것 방지용
		
		  searchElement.addEventListener('input', function () {
		    const val = this.value || '';
		
		    if (val.length > MAX_LEN) {
		      // 초과 입력 잘라내기
		      this.value = val.slice(0, MAX_LEN);
		      alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
		    } 
		  });
		});
	 
		// 디바이스 및 주소 검색
		window.searchDeviceList = function(pageNo){
			
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;
		  	
		  	if( searchKeyword.length >= 100 ){
		  		alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
		  		return;
		  	}
		  	if(startDate > endDate){ 
				alert("날짜를 확인해주세요.");
				return;
		  	}
		  	
		  	// 검색 파라미터 변경으로 인한 페이지 번호 1로 변경
		  	pageNo = Math.max(1, Number.isFinite(+pageNo) ? Math.trunc(+pageNo) : 0);
			
			location.href = "viewDeviceList.do?page=" + pageNo +"&startDate=" +startDate +"&endDate="+ endDate + "&searchKeyword=" + searchKeyword+"&pageSize="+pageSize;
			
		}
		
		// pagination 객체를 활용한 페이지 이동
		window.goPage = function(pageNo){
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;

			location.href = "viewDeviceList.do?page=" + pageNo + "&startDate=" +startDate+ "&endDate=" +endDate+"&searchKeyword=" + searchKeyword+"&pageSize="+pageSize;
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
		
		  // 3️⃣ 서버에서 삭제 팝업 JSP 가져오기
		  axios
		    .post("${pageContext.request.contextPath}/deviceList/viewDeleteDevicePopup", { dvIds })
		    .then(function (r) {
		      
		      const popupDiv = document.getElementById("deleteDevicePopup");
		      popupDiv.innerHTML = r.data;
		      popupDiv.style.display = "block";
		    })
		    .catch(function (e) {
		      
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
		  
		
		  axios.post("${pageContext.request.contextPath}/deviceList/deleteDeviceInfo", {
		      dvIds: dvIds
		    })
		    .then(function (r) {
		      
		
		      if (r.data?.ok) {
		        alert("삭제가 완료되었습니다.");
		        removeDeletePopup(); // 팝업 닫기
		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";   // 리스트 갱신
		      } else {
		        alert(r.data?.msg || "삭제 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function (e) {
		      
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

   	    // 디바이스 등록, 수정 화면에서 한계 값 이상 초과 입력 시도시 오류
		const INPUT_LIMITS = {
		  dvName: {
		    max: 100,
		    message: "디바이스명은 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다."
		  },
		  serialNumber: {
		    max: 15,
		    message: "시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다."
		  },
		  dvAddr: {
		    max: 200,
		    message: "주소는 200자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다."
		  },
		  dvIp: {
		    max: 30,
		    message: "도메인은 30자를 넘을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함한 값만 입력 가능합니다."
		  }
		};
	    
	    document.addEventListener('DOMContentLoaded', function(){
			
			let dvNameWarnedOnce = false; // 계속 알람 뜨는 것 방지용
			document.addEventListener('input', function (e) {
		    
			const el = e.target;
			if(!el.id) return;
				
		    const config = INPUT_LIMITS[el.id];
		    if (!config) return;   // 우리가 관리하는 필드가 아니면 무시
			
		    const max = config.max;
		    const val = el.value || "";
	
		    if (val.length > max) {
			      // 1) 초과 입력 취소 (초과분 잘라내기)
			      el.value = val.slice(0, max-1);
			      alert(config.message);
			     }
			  }); 
		});
	    
	    // 디바이스 등록 수정시 디바이스명과 주소 중복 체크
	    async function duplicatedNameAndAddr(dvId,dvName,dvAddr ){
		    
		 	const body = {
		 		dvId : dvId,	
		 		dvName : dvName,
		 		dvAddr : dvAddr
		 	}
		 	
		 	const res = await fetch('${pageContext.request.contextPath}/deviceList/duplicatedNameAndAddr',{
		    	method : 'POST',
		    	headers : {
		    		'Content-Type' : 'application/json'
		    	},
				credentials : 'same-origin',
				cache: 'no-store',
				body : JSON.stringify(body)
		    });

		 	if(!res.ok){
    			return false;
    		}
		 	
		 	const result = await res.json();
		 	if(!result.ok){
		 		alert(result.msg);
		 		return false;
		 	}else{
		 		return true;
		 	}
		 	
	 	}
	 
	 	// 디바이스 등록, 수정시 중복 체크
	 	async function validateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvSerialNumber){
	  		
    		if(!dvName){
    			alert("디바이스명은 필수입니다.");
    			return false;
    		}
    		if(dvName.length > 100){
    			alert("디바이스명은 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
    			return false;
    		}
    		
    		if(!dvAddr){
    			alert("주소는 필수입니다.");
    			return false;
    		}
    		if(dvAddr.length > 200){
    			alert("주소는 200자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
    			return false;
    		}
    		const isDuplicatedNameAndAddr = await duplicatedNameAndAddr(dvId,dvName,dvAddr);
    		if(!isDuplicatedNameAndAddr){
    			return false;
    		}
    		if(!dvIp){
    			alert("도메인은 필수입니다.");
    			return false;
    		}
    		if(dvIp.length > 30){
    			alert("도메인은 30자를 넘을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함한 값만 입력 가능합니다");
    			return false;
    		}
    		if (/^[0-9.]+$/.test(dvIp)) {
    			alert("도메인에는 '.'과 숫자만으로 이루어진 값을 넣을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함해 주세요.");
    			return false;
    		}
    		if(!dvSerialNumber){
    			alert("시리얼 넘버는 필수입니다.");
    			return false;
    		}
    		if(dvSerialNumber.lengh > 15){
    			alert("시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다.");

    			return false;
    		}
    		if (/[ㄱ-ㅎ가-힣]/.test(dvSerialNumber)) {
    			alert("시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다.");

    			return false;
    		}
    		return true;
	 	}   
	 
	    // 디바이스 정보 팝업 열기
		function viewDeviceInfoPopup(dvId){
			axios.get('${pageContext.request.contextPath}/deviceList/viewDeviceInfoPopup', { params : {dvId} })
			.then(function(r) {
			  const riDiv = document.getElementById("deviceInfoPopup");
			  riDiv.innerHTML = r.data;
			  riDiv.style.display = "block";
			  document.getElementById('dvName').focus();
			})
			.catch(function(e) {
			  
			});
	    }
	 
    	// 디바이스 수정
    	async function updateDeviceInfo(dvId){
    		
    		let dvName = document.getElementById("dvName").value;
    		let dvAddr = document.getElementById("dvAddr").value;
    		let dvIp = document.getElementById("dvIp").value;
    		let dvSerialNumber = document.getElementById("serialNumber").value.trim();	
		
    		const validateCheck = await validateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvSerialNumber);
    		if(!validateCheck){
    			return;
    		}
    		
    		axios.post('${pageContext.request.contextPath}/deviceList/updateDeviceInfo',
  			    new URLSearchParams({
  			        dvId: dvId,
  			        dvName: dvName,
  			        dvAddr: dvAddr,
  			        dvIp: dvIp,
    			    dvSerialNumber : dvSerialNumber
  			    })
  			)
    		.then(function(r){
    			
    			if(r.data?.ok){
    		        alert("디바이스가 수정되었습니다.");
    		        closeDeviceInfoPopup();
    		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		})
    		.error(function(e){
    			
    			alert("수정 중 오류가 발생했습니다.");
    		});
    	}
    	
    	// 디바이스 등록
		async function insertDeviceInfo() {
		  let dvName = document.getElementById("dvName").value.trim();
		  let dvAddr = document.getElementById("dvAddr").value.trim();
		  let dvIp = document.getElementById("dvIp").value.trim();
		  let dvSerialNumber = document.getElementById("serialNumber").value.trim();	

  		  const validateCheck = await validateDeviceInfo(null,dvName,dvAddr,dvIp,dvSerialNumber);
		  if(!validateCheck){
			  return;
		  }
		
		  axios.post("${pageContext.request.contextPath}/deviceList/insertDeviceInfo",
		      new URLSearchParams({
		        dvName: dvName,
		        dvAddr: dvAddr,
		        dvIp: dvIp,
		        dvSerialNumber : dvSerialNumber
		      })
		    )
		    .then(function(r) {
		      if (r.data?.ok) {
		        alert("디바이스가 등록되었습니다.");
		        closeDeviceInfoPopup();
		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";
		      } else {
		        alert(r.data?.msg || "등록 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function(e) {
		      
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
			
			// URLSearchParams를 사용하여 form data로 전송
			const formData = new URLSearchParams();
			formData.append('dvId', dvId);
    		
    		axios.post('${pageContext.request.contextPath}/deviceList/viewRealTimeVideoPopup', formData)
			.then(function(r){
				
				let rtDiv = document.getElementById("realTimeVideoPopup");
				
				rtDiv.innerHTML = r.data;
				
				rtDiv.style.display = 'block';
				
				// 팝업창 실행시 자동 시작
			    setTimeout(() => {
					    deviceBtnClick('start', dvId);
			    }, 0);
				
			})
			.catch(function(e) {
				
			})
		}
		
		// 현재 스트리밍 중인 deviceId
		let deviceId = null;
		
		// 현재 스트리밍중인지 아닌지 여부
		let isStreamingActive = false;
		
		// ?
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
		    	const response = await fetch('${pageContext.request.contextPath}/deviceList/sendCommandToJSON', {
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
    	          '${pageContext.request.contextPath}/deviceList/sendCommandToJSON',
    	          new Blob([body], { type: 'application/json' })
    	        );
    	    	
    	        if (!ok) {
    	          // 2) sendBeacon 실패시 fetch에 keepalive true 속성 사용하여 실시간 스트리밍 종료 요청
    	          fetch('${pageContext.request.contextPath}/deviceList/sendCommandToJSON', {
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
					endpoint:'/deviceList/excelDownload',
					formSelector:'#deviceListSearchForm',
					mapping: {
						startDate:'startDate',
						endDate:'endDate',
						searchKeyword:'searchKeyword'
					},
					responseType:'blob',
					downloadFilename:'디바이스_리스트.xlsx'
				}).catch(function(e){alert(e.message);});
			})
		});

		/*
		async function excelDownload(){
			
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
			
			const body = {
				'startDate': startDate,
				'endDate': endDate,
				'searchKeyword':searchKeyword
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
		
		
	  // --------- 각 컬럼별 정렬 버튼 클릭시 데이터 정렬 ---------
	  document.addEventListener('DOMContentLoaded', function () {  
			
		  	// 화살표 버튼 이미지 파일 경로
		  	const BASE = '${pageContext.request.contextPath}';
		  	const ICON_UP = BASE + '/resources/images/icon_arrow_up.svg';
		  	const ICON_DOWN = BASE + '/resources/images/icon_arrow_down.svg';
		  
		    // 현재 정렬 상태 (url값 사용)
		    const url = new URL(window.location.href);
		    let currentSortCol = url.searchParams.get('sortCol') || 'ev_id';
		    let currentSortDir = (url.searchParams.get('sortDir') || 'DESC').toUpperCase();

			
		    //각 정렬 버튼 별 이벤트 추가
		    document.querySelectorAll('.sort-btn').forEach(btn => {
		        
		    	// 정렬 대상이 되는 컬럼
		    	const col = btn.dataset.column;
		    	
		    	// 오름차순, 내림차순 표시하는 화살표 이미지
		        const img = btn.querySelector('img');
		        if (!img) return;

		        // 🔹 현재 정렬 컬럼 표시
		        if (col === currentSortCol) {
		            
		        	// active로 정렬 활성화
		        	btn.classList.add('active');
		            
		        	// 이미지 아이콘 변경
		        	img.src = (currentSortDir === 'ASC') ? ICON_UP : ICON_DOWN;
		            if (currentSortDir === 'ASC') {
		                btn.classList.add('asc');
		            }
		        }

		        btn.addEventListener('click', function () {
		            

		            // 다음 이벤트 발생시 정렬 조건을 변수에 저장
		            let nextDir = 'DESC';
		            if (currentSortCol === col) {
		                nextDir = (currentSortDir === 'DESC') ? 'ASC' : 'DESC';
		            }

		            // 🔹 기존 파라미터 유지
		            const url = new URL(window.location.href);
					
		            // 정렬 컬럼, 다음 이벤트시 정렬 조건을 검색 파라미터 추가
		            url.searchParams.set('sortCol', col);
		            url.searchParams.set('sortDir', nextDir);

		            // 정렬 변경 시 페이지는 1페이지로
		            url.searchParams.set('page', 1);
					
		            // 정렬
		            window.location.href = url.toString();
		        });
		    });
		});
		// --------- 각 컬럼별 정렬 버튼 클릭시 데이터 정렬 ---------
		
    </script>
</head>
<body>
	<div class="page-wrapper">
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
		<!-- 사이드바 -->
		<div class="container">
			<!-- 사이드바 -->
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
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.99998 3.33325C10.884 3.33325 11.7319 3.68444 12.357 4.30956C12.9821 4.93468 13.3333 5.78253 13.3333 6.66659C13.3333 7.55064 12.9821 8.39849 12.357 9.02361C11.7319 9.64873 10.884 9.99992 9.99998 9.99992C9.11592 9.99992 8.26808 9.64873 7.64296 9.02361C7.01784 8.39849 6.66665 7.55064 6.66665 6.66659C6.66665 5.78253 7.01784 4.93468 7.64296 4.30956C8.26808 3.68444 9.11592 3.33325 9.99998 3.33325ZM9.99998 4.99992C9.55795 4.99992 9.13403 5.17551 8.82147 5.48807C8.50891 5.80063 8.33331 6.22456 8.33331 6.66659C8.33331 7.10861 8.50891 7.53254 8.82147 7.8451C9.13403 8.15766 9.55795 8.33325 9.99998 8.33325C10.442 8.33325 10.8659 8.15766 11.1785 7.8451C11.4911 7.53254 11.6666 7.10861 11.6666 6.66659C11.6666 6.22456 11.4911 5.80063 11.1785 5.48807C10.8659 5.17551 10.442 4.99992 9.99998 4.99992ZM9.99998 10.8333C12.225 10.8333 16.6666 11.9416 16.6666 14.1666V16.6666H3.33331V14.1666C3.33331 11.9416 7.77498 10.8333 9.99998 10.8333ZM9.99998 12.4166C7.52498 12.4166 4.91665 13.6333 4.91665 14.1666V15.0833H15.0833V14.1666C15.0833 13.6333 12.475 12.4166 9.99998 12.4166Z"
 fill="currentColor"/>
</svg>내 정보
					</a></li>


					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<!-- 메인 콘텐츠 -->
			<div class="content">
				<main class="main">
					<div class="buttonBox">
						<!-- 첫 번째 줄: 등록 버튼 / 두 번째 줄 : 날짜, 검색, 조회버튼 - 10개씩 보기 -->
						<button class="add-btn" onclick="viewDeviceInfoPopup()">+
							디바이스 등록</button>
					</div>
					<div class="device-top">
						<div class="top-row">

							<form id="deviceListSearchForm" class="filter-form"
								onsubmit="searchDeviceList('${page}'); return false;">
								<div class="filter-input-group">
									<input type="date" name="startDate" value="${startDate}" />
								</div>
								<p class="date-contect">~</p>
								<div class="filter-input-group">
									<input type="date" name="endDate" value="${endDate}" />
								</div>
								<div class="search-box">
									<svg width="20" height="20" viewBox="0 0 20 20" fill="none"
										xmlns="http://www.w3.org/2000/svg">
							      		<path
											d="M8.75065 14.1673C11.7422 14.1673 14.1673 11.7422 14.1673 8.75065C14.1673 5.75911 11.7422 3.33398 8.75065 3.33398C5.75911 3.33398 3.33398 5.75911 3.33398 8.75065C3.33398 11.7422 5.75911 14.1673 8.75065 14.1673Z"
											stroke="#767676" stroke-width="1.5" stroke-miterlimit="10" />
						      			<path
											d="M16.1363 17.197C16.4292 17.4899 16.9041 17.4899 17.197 17.197C17.4899 16.9041 17.4899 16.4292 17.197 16.1363L16.6667 16.6667L16.1363 17.197ZM12.5 12.5L11.9697 13.0303L16.1363 17.197L16.6667 16.6667L17.197 16.1363L13.0303 11.9697L12.5 12.5Z"
											fill="#767676" />
						    		</svg>
									<input type="text" name="searchKeyword"
										value="<c:out value='${searchKeyword}'/>"
										placeholder="디바이스명 및 주소 검색"
										maxlength="100">
								</div>
								<button type="submit" class="search-btn" title="검색">조회</button>
							</form>
							
							<select id="pageSize" name="pageSize" class="select-box"
								onChange="searchDeviceList()">
								<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩
									보기</option>
								<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩
									보기</option>
								<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩
									보기</option>
							</select>
						</div>

						<div class="bulk-actions">
							<svg width="16" height="16" viewBox="0 0 16 16" fill="none"
								xmlns="http://www.w3.org/2000/svg">
				      		<rect width="16" height="16" rx="4" fill="#6955A2" />
				      		<path d="M4 9V7H12V9H4Z" fill="white" />
				    	</svg>

							<span class="selected-text">0개 선택됨</span>

							<button type="button" class="delete-btn"
								onclick="viewDeleteDevicePopup()" title="삭제">
								<svg width="20" height="20" viewBox="0 0 20 20" fill="none"
									xmlns="http://www.w3.org/2000/svg">
					        	<path
										d="M11.75 9.11111V14.4444M8.25 9.11111V14.4444M4.75 5.55556V16.2222C4.75 16.6937 4.93437 17.1459 5.26256 17.4793C5.59075 17.8127 6.03587 18 6.5 18H13.5C13.9641 18 14.4092 17.8127 14.7374 17.4793C15.0656 17.1459 15.25 16.6937 15.25 16.2222V5.55556M3 5.55556H17M5.625 5.55556L7.375 2H12.625L14.375 5.55556"
										stroke="black" stroke-width="1.4" stroke-linecap="round"
										stroke-linejoin="round" />
					      	</svg>
							</button>
							<button id="btnExcel" type="button" class="delete-btn"
								onclick="excelDownload()" title="엑셀 다운로드">
								<img
									src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
									alt="엑셀 다운로드">
							</button>
						</div>
					</div>

					<table id="deviceTable" class="device-table">
						<thead>
							<tr>
								<th><input type="checkbox" id="checkAll"
									class="table-checkBox" /></th>
								<th>디바이스명
									<button class="sort-btn" data-column="dv_name">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<th>디바이스 주소
									<button class="sort-btn" data-column="dv_addr">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<th>등록날짜
									<button class="sort-btn" data-column="dv_reg_date">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<th>디바이스 수정</th>
							</tr>
						</thead>
						<tbody>
							<c:choose>
								<c:when test="${empty deviceList}">
									<tr>
										<td colspan="6"
											style="text-align: center; padding: 40px 0; color: #777;">
											조회된 디바이스가 없습니다.</td>
									</tr>
								</c:when>
								<c:otherwise>
									<c:forEach var="item" items="${deviceList}">
										<tr
											data-dv-id="<c:out value='${item.dv_id}' escapeXml ='true'/>">
											<td><input type="checkbox" class="row-check" /></td>
											<td><span class="cell-ellipsis"
												title="${fn:escapeXml(item.dv_name)}"> <c:out
														value="${item.dv_name}" escapeXml="true" />
											</span></td>
											<td><span class="cell-ellipsis"
												title="${fn:escapeXml(item.dv_addr)}"> <c:out
														value="${item.dv_addr}" escapeXml="true" />
											</span></td>
											<td><span class="cell-ellipsis"
												title="${fn:escapeXml(item.dv_reg_date)}"> <c:out
														value="${item.dv_reg_date}" escapeXml="true" />
											</span></td>
					          
					          <!--
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
								 
					          <td>
						        <c:choose>
					        		<c:when test="${item.dv_status eq 1}">
					            		<button type="button" class="video-btn" onclick="viewRealTimeVideoPopup(${item.dv_id})">
				              			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
					                		<path d="M17 12V8C17 7.47 16.79 6.96 16.41 6.59C16.04 6.21 15.53 6 15 6H5C4.47 6 3.96 6.21 3.59 6.59C3.21 6.96 3 7.47 3 8V16C3 16.53 3.21 17.04 3.59 17.41C3.96 17.79 4.47 18 5 18H15C15.53 18 16.04 17.79 16.41 17.41C16.79 17.04 17 16.53 17 16V12ZM17 12L21 8V16L17 12Z"
					                      stroke="black" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
					              		</svg>
					            		</button>
				            		</c:when>
								</c:choose>	
					          </td>
					          -->
											<td>
												<button class="edit-btn" type="button"
													onclick="viewDeviceInfoPopup(${item.dv_id})">수정</button>
											</td>
										</tr>
									</c:forEach>
								</c:otherwise>
							</c:choose>
						</tbody>
					</table>

					<div class="pagination">
						<ui:pagination paginationInfo="${paginationInfo}" type="text"
							jsFunction="goPage" />
					</div>

					<!-- 팝업 placeholder -->
					<div id="realTimeVideoPopup" style="display: none;"></div>
					<div id="deviceInfoPopup" style="display: none;"></div>
					<div id="deleteDevicePopup" style="display: none;"></div>
				</main>
			</div>
		</div>
	</div>
</body>
</html>