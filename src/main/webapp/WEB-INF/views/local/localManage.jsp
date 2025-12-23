<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    <%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE html>

<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<!-- jQuery & jsTree -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jstree@3.3.15/dist/themes/default/style.min.css">
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/jstree@3.3.15/dist/jstree.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<script>
  <c:if test="${not empty errorMsg}">
    alert('<c:out value="${errorMsg}" />');
  </c:if>
</script>
<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->

<body>
	<div class="container">
		<aside class="sidebar">
            <ul class="menu">
                <li><a href="${pageContext.request.contextPath}/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">홈</a></li>
                <li><a href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <li><a href="${pageContext.request.contextPath}/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
                <li><a href="${pageContext.request.contextPath}/local/viewlocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            </ul>
        </aside>
		<div class="content">
			<div class="tree-wrap">
				
	  			<div class="toolbar">
	    			<button type="button" id="btnAdd" onclick="openAddPopup()">추가</button>
	    			<button type="button" id="btnDelete" onclick="delNode()">삭제</button>
	    			<button type="button" id="btnSave" onclick="savePatches()">저장</button>
	  			</div>
	  			 
	  			<div id="regionTree"></div>
			</div>
		</div>
		
		<div id="treeNodePopup" style="display:none;">
			
		</div>

	</div>


<%-- 지역 node --%>
<script type="application/json" id="result-data">
  <c:out value="${resultJson}" escapeXml="false"/>
</script>
<script>

// 프론트에서 노드 추가, 삭제시 저장될 배열
let patches = []; // {op:'add'|'rename'|'delete'|'move', data:{...}}

  // 서버에서 전달된 flat 데이터(JSON 직렬화)
  // JSTL로 안전하게 JSON 문자열을 만든다.
  
  var flat = null;
  try {
	  flat = JSON.parse(document.getElementById('result-data').textContent);
	  console.log("정상");
	  console.log(flat);
  } catch (e) {
	  console.log("오류");
      console.log(flat);
      console.log(e);
  }
  
  
  // jsTree 변환
  // jsTree는 {id, parent, text} 형식 사용, root는 parent:'#', jsTree에서 parent는 문자열이여야 함
  const nodes = flat.map(r => ({
    id: String(r.rg_id),
    parent: (Number(r.rg_p_id) === 0 ? '#' : String(r.rg_p_id)), // DB는 int지만 jsTree는 string이어야 함
    text: r.rg_name,
    data : {
    	rg_depth : Number(r.rg_depth) || 1
    	, rg_org : Number(r.rg_org || 0)
    	, rg_p_id : Number(r.rg_p_id || 0)
    	
    }
  }));

  $(function(){
    $('#regionTree').jstree({
      core: {
        data: nodes,
        check_callback: true,
        multiple: true,
        themes: { stripes: true }
      },
      plugins: ['checkbox','wholerow','dnd'],
      checkbox : {
    	  three_state : false // 자기의 부모, 자식 노드 자동 선택 해제
    	  , cascade : '' // 선택, 해제 전파 금지
      }
    })
      .on('create_node.jstree', (e, d) => { // 노드 추가
    patches.push({ op:'add', data:{
      temp_id: d.node.id, 
      rg_name: d.node.text,
      rg_p_id: d.node.parent === '#' ? 0 : Number(d.node.parent),
      rg_depth: (Number(d.node.data?.rg_depth) || 1),
      rg_org: (Number(d.node.data?.rg_org) || 0)
    }});
  })
  .on('delete_node.jstree', (e, d) => { // 노드 삭제
    patches.push({ op:'delete', data:{ 
    	rg_id: d.node.id
    	, rg_depth: (Number(d.node.data?.rg_depth) || 1)
        , rg_name: d.node.text
    	}});
  })

    // 선택된 리프 노드만 가져오기 (필요 시)
    window.getSelectedLeafNames = function(){
      const inst = $('#regionTree').jstree(true);
      const ids  = inst.get_selected(); // 체크박스가 있으면 체크된 것
      const leafNames = [];
      ids.forEach(id=>{
        const node = inst.get_node(id);
        if(node && (!node.children || node.children.length === 0)){
          leafNames.push(node.text);
        }
      });
      return leafNames;
    };
  });
  
  // 노트 추가(프론트 앤드에서만)
  function addNode() {
	  
	  // 팝업에서 입력된 값들
      const popup = document.getElementById("treeNodePopup");
      const rgNameInput  = popup.querySelector('[name="rg_name"]'); // 지역 이름
      const rgDepthInput = popup.querySelector('[name="rg_depth"]'); // 지역 depth
      const rgOrgInput   = popup.querySelector('[name="rg_org"]'); // 지역 순서
	  
      // 노드 생성을 위한 값
	  const inst = $('#regionTree').jstree(true);
	  const sel  = inst.get_selected()[0] || '#';    // 선택 없으면 루트에 추가
	  const rgName = rgNameInput?.value?.trim() || ''; // 지역 이름
	  const rgDepth = Number(rgDepthInput?.value || 1); // 지역 depth
	  const rgOrg = Number(rgOrgInput?.value || 1); // 지역 순서
	  const parentId = sel === '#' ? 0 : Number(sel);
	  
	  // 노드 생성(프론트 앤드만)
	  const newId = inst.create_node(sel, { 
		  text: rgName 
		  , data: {
			rg_depth : rgDepth
			, rg_org : rgOrg
			, rg_p_id : parentId
		  	}
	  	  }, 'last');
	  
	    // patches에 add 정보 기록
	    /*
	    patches.push({
	      op: 'add',
	      data: {
	        temp_id: newId,     // 프론트 임시 ID
	        rg_name: rgName,
	        rg_p_id: parentId,
	        rg_depth: rgDepth,
	        rg_org: rgOrg
	      }
	    });
	  	*/
	  // 팝업창 닫기
	  closeTreePopup();

	}

  	// 노드 삭제(프론트 앤드에서만)
	function delNode() {
	  const inst = $('#regionTree').jstree(true);
	  const sel  = inst.get_selected(true);
	  if (sel.length){
		  
		  // 삭제 (delete_node 이벤트에서 patches에 기록됨)
		  sel.forEach(n => inst.delete_node(n));
		  
	  }else{
		  alert("노드를 선택하세요");
		  return;
	  }
	}
  
  	// 노드 변경사항 저장(백엔드)
	async function savePatches() {
		  console.log('patches:', patches);
		
		  try{
			  const response = await fetch('${pageContext.request.contextPath}/local/saveLocalManage', {
		      		method: 'POST'
		      		, headers: { 'Content-Type': 'application/json' }
		      		, body: JSON.stringify(patches)
		      		, credentials : 'same-origin'
		      		, cache:'no-store'
		    		});
			  
		      // HTTP 자체는 성공(200) -> JSON 파싱
		      const r = await response.json();
			  
			  if(r.ok){
				  patches = [];
				  alert(r.msg);
			  }else{
				  alert(r.msg);
			  }
		  }
		  catch(e){
			  alert(e);
		  }

  	}
  	
    // 선택한 노드의 자식들 중에서 rg_org 최대값 + 1 구하는 함수
    function getNextChildOrg(inst, parentId) {
    	const parentNode = inst.get_node(parentId);
    	if (!parentNode) return 1;

    	const childIds = parentNode.children || [];
    	let maxOrg = 0;

    	childIds.forEach(function (cid) {
      		const childNode = inst.get_node(cid);
      		const org = Number(childNode?.data?.rg_org || 0);
      		if (org > maxOrg) maxOrg = org;
    	});

    	return maxOrg + 1;   // 자식이 없으면 1
    }
  
	// 팝업창 닫기
	function closeTreePopup(){
	    const popupDiv = document.getElementById("treeNodePopup");
	    popupDiv.innerHTML = "";
	    popupDiv.style.display = "none";
	}
  
	// 팝업창 열기
	async function openAddPopup(){
	  	const inst = $('#regionTree').jstree(true);
	  	const sel  = inst.get_selected()[0] || '#';
	  	const parentNode = inst.get_node(sel);
	    
	  	// 최대 깊이를 초과하는 노드 생성 금지
	  	parentDepth = Number(parentNode?.data?.rg_depth) || 1;
	  	if(parentDepth >=4){
	   		alert("하위 노드를 생성할 수 없는 노드입니다.");
	   		return;
	  	} 	
    
 		// 선택 노드 기준으로 하위 노드 rg_org 최대값 + 1
    	const nextOrg = getNextChildOrg(inst, sel);
 		
 		// 파라미터 값
 		const body = {
			rg_p_id : sel === '#' ? null : Number(sel) // 부모 id
			, rg_depth : parentDepth + 1 // 깊이
			, rg_org : nextOrg // 지역 순서	
 		}
    
		axios.post('${pageContext.request.contextPath}/local/openTreeNodePopup', 
				{
					rg_p_id : sel === '#' ? null : Number(sel) // 부모 id
					, rg_depth : parentDepth + 1 // 깊이
					, rg_org : nextOrg // 지역 순서	
				})
		.then(function(r) {
		  const riDiv = document.getElementById("treeNodePopup");
		  riDiv.innerHTML = r.data;
		  riDiv.style.display = "block";
		})
		.catch(function(e) {
		  
		});
 	 }
	
	
</script>


</body>
</html>