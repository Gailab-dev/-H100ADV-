<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입</title> <!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/login.css"> <!-- CSS 불러오기 -->
</head>
<script
  src="https://code.jquery.com/jquery-3.7.1.js"
  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
  crossorigin="anonymous"></script>

<body>
	<!-- 상단 헤더 공간 (투명, 고정 높이) -->
    <header class="login-header"></header>

	<main class="login-wrap">
	  <!-- 좌측: 제품 사진 -->
		<section class="bg-panel">
		    <img src="${pageContext.request.contextPath}/resources/images/product.png"
		         alt="제품 이미지"
		         class="bg-img">
		</section>
	
	    <!-- 우측: 로그인 카드 -->
	    <section class="form-panel">
	      <div class="login-card">
	        <p class="product-ver">G.Eye-Parking H100 V1.0</p>
	
	        <div class="title-row" role="heading" aria-level="1">
				<img src="${pageContext.request.contextPath}/resources/images/simbol.png"
				     alt="아이콘" class="title-icon">
	          <span class="title-text">관리자 로그인</span>
	        </div>
	
	        <div class="fields">
	          <input id="id"  class="line-input" type="text"     placeholder="아이디를 입력하세요" autocomplete="username">
	          <input id="pwd" class="line-input" type="password" placeholder="비밀번호를 입력하세요" autocomplete="current-password">
	          <input id="name" class="line-input" type="text" placeholder="이름를 입력하세요" autocomplete="current-password">
	          <input id="phone" class="line-input" type="text" placeholder="전화번호를 입력하세요" autocomplete="current-password">
	          <input id="email" class="line-input" type="text" placeholder="이메일을 입력하세요" autocomplete="current-password">
	          <select id = "region">
	          	<option id="region-default" selected>지역</option>
	          	<c:forEach items="${resultList}" var="region" varStatus="status1">
	          		<c:if test="${region.rg_depth eq 1 }">
	          			<option class="option-region" data-rgid="${region.rg_id}">${region.rg_name }</option>
	          		</c:if>
	          	</c:forEach>
	          </select>
	          <select id = "gu">
		        <option id="gu-default" selected>구</option>
	          	<c:forEach items="${resultList}" var="gu" varStatus="status2">
	          		<c:if test="${gu.rg_depth eq 2 }">
	          			<option class="option-gu" data-pid="${gu.rg_p_id}" data-rgid="${gu.rg_id}">${gu.rg_name }</option>
	          		</c:if>	
	          	</c:forEach>
	          </select>
	          <select id = "dong">
	            <option id="dong-default" selected>동</option>
	          	<c:forEach items="${resultList}" var="dong" varStatus="status1">
	          		<c:if test="${dong.rg_depth eq 3 }">
	          			<option class="option-dong" data-pid="${dong.rg_p_id}" data-rgid="${dong.rg_id}">${dong.rg_name }</option>
	          		</c:if>
	          	</c:forEach>
	          </select>
	          <select id = "parkingLot">
	            <option id="parking-default" selected>주차장</option>
	          	<c:forEach items="${resultList}" var="parking" varStatus="status4">
        			<c:if test="${parking.rg_depth eq 4 }">
	          			<option class="option-parking" data-pid="${parking.rg_p_id}" >${parking.rg_name }</option>
	          		</c:if>
	          	</c:forEach>
	          </select>
	          <label>
	          	<input id="allAgree" class="line-input" type="checkbox" value="">전체동의
	          </label>
	          <label>
	          	<input id="tnc" class="line-input" type="checkbox" value="">(필수) 이용약관 동의
	          	<a href="#">전문보기</a>
	          </label>
	          <label>
	          	<input id="usePi" class="line-input" type="checkbox"  value="" >(필수) 개인정보 수집 및 이용 동의
			  <a href="#">전문보기</a>
	          </label>
			  <p id="alert" style="color:red;"></p>
	          <button class="primary-btn"
	                  onclick="register()">
	            회원가입
	          </button>
	        </div>
	      </div>
	    </section>
	</main>

    <footer class="login-footer"></footer>
</body>
<script>
	
	// 공통: 특정 select를 default option으로 되돌리는 함수
	function resetSelectToDefault(selectId) {
	  const sel = document.getElementById(selectId);
	  if (!sel) return;
	
	  // id에 'default'가 들어간 option을 찾아서 선택
	  const defOpt = sel.querySelector("option[id*='default']");
	  if (defOpt) {
	    defOpt.selected = true;
	  } else {
	    // 혹시 default가 없으면 첫 번째 option으로
	    sel.selectedIndex = 0;
	  }
	}
	
	// parentSelectId : 상위 select의 id (예: 'region')
	// childSelectId  : 하위 select의 id (예: 'gu')
	function filterChildOptions(parentSelectId, childSelectId) {
	  const parentSel = document.getElementById(parentSelectId);
	  const childSel  = document.getElementById(childSelectId);
	  if (!parentSel || !childSel) return;

	  const selectedParentOpt = parentSel.options[parentSel.selectedIndex];
	  // 부모 option의 data-rgid (default면 undefined → null 처리)
	  const parentId = selectedParentOpt ? (selectedParentOpt.dataset.rgid || null) : null;

	  Array.from(childSel.options).forEach(function (opt) {
	    // 1) default 옵션은 항상 보이게
	    if (opt.id && opt.id.indexOf('default') !== -1) {
	      opt.style.display = 'block';
	      return; // 다음 option 처리
	    }

	    // 2) parentId가 없으면(상위가 default 선택 상태면) 하위는 숨김
	    if (!parentId) {
	      opt.style.display = 'none';
	      return;
	    }

	    // 3) 각 하위 option의 data-pid
	    const pid = opt.dataset.pid || null;

	    // 4) 부모 id와 pid가 같으면 block, 아니면 none
	    if (pid === parentId) {
	      opt.style.display = 'block';
	    } else {
	      opt.style.display = 'none';
	    }
	  });
	}
	
	// region, gu, dong, parkingLot 전체 display를 한 번에 제어
	function updateAllSelectDisplays() {
	  // 1) region 은 무조건 전체 보이기
	  updateRegionOptions();

	  // 2) region 선택 상태에 따라 gu 옵션 필터
	  filterChildOptions('region', 'gu');

	  // 3) gu 선택 상태에 따라 dong 옵션 필터
	  filterChildOptions('gu', 'dong');

	  // 4) dong 선택 상태에 따라 parkingLot 옵션 필터
	  filterChildOptions('dong', 'parkingLot');
	}
	
	// 최상위 항목인 지역은 항상 보이게 설정
	function updateRegionOptions() {
		  const regionSel = document.getElementById('region');
		  if (!regionSel) return;

		  Array.from(regionSel.options).forEach(function (opt) {
		    opt.style.display = 'block';
		  });
		}
	
	// region 변경 → gu, dong, parkingLot 초기화
	function onRegionChange() {
	  resetSelectToDefault('gu');
	  resetSelectToDefault('dong');
	  resetSelectToDefault('parkingLot');
	
	  updateAllSelectDisplays();

	}
	
	// gu 변경 → dong, parkingLot 초기화
	function onGuChange() {
	  resetSelectToDefault('dong');
	  resetSelectToDefault('parkingLot');
	
	  updateAllSelectDisplays();

	}
	
	// dong 변경 → parkingLot 초기화
	function onDongChange() {
	  resetSelectToDefault('parkingLot');
	
	  updateAllSelectDisplays();

	}
	
	// 이벤트 바인딩 (select 태그 아래쪽에 이 스크립트를 두는 게 안전)
	document.addEventListener('DOMContentLoaded', function () {
	  document.getElementById('region').addEventListener('change', onRegionChange);
	  document.getElementById('gu').addEventListener('change', onGuChange);
	  document.getElementById('dong').addEventListener('change', onDongChange);
	
	  // 초기 상태 display 세팅
	  updateAllSelectDisplays();

	});
	
	
	
	/**
	* 엔터키 감지하여 = 회원가입 버튼 클릭
	*/
	function enterKeyEvent(event){
		if(event.key == 'Enter'){
			
			register();
		}
	}
	
	/**
	* 키보드에 반응할 수 있도록 input태그에 eventListener 추가
	*/
	$(document).ready(function(){
		const id = document.getElementById('id');
		const pwd = document.getElementById('pwd');
		const phone = document.getElementById('phone');
		const email = document.getElementById('email');
		
		id.addEventListener('keyup',enterKeyEvent);
		pwd.addEventListener('keyup',enterKeyEvent);
		phone.addEventListener('keyup',enterKeyEvent);
		email.addEventListener('keyup',enterKeyEvent);

	})
	
	// id 중복 체크
	async function checkIdDuplicated(id){
		const res = await fetch('${pageContext.request.contextPath}/user/checkId?id='+id, {
		    method: 'GET',
		  });
			
		  // http 오류 상태가 200이 아닌 경우
		  if (!res.ok) {
			return false;
		  }

		  const data = await res.json();   //{ ok: true }
		  return data.ok === true; // true/false로 정리
	}
	
	// validation 발생시 오류 출력
	function showAlert(msg){
		
		// validation 오류시 알림
		const p = document.getElementById("alert");
		p.textContent = msg;
	}
	
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function register() {

		// 회원가입 파라미터 가져오기
		const id = document.getElementById("id")?.value;
		const pwd = document.getElementById("pwd")?.value;
		const name = document.getElementById("name")?.value;
		const phone = document.getElementById("phone")?.value;
		const email = document.getElementById("email")?.value;
		const parkingLot = document.getElementById("parkingLot");
		const selectOpt = parkingLot.options[parkingLot.selectedIndex];
		const region = selectOpt.dataset.pid;
		const tnc = document.getElementById("tnc")?.checked;
		const usePi = document.getElementById("usePi")?.checked;
		
		/*
		try{
		*/
			// validation
			// id
			if(!id){
				showAlert("아이디를 입력해주세요");
				return;
			}
		  	if( id.length >= 100 ){
		  		showAlert("ID는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	const isDuplicated = await checkIdDuplicated(id);
		  	if( isDuplicated ){
		  		showAlert("이미 사용중인 ID입니다.");
		  		return;
		  	}
			if(!pwd){
				showAlert("비밀번호를 입력해주세요");
				return;
			}
		  	if( pwd.length >= 100 ){
		  		showAlert("비밀번호는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		    //비번 규칙: 6~20글자 / 영문+숫자+특수문자 각 1개 이상 / 공백 불가 
		    const PASSWORD_RULE = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s])\S{6,20}$/; 
			if(!PASSWORD_RULE.test(pwd)){
		  		showAlert("비밀번호는 6자 - 20자 사이여야 하고, 영문, 숫자, 특수문자 1개 이상을 포함하는 문자열이여야 합니다.");
		  		return;
			}
			if(!name){
				showAlert("이름을 입력해주세요");
				return;
			}
		  	if( name.length >= 40 ){
		  		showAlert("이름은 최대 한글 20자, 영문 40자 이내로 입력해주세요.");
		  		return;
		  	}
			if(!phone){
				showAlert("전화번호를 입력해주세요");
				return;
			}
		  	if( phone.length >= 26 ){
		  		showAlert("전화번호 길이가 너무 깁니다.");
		  		return;
		  	}
		  	const PHONE_RULE = /^01[016789]-\d{3,4}-\d{4}$/;
		  	if( !PHONE_RULE.test(phone) ){
		  		showAlert("전화번호는 01X-XXXX-XXXX 형식이어야 하며, 휴대폰 번호만 가능합니다.");
		  		return;
		  	}
			if(!email){
				showAlert("이메일을 입력해주세요");
				return;
			}
		  	if( email.length >= 100 ){
		  		showAlert("이메일은 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	/*
		  	const EMAIL_RULE = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
		  	if( !EMAIL_RULE.test(phone) ){
		  		showAlert("이메일은 example@example.com 형식이어야 합니다.");
		  		return;
		  	}
		  	*/
			if(!selectOpt){
				showAlert("지역을 선택해주세요");
				return;
			}
			if(!region){
				showAlert("지역을 선택해주세요");
				return;
			}
			if (!tnc) {
			  showAlert("이용약관에 동의해 주세요.");
			  return;
			}

			if (!usePi) {
			  showAlert("개인정보 수집·이용에 동의해 주세요.");
			  return;
			}
		  	
			// body
			const body = {
				u_login_id : id
				, u_login_pwd : pwd
				, u_name : name
				, u_phone : phone
				, u_email : email
				, u_region : region
			}
			
			console.log("${pageContext.request.contextPath}/user/register");
			
		    // 회원가입
			const res = await fetch('${pageContext.request.contextPath}/user/register',{
				method: 'POST',
		  		headers: {
		    		'Content-Type': 'application/json'
	    			, 'Accept': 'application/json'
		  		},
		  		body: JSON.stringify(body)
			});
			
	        if (!res.ok) {
	            const text = await res.text(); // 에러 페이지로 나온 경우 내용 확인
	            console.error('서버 오류 응답:', res.status, text);
	            return; 
	        }
		    
			const result = await res.json();
			
			if(result.ok){
				window.location.href = "${pageContext.request.contextPath}/user/login.do";
			}else {
				alert(result.msg);
			}
		/*
		}catch (err){
			showAlert("회원가입 오류: " + err);
			return ;
	        
		}
		*/
	}
	

	
	// 1) region 의 모든 option은 항상 block
	  function updateRegionOptions() {
	    const regionSel = document.getElementById('region');
	    Array.from(regionSel.options).forEach(function (opt) {
	      opt.style.display = 'block';
	    });
	  }
	 
	
</script>

</html>