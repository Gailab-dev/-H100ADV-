package com.disabled.controller;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.common.CommonValidation;
import com.disabled.common.ExcelColumn;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.component.LogDiskManager;
import com.disabled.mapper.LoginMapper;
import com.disabled.service.ApiService;
import com.disabled.service.DeviceListService;
import com.disabled.service.ExcelService;
import com.disabled.service.UserService;

@Controller
@RequestMapping("/deviceList")
public class DeviceListController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	@Autowired
	DeviceListService deviceListService;
	
	@Autowired
	ApiService apiService;
	
	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	LogDiskManager logDiskManager;
	
	@Autowired
	CommonValidation commonValidation;
	
	@Autowired
	ExcelService excelService;
	
	@Autowired
	UserService userService;

	/** 카카오 지도 JavaScript SDK 키(주소→좌표 지오코딩용). globals.properties kakao.map.js-key */
	@Value("${kakao.map.js-key:}")
	private String kakaoMapJsKey;

	
	// 디바이스 리스트 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/deviceList/viewDeviceList.do";
	}
	
	// 디바이스 리스트 화면
	@RequestMapping("/viewDeviceList.do")
	private String viewDeviceList(
			@RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="page", required=false) Integer page
			, @RequestParam(value="pageSize", defaultValue="10") Integer pageSize
	        , @RequestParam(value="sortCol", defaultValue="dv_name") String sortCol
	        , @RequestParam(value="sortDir", defaultValue="DESC") String sortDir
			, Model model
			, HttpSession session  ) {
		
		// 접근 로그
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		Integer uId = null;
		if(uIdStr != null) {
			logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자의 {}에 디바이스 리스트 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
			uId = Integer.parseInt(uIdStr.toString());
		}else {
			return "/user/login.do"; 
		}
		
		boolean useTblLog = false;	// 로그 스토리지 사용 가능 여부

		// ====== 유효성 검증 [S] ====== //
				// searchKeyword 검증 (XSS, SQL Injection 방어)
				if (searchKeyword != null && !searchKeyword.isEmpty()) {
					if (searchKeyword.length() > 100 || containsDangerousPattern(searchKeyword)) {
						logger.warn("유효하지 않은 searchKeyword 요청: {}", searchKeyword);
						model.addAttribute("errorMessage", "유효하지 않은 검색어입니다.");
						return "error";
					}
				}
				
				// startDate 검증 (날짜 형식 및 SQL Injection 방어)
				if (startDate != null && !startDate.isEmpty()) {
					if (!commonValidation.isValidDate(startDate) || containsDangerousPattern(startDate)) {
						logger.warn("유효하지 않은 startDate 요청: {}", startDate);
						model.addAttribute("errorMessage", "유효하지 않은 시작 날짜 형식입니다.");
						return "error";
					}
				}

				// endDate 검증 (날짜 형식 및 SQL Injection 방어)
				if (endDate != null && !endDate.isEmpty()) {
					if (!commonValidation.isValidDate(endDate) || containsDangerousPattern(endDate)) {
						logger.warn("유효하지 않은 endDate 요청: {}", endDate);
						model.addAttribute("errorMessage", "유효하지 않은 종료 날짜 형식입니다.");
						return "error";
					}
				}

				// page 검증 (정수 범위 검증)
				if (page != null) {
					if (page < 0 || page > 100000) {
						logger.warn("유효하지 않은 page 요청: {}", page);
						model.addAttribute("errorMessage", "유효하지 않은 페이지 번호입니다.");
						return "error";
					}
				}

				// pageSize 검증 (정수 범위 검증)
				if (pageSize != null) {
					if (pageSize < 1 || pageSize > 100) {
						logger.warn("유효하지 않은 pageSize 요청: {}", pageSize);
						model.addAttribute("errorMessage", "유효하지 않은 페이지 크기입니다.");
						return "error";
					}
				}
				// ====== 유효성 검증 [E] ====== //
		
		
		// 페이지 null 방지
		if (page == null || page < 1) page = 1;
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 페이징 설정
		paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
		paginationInfo.setRecordCountPerPage(pageSize);  // 한 페이지에 출력할 게시글 수
		paginationInfo.setPageSize(10); // 페이지 블록 수
		
		int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
		int totalRecordCount = deviceListService.getTotalRecordCount(startDate,endDate,searchKeyword);
		paginationInfo.setTotalRecordCount(totalRecordCount);
		
	    // 마지막 페이지 계산 후 page 보정
	    int lastPage = (int) Math.ceil(totalRecordCount / (double) recordCountPerPage);
	    if (lastPage < 1) lastPage = 1;

	    int currentPage = Math.min(Math.max(page, 1), lastPage);
	    paginationInfo.setCurrentPageNo(currentPage);

	    // offset 재계산
	    int firstIndex = (currentPage - 1) * recordCountPerPage;

		// DB 검색을 위한 파라미터 설정
		Map<String, Object> paramMap = new HashMap<String, Object>();
		paramMap.put("firstIndex", firstIndex);
		paramMap.put("recordCountPerPage", recordCountPerPage);
		paramMap.put("page", page);
		paramMap.put("searchKeyword", searchKeyword == null ? "" : searchKeyword );
	    paramMap.put("startDate", startDate);
	    paramMap.put("endDate", endDate);
		paramMap.put("sortCol", sortCol);
	    paramMap.put("sortDir", sortDir);
		
		// 로그 스토리지 사용 가능 여부 조회
		useTblLog = logDiskManager.hasEnoughLogSpace();
		
		// 디바이스 리스트 가져오기
		List<Map<String, Object>> deviceList = deviceListService.getDeviceList(paramMap);
		
		System.out.println(deviceList);
		
		// 디바이스 리스트 주소별로 그룹화
		// Map<String, List<Map<String, Object>>> groupAddrByDeviceList = groupedByAddr(deviceList);
		
		// 첫번째 디바이스 값 따로 분리
		// Integer firstDeviceId = (Integer) deviceList.get(0).get("dv_id");
		
		//model add
		// model.addAttribute("groupAddrByDeviceList", groupAddrByDeviceList);
		
		// 세션에 저장된 회원의 이름 조회
		String uName = userService.getUNameBySession(uId);
		
		 // 세션에 저장된 회원의 등급(권한) 가져오기
	    Integer uGrade = Integer.parseInt(session.getAttribute("uGrade").toString()); 
		
	    model.addAttribute("uName", uName);
	    model.addAttribute("uGrade",uGrade);
		model.addAttribute("deviceList", deviceList);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("searchKeyword", searchKeyword == null ? "" : searchKeyword);
		model.addAttribute("startDate", startDate);
		model.addAttribute("endDate", endDate);
		model.addAttribute("useTblLog", useTblLog);
		model.addAttribute("pageSize", pageSize);
		model.addAttribute("kakaoMapJsKey", kakaoMapJsKey); // 주소검색 지오코딩용 Kakao SDK 키
		// model.addAttribute("deviceId", firstDeviceId);
		
		return "deviceList"; // Tiles 정의명(patches 2026-07-06). defaultLayout chrome 적용
	}

	/**
	 * (작업계획서 04) 디바이스 상태 실시간 조회 — deviceList 화면 AJAX 폴링용.
	 * tbl_device 의 상태 5종(dv_status_pc/cctv/lens/speaker/sip) + dv_status_updated 반환.
	 * 조회 전용이라 기존 기능 영향 0. (display 는 DB v0.0.7 미존재로 제외)
	 */
	@GetMapping("/status")
	@ResponseBody
	public List<Map<String, Object>> getStatusList() {
		return deviceListService.getStatusList();
	}

	/**
	 * 디바이스 리스트를 주소를 기준으로 그룹화하여 리턴
	 * @prarm 
	 *   - deviceList: 디바이스 리스트 ( List<Map<String,Object>> )
	 * @return
	 *   - groupAddrByDeviceList : 주소 기준으로 그룹화 된 디바이스 리스트 ( List<Map<String, List<Map<String,Object>>>> )	 
	 */
	@SuppressWarnings("unused")
	private Map<String, List<Map<String, Object>>> groupedByAddr(List<Map<String, Object>> deviceList) {
		
		Map<String, List<Map<String, Object>>> groupAddrByDeviceList = new HashMap<String, List<Map<String,Object>>>();
		
		for(Map<String, Object> device : deviceList) {
			String addr = device.get("dv_addr").toString();
			
			// 키가 존재하지 않는 경우에만 값을 생성하고 추가해주는 함수
			// 키가 존재하면 : 해당 값을 반환
			// 키가 존재하지 않으면 : 새로운 값을 생성에 map에 추가 후 반환
			groupAddrByDeviceList.computeIfAbsent(addr, k -> new ArrayList<>()).add(device);
	
		}
		
		return groupAddrByDeviceList;
	}

	/**
	 * httpServlet을 이용한 on-device 장비와 실시간 스트리밍
	 * @httpServetRequest의parameter
	 *  - type: device에게 보낼 명령어(string)
	 *    - start: 실시간 video streaming 시작
	 *    - end: 실시간 video streaming 종료
	 *    - U: device의 화면을 위로 이동
	 *    - D: device의 화면을 아래로 이동
	 *    - L: device의 화면을 왼쪽으로 이동
	 *    - R: device의 화면을 오른쪽으로 이동
	 *  - id: 명령어를 보낼 device의 id(int) 
	 */
	@RequestMapping("/sendCommand")
	private String sendCommand(HttpServletRequest req, HttpServletResponse res){
		
		String returnStr = "실시간 디바이스와 송수신 실패";
		
		try {
			
			String id = req.getParameter("deviceId");
			
			//id 유효성 검사
			if(id == null || id.trim().isEmpty()) {
				throw new IllegalArgumentException("유효하지 않은 파라미터(id)");
			}
			
			// 디바이스 ID를 파라미터로 디바이스 IP를 조회
			String dvIp = getValidatedDvIp(id);
			
			//dvIp 유효성 검사
			if(dvIp == null || dvIp.trim().isEmpty()) {
				throw new IllegalArgumentException("유효하지 않은 device ID.");
			}
			
			//deviceIp를 url로 한 실시간 데이터 스트리밍
			boolean streamCheck = false;
			streamCheck = apiService.forwardStream(req, res, dvIp);
			if(!streamCheck) {
				return returnStr;
			}
			
			returnStr = "실시간 스트리밍 성공";
			return returnStr;
				
		} catch (IllegalArgumentException e) {
			logger.error("유효성 검사 오류: ",e);
			return returnStr;
			
		}
		
	}
	
	/**
	 * json 파일로 송신시 inputStream을 이용한 on-device 장비와 실시간 스트리밍
	 */
	@ResponseBody
	@PostMapping(
	  value = "/sendCommandToJSON",
	  consumes = MediaType.APPLICATION_JSON_VALUE,
	  produces = MediaType.APPLICATION_JSON_VALUE
	)
	private String sendCommandToJSON(@RequestBody HashMap<String, Object> json, HttpServletResponse res) {
		
		try {
			String id = json.get("deviceId").toString();
			
			//id 유효성 검사
			if(id == null || id.trim().isEmpty()) {
				throw new IllegalArgumentException("유효하지 않은 파라미터(id)");
			}
			
			// 디바이스 ID를 파라미터로 디바이스 IP를 조회
			String dvIp = getValidatedDvIp(id);
			
			//dvIp 유효성 검사
			if(dvIp == null || dvIp.trim().isEmpty()) {
				throw new IllegalArgumentException("유효하지 않은 device ID.");
			}
			
			// (15번 4-4) 명령 종류에 따라 디바이스 엔드포인트 분기.
			//   - 스트리밍 시작/종료(start·end) : module_d /video
			//   - 카메라 화각·줌(U·D·L·R·H·zoom) : module_d /tilting  ← 기존 엔드포인트 재사용
			//   기존에는 전부 /video 로 보내 틸팅 명령이 module_d 에서 무시되고 있었다.
			String cmdType = String.valueOf(json.get("type"));
			String devicePath = isTiltingCommand(cmdType) ? "/tilting" : "/video";

			String streamCheck;
			streamCheck = apiService.forwardStreamToJSON(res, json, dvIp, devicePath);
			if("error".equals(streamCheck)) {
				return "";
			}
			
			// (긴급복구 2026-07-16) 브라우저가 디바이스에 직접 접속하는 HLS URL. module_d 는 8087 로 listen 하므로 포트 필수.
			String playUrl = "https://" + withDevicePort(dvIp) + "/index.m3u8";
			String resultString = "";
			if("start".equals(json.get("type"))) {
				resultString = extractJsonObject(streamCheck,playUrl);
			}
			if("end".equals(json.get("type"))) {
				resultString = "{\"result\":null,\"playUrl\":null}";

			}
			// (15번 4-4 수정) 기존에는 ok 에 따옴표가 없어 '유효하지 않은 JSON' 이 내려갔고,
			//   프론트의 response.json() 이 예외를 던져 틸팅·줌이 항상 "실패" 로 처리되고 있었다.
			if(isTiltingCommand(String.valueOf(json.get("type")))) {
				resultString = "{\"result\":\"ok\",\"playUrl\":null}";
			}
			
			logger.info("resultString : " + resultString);
			
			return resultString;
			
		} catch (IllegalArgumentException e) {
			logger.error("유효성 검사 오류: ",e);
			return "";
		}

	}
	
	/**
	 * (긴급복구 2026-07-16) 디바이스 실시간 스트리밍 포트 임시 하드코딩.
	 *  module_d 는 .env PORT=8087 로 TLS listen 하는데 기존 코드는 포트 없이 https://{ip}(=443) 를 사용해 연결 실패했음.
	 *  dv_ip 에 이미 포트가 포함돼 있으면 그대로 사용. (ApiServiceImpl.withDevicePort 와 동일 규칙)
	 *  ※ 임시 조치 — 추후 properties/DB 로 이관 필요.
	 */
	private static final String DEVICE_STREAM_PORT = "8087";

	/**
	 * (15번 4-4) 카메라 조종 명령 여부. 화각 4방향 + 홈(H) + 줌.
	 *  이 명령들은 스트리밍(/video)이 아니라 module_d 의 /tilting 으로 보낸다.
	 */
	private static boolean isTiltingCommand(String type) {
		if (type == null) return false;
		switch (type) {
			case "U": case "D": case "L": case "R": case "H":
			case "zoomIn": case "zoomOut":
				return true;
			default:
				return false;
		}
	}

	private static String withDevicePort(String dvIp) {
		if (dvIp == null) return null;
		String host = dvIp.trim();
		return host.contains(":") ? host : host + ":" + DEVICE_STREAM_PORT;
	}

	/*
	 * 유효성 검사를 통한 dvId를 파라미터로 dvIp 조회
	 */
	private String getValidatedDvIp(String id) {
		
		String dvIp = null;
		
		try {
			// 파라미터 유효성 검사
			if(id == null || id.isEmpty()) {
				throw new IllegalArgumentException("device ID가 전달되지 않았습니다.");
			}
			
			// deviceId를 통해 deviceIp 조회
			dvIp = deviceListService.getDvIpByDvID(Integer.parseInt(id));
			
			//dvIp 유효성 검사
			if(dvIp == null || dvIp.trim().isEmpty()) {
				throw new IllegalArgumentException("유효하지 않은 device ID.");
			}
		} catch (IllegalArgumentException e) {
			logger.error("유효성 검사 오류: ",e);
		} 
		
		return dvIp;
		
	}
	
	//실시간 영상 팝업창
	@PostMapping("/viewRealTimeVideoPopup")
	public String viewRealTimeVideoPopup(@RequestParam("dvId") Integer dvId, Model model) {
		
		// ====== 유효성 검증 [S] ====== //
		// dvId 유효성 검증 (Injection 방어)
		if(dvId == null || dvId <= 0) {
			logger.warn("유효하지 않은 dvId 요청: {}", dvId);
			model.addAttribute("errorMessage", "유효하지 않은 디바이스 ID입니다.");
			return "error";
		}
		// ====== 유효성 검증 [E] ====== //
		
		model.addAttribute("deviceId", dvId);
		return "/popup/deviceList/realTimeVideoPopup";
	}
	
	// 디바이스 등록, 수정 팝업창
	@GetMapping("/viewDeviceInfoPopup")
	public String viewDeviceInfoPopup(
			@RequestParam(value = "dvId", required = false) Integer dvId
			, Model model
			) {
		
		// ====== 유효성 검증 [S] ====== //
		// dvId 유효성 검증 (Injection 방어)
		if(dvId != null && dvId <= 0) {
			logger.warn("유효하지 않은 dvId 요청: {}", dvId);
			model.addAttribute("errorMessage", "유효하지 않은 디바이스 ID입니다.");
			return "error";
		}

		if(dvId != null) {
			Map<String,Object> dvInfo = deviceListService.getDeviceInfo(dvId);
			model.addAttribute("dvInfo",dvInfo);
		}
		// ====== 유효성 검증 [E] ====== //	
		
		model.addAttribute("dvId", dvId);
		return "/popup/deviceList/deviceInfoPopup";
	}
	
	// 디바이스 삭제 팝업창
	@PostMapping("/viewDeleteDevicePopup")
	public String viewDeleteDevicePopup(Model model) {

		return "/popup/deviceList/deleteDevicePopup";
	}
	
	// 디바이스 등록
	@ResponseBody
	@PostMapping("/insertDeviceInfo")
	public Map<String, Object> insertDeviceInfo(
			@RequestParam("dvName") String dvName
			, @RequestParam("dvAddr") String dvAddr
			, @RequestParam(value = "dvAddrDetail", required = false) String dvAddrDetail
			, @RequestParam("dvIp") String dvIp
			, @RequestParam("dvSerialNumber") String dvSerialNumber
			, @RequestParam(value = "dvLat", required = false) String dvLat
			, @RequestParam(value = "dvLng", required = false) String dvLng
			) {
		
		// connetion 객체
		HttpURLConnection conn = null;
		
		// dv 상태
		Integer dvStatus = 1;
		
		// resultMap
		Map<String, Object> res = new HashMap<>();
		
		try {
			
			// ====== 유효성 검증 [S] ====== //
			// dvName 검증 (XSS, SQL Injection 방어)
			if (dvName == null || dvName.isEmpty()) {
				logger.warn("디바이스명이 비어있습니다.");
				res.put("ok", false);
				res.put("msg", "디바이스명은 필수입니다.");
				return res;
			}
			if (dvName.length() > 100 || containsDangerousPattern(dvName)) {
				logger.warn("유효하지 않은 dvName 요청: {}", dvName);
				res.put("ok", false);
				res.put("msg", "유효하지 않은 디바이스명입니다.");
				return res;
			}

			// dvAddr 검증 (XSS, SQL Injection 방어)
			if (dvAddr == null || dvAddr.isEmpty()) {
				logger.warn("디바이스 주소가 비어있습니다.");
				res.put("ok", false);
				res.put("msg", "디바이스 주소는 필수입니다.");
				return res;
			}
			if (dvAddr.length() > 200 || containsDangerousPattern(dvAddr)) {
				logger.warn("유효하지 않은 dvAddr 요청: {}", dvAddr);
				res.put("ok", false);
				res.put("msg", "유효하지 않은 디바이스 주소입니다.");
				return res;
			}

			// dvAddrDetail 검증 (선택 입력. XSS/SQLi 방어, 최대 200자)
			if (dvAddrDetail != null && !dvAddrDetail.isEmpty()
					&& (dvAddrDetail.length() > 200 || containsDangerousPattern(dvAddrDetail))) {
				logger.warn("유효하지 않은 dvAddrDetail 요청: {}", dvAddrDetail);
				res.put("ok", false);
				res.put("msg", "유효하지 않은 상세 주소입니다.");
				return res;
			}

			// dvIp 검증
			if (dvIp == null || dvIp.isEmpty()) {
				logger.warn("도메인 값이 비어있습니다.");
				res.put("ok", false);
				res.put("msg", "도메인은 필수입니다.");
				return res;
			}

			// serial number 검증 (XSS, SQL Injection 방어)
			if (dvSerialNumber == null || dvSerialNumber.isEmpty()) {
				logger.warn("SerialNumber가 비어있습니다.");
				res.put("ok", false);
				res.put("msg", "SerialNumber는 필수입니다.");
				return res;
			}
			if (dvSerialNumber.length() > 200 || containsDangerousPattern(dvSerialNumber)) {
				logger.warn("유효하지 않은 dvSerialNumber 요청: {}", dvSerialNumber);
				res.put("ok", false);
				res.put("msg", "유효하지 않은 SerialNumber입니다.");
				return res;
			}
			// ====== 유효성 검증 [E] ====== //
			
			// device 상태 확인
			// 추후 고도화 필요
			// conn = apiService.createPostConnection("https://" + dvIp, "", "application/json");
			conn = apiService.createPostConnection(dvIp, "", "application/json");
			if(conn == null || conn.getResponseCode() != 200) {
				dvStatus = 0;
			}
			
			
			// 좌표 정규화(지오코딩 값 또는 0). decimal(10,7) 범위 밖·비숫자는 0으로 방어(파싱오류·인젝션 방지)
			dvLat = normalizeCoord(dvLat);
			dvLng = normalizeCoord(dvLng);

			// 디바이스 등록
			deviceListService.insertDeviceInfo(dvName,dvAddr,dvAddrDetail,dvIp,dvStatus,dvSerialNumber,dvLat,dvLng);
			
			
		} catch (RuntimeException e) {
			logger.error("디바이스 등록 중 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg", "디바이스 등록 중 오류 발생");
			return res;
			
		} catch (IOException e2) {
			logger.error("디바이스 등록 중 connection 객체 생성 중 오류 발생 : ",e2);
			res.put("ok", false);
			res.put("msg", "connection 생성 중 오류 발생");
			return res;
		} finally {
	        if (conn != null) try { conn.disconnect(); } catch (Exception ignore) {logger.debug("",ignore);}
	    }
		
		res.put("ok", true);
		return res;
	}
	
	// 디바이스 수정
	@ResponseBody
	@PostMapping("/updateDeviceInfo")
	public Map<String,Object> updateDeviceInfo(
			@RequestParam("dvId") Integer dvId
			, @RequestParam("dvName") String dvName
			, @RequestParam("dvAddr") String dvAddr
			, @RequestParam(value = "dvAddrDetail", required = false) String dvAddrDetail
			, @RequestParam("dvIp") String dvIp
			, @RequestParam("dvSerialNumber") String dvSerialNumber
			, @RequestParam(value = "dvLat", required = false) String dvLat
			, @RequestParam(value = "dvLng", required = false) String dvLng
			) {
		
		// connetion 객체
		HttpURLConnection conn = null;
		
		// dv 상태(1 = 정상, 0 = 비정상)
		Integer dvStatus = 1;
		
		// resultMap
		Map<String, Object> res = new HashMap<>();
		
		try {
			
			// ====== 유효성 검증 [S] ====== //
						// dvId 유효성 검증 (Injection 방어)
						if(dvId == null || dvId <= 0) {
							logger.warn("유효하지 않은 dvId 요청: {}", dvId);
							res.put("ok", false);
							res.put("msg", "유효하지 않은 디바이스 ID입니다.");
							return res;
						}

						// dvName 검증 (XSS, SQL Injection 방어)
						if (dvName == null || dvName.isEmpty()) {
							logger.warn("디바이스명이 비어있습니다.");
							res.put("ok", false);
							res.put("msg", "디바이스명은 필수입니다.");
							return res;
						}
						if (dvName.length() > 100 || containsDangerousPattern(dvName)) {
							logger.warn("유효하지 않은 dvName 요청: {}", dvName);
							res.put("ok", false);
							res.put("msg", "유효하지 않은 디바이스명입니다.");
							return res;
						}

						// dvAddr 검증 (XSS, SQL Injection 방어)
						if (dvAddr == null || dvAddr.isEmpty()) {
							logger.warn("디바이스 주소가 비어있습니다.");
							res.put("ok", false);
							res.put("msg", "디바이스 주소는 필수입니다.");
							return res;
						}
						if (dvAddr.length() > 200 || containsDangerousPattern(dvAddr)) {
							logger.warn("유효하지 않은 dvAddr 요청: {}", dvAddr);
							res.put("ok", false);
							res.put("msg", "유효하지 않은 디바이스 주소입니다.");
							return res;
						}

						// dvAddrDetail 검증 (선택 입력. XSS/SQLi 방어, 최대 200자)
						if (dvAddrDetail != null && !dvAddrDetail.isEmpty()
								&& (dvAddrDetail.length() > 200 || containsDangerousPattern(dvAddrDetail))) {
							logger.warn("유효하지 않은 dvAddrDetail 요청: {}", dvAddrDetail);
							res.put("ok", false);
							res.put("msg", "유효하지 않은 상세 주소입니다.");
							return res;
						}

						// dvIp 검증 (IP 형식 검증)
						if (dvIp == null || dvIp.isEmpty()) {
							logger.warn("디바이스 IP가 비어있습니다.");
							res.put("ok", false);
							res.put("msg", "디바이스 IP는 필수입니다.");
							return res;
						}

						// serial number 검증 (XSS, SQL Injection 방어)
						if (dvSerialNumber == null || dvSerialNumber.isEmpty()) {
							logger.warn("SerialNumber가 비어있습니다.");
							res.put("ok", false);
							res.put("msg", "SerialNumber는 필수입니다.");
							return res;
						}
						if (dvSerialNumber.length() > 200 || containsDangerousPattern(dvSerialNumber)) {
							logger.warn("유효하지 않은 dvSerialNumber 요청: {}", dvSerialNumber);
							res.put("ok", false);
							res.put("msg", "유효하지 않은 SerialNumber입니다.");
							return res;
						}
						// ====== 유효성 검증 [E] ====== //
			
			
			// device 상태 확인
			// 추후 고도화 필요
			// conn = apiService.createPostConnection("https://" + dvIp, "", "application/json");
			conn = apiService.createPostConnection(dvIp, "", "application/json");
			if(conn == null || conn.getResponseCode() != 200) {
				dvStatus = 0;
			}
			
			// 좌표 정규화(지오코딩 값 또는 0)
			dvLat = normalizeCoord(dvLat);
			dvLng = normalizeCoord(dvLng);

			// 디바이스 수정
			deviceListService.updateDeviceInfo(dvId,dvName,dvAddr,dvAddrDetail,dvIp,dvStatus,dvSerialNumber,dvLat,dvLng);
			
			
		} catch (RuntimeException e) {
			logger.error("디바이스 수정 중 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg", "디바이스 수정 중 오류 발생");
			return res;
			
		} catch (IOException e2) {
			logger.error("디바이스 수정 중 connection 객체 생성 중 오류 발생 : ",e2);
			res.put("ok", false);
			res.put("msg", "connection 생성 중 오류 발생");
			return res;
		} finally {
	        if (conn != null) try { conn.disconnect(); } catch (Exception ignore) {logger.debug("",ignore);}
	    }
		
		res.put("ok", true);
		return res;
	}
	
	
	// 디바이스 삭제
	@ResponseBody
	@PostMapping("/deleteDeviceInfo")
	public Map<String,Object> deleteDeviceInfo(
			@RequestBody Map<String, List<Integer>> body
			) {
		
		Map<String, Object> res = new HashMap<>();
		
		try {
			
			// ====== 유효성 검증 [S] ====== //
			List<Integer> dvIds = body.get("dvIds");
			if(dvIds == null || dvIds.isEmpty()) {
				res.put("ok", false);
				res.put("msg","삭제할 데이터가 없습니다.");
				return res;
			}

			// dvIds 리스트 크기 검증
			if(dvIds.size() > 1000) {
				logger.warn("너무 많은 삭제 요청: {} 개", dvIds.size());
				res.put("ok", false);
				res.put("msg","한 번에 삭제할 수 있는 최대 개수를 초과했습니다.");
				return res;
			}

			// 각 dvId 유효성 검증
			for(Integer dvId : dvIds) {
				if(dvId == null || dvId <= 0) {
					logger.warn("유효하지 않은 dvId 포함: {}", dvId);
					res.put("ok", false);
					res.put("msg","유효하지 않은 디바이스 ID가 포함되어 있습니다.");
					return res;
				}
			}
			// ====== 유효성 검증 [E] ====== //
			
			
			// 디바이스 삭제
			deviceListService.deleteDeviceInfo(dvIds);
			
		} catch (RuntimeException e) {
			logger.error("디바이스 삭제 중 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg","디바이스 삭제 중 오류 발생.");
			return res;
			
		}
		
		res.put("ok", true);
		return res;
	}

	/**
	 * 디바이스명과 주소 중복 확인
	 * @param raw
	 * @return
	 */
	@PostMapping("/duplicatedNameAndAddr")
	@ResponseBody
	public Map<String,Object> duplicatedNameAndAddr(@RequestBody Map<String,Object> body){
		Map<String,Object> resultMap = new HashMap<String, Object>();

		try {
			// ====== 유효성 검증 [S] ====== //
			// dvName 검증
			String dvName = (String) body.get("dvName");
			if (dvName == null || dvName.isEmpty()) {
				resultMap.put("ok", false);
				resultMap.put("msg", "디바이스명은 필수입니다.");
				return resultMap;
			}
			if (dvName.length() > 100 || containsDangerousPattern(dvName)) {
				logger.warn("유효하지 않은 dvName 요청: {}", dvName);
				resultMap.put("ok", false);
				resultMap.put("msg", "유효하지 않은 디바이스명입니다.");
				return resultMap;
			}

			// dvAddr 검증
			String dvAddr = (String) body.get("dvAddr");
			if (dvAddr == null || dvAddr.isEmpty()) {
				resultMap.put("ok", false);
				resultMap.put("msg", "디바이스 주소는 필수입니다.");
				return resultMap;
			}
			if (dvAddr.length() > 200 || containsDangerousPattern(dvAddr)) {
				logger.warn("유효하지 않은 dvAddr 요청: {}", dvAddr);
				resultMap.put("ok", false);
				resultMap.put("msg", "유효하지 않은 디바이스 주소입니다.");
				return resultMap;
			}
			// ====== 유효성 검증 [E] ====== //

			boolean isDuplicated = deviceListService.duplicatedNameAndAddr(body);
			if(isDuplicated) {
				resultMap.put("ok",false);
				resultMap.put("msg","이미 같은 디바이스 명과 주소를 가진 디바이스가 등록되어 있습니다");
				return resultMap;
			}
			
			resultMap.put("ok", true);
			return resultMap;
		} catch (RuntimeException e) {
			logger.error("디바이스명과 주소를 중복체크하는 도중 오류 발생");
			resultMap.put("msg","디바이스명과 주소를 중복체크하는 도중 오류 발생");
			resultMap.put("ok",false);
			return resultMap;
		}
	}
	
	// 문자열 자르기
	@SuppressWarnings("unused")
	private static String extractJsonObject(String raw) {
	    if (raw == null) return null;
	    int s = raw.indexOf('{');
	    int e = raw.lastIndexOf('}');
	    if (s < 0 || e < s) return null;
	    return raw.substring(s, e + 1).trim();
	}
	
	// 문자열 자르기
	private static String extractJsonObject(String raw, String playUrl) {
	    if (raw == null) return null;
	    int s = raw.indexOf('{');
	    int e = raw.lastIndexOf('}');
	    if (s < 0 || e < s) return null;
	    
	    String inner = raw.substring(s + 1, e).trim(); // {와 } 사이
	    StringBuilder sb = new StringBuilder();
	    sb.append('{');
	    if (!inner.isEmpty()) {
	        sb.append(inner);
	        if (inner.charAt(inner.length() - 1) != ',') sb.append(',');
	    }
	    sb.append("\"playUrl\":\"").append(escapeJson(playUrl)).append("\"}");
	    return sb.toString();
	}
	
	private static String escapeJson(String s) {
	    if (s == null) return null;
	    StringBuilder sb = new StringBuilder(s.length() + 16);
	    for (int i = 0; i < s.length(); i++) {
	        char c = s.charAt(i);
	        switch (c) {
	            case '\\': sb.append("\\\\"); break;
	            case '"':  sb.append("\\\""); break;
	            case '\b': sb.append("\\b");  break;
	            case '\f': sb.append("\\f");  break;
	            case '\n': sb.append("\\n");  break;
	            case '\r': sb.append("\\r");  break;
	            case '\t': sb.append("\\t");  break;
	            default:
	                if (c < 0x20) sb.append(String.format("\\u%04x", (int)c));
	                else sb.append(c);
	        }
	    }
	    return sb.toString();
	}
	
	/**
	 * 좌표 문자열 정규화(patches 2026-07-07): decimal(10,7) 형태의 유효 숫자만 허용.
	 * null·빈값·비숫자·범위초과는 "0"(지도 미표시)으로 방어 → 파싱오류·인젝션 차단.
	 * @param v 위도 또는 경도 문자열
	 * @return 유효 숫자 문자열 또는 "0"
	 */
	private String normalizeCoord(String v) {
		if (v == null) return "0";
		v = v.trim();
		// 부호 + 정수부(최대 3자리) + 소수부(자리수 제한 없음).
		// (버그수정 2026-07-07) 카카오 지오코더는 고정밀 좌표(예: 37.5665683509886, 13자리)를 반환 →
		//   기존 소수 7자리 제한 정규식이 이를 탈락시켜 0으로 저장되던 문제 해소. DB decimal(10,7)이 7자리로 반올림.
		if (v.matches("^-?\\d{1,3}(\\.\\d+)?$")) {
			return v;
		}
		return "0";
	}

	/**
	 * 위험한 패턴 검사 (SQL Injection, XSS, Path Traversal 방어)
	 * @param input 검사할 문자열
	 * @return 위험한 패턴이 포함되어 있으면 true
	 */
	private boolean containsDangerousPattern(String input) {
		if (input == null || input.isEmpty()) {
			return false;
		}

		// 위험한 패턴 목록
		String[] dangerousPatterns = {
			"<script", "</script>", "javascript:", "onerror=", "onload=",  // XSS
			"'", "\"", "--", ";", "/*", "*/", "xp_", "sp_",  // SQL Injection
			"../", "..\\", "%2e%2e", "~",  // Path Traversal
			"<", ">", "&lt;", "&gt;",  // HTML 태그
			"union", "select", "insert", "update", "delete", "drop", "exec", "execute"  // SQL 키워드
		};

		String lowerInput = input.toLowerCase();
		for (String pattern : dangerousPatterns) {
			if (lowerInput.contains(pattern.toLowerCase())) {
				return true;
			}
		}

		return false;
	}
	
	/**
	 * 엑셀 다운로드
	 * @param startDate		이벤트 발생일 기준 검색 시작일(String)
	 * @param endDate		이벤트 발생일 기준 검색 종료일(String)
	 * @param searchKeyword	검색어
	 * @param response		HttpServletResponse 객체
	 */
	@PostMapping(
			value = "/excelDownload",
			consumes = "application/json",
			produces = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	@ResponseBody
	public void excelDownload(
			@RequestBody Map<String,Object> paramMap
			, HttpServletResponse response) {
		
		// ====== 디버깅 로그 [S] ======
		System.out.println("excelDownload map ; {}" + paramMap);
		logger.info("excelDownload map ; {}",paramMap);
		// ====== 디버깅 로그 [E] ======
		
		try {
			
			// ====== 서비스 [S] ======
			
			// 두 파라미터 값 0이 들어가지 않게 방어코드
			paramMap.put("recordCountPerPage", null);
			paramMap.put("firstIndex", null);
			
			// 데이터 가져오기
			List<Map<String, Object>> deviceList = deviceListService.getDeviceList(paramMap);
			
			System.out.println("deviceList { " + deviceList + " }");
			
			// 엑셀 컬럼 추가
		    List<ExcelColumn> columns = List.of(
	            new ExcelColumn("dv_name", "이름"),
	            new ExcelColumn("dv_addr", "주소"),
	            new ExcelColumn("dv_reg_date", "등록일")
	        );
		    
		    // 엑셀 시트 생성
		    ExcelSheetSpec sheet = ExcelSheetSpec.builder()
		            .sheetName("디바이스목록")
		            .columns(columns)
		            .data(deviceList)
		            .build();
		    
		    // 엑셀 파일 생성 및 다운로드
		    // 엑셀 파일명, 엑셀 시트, 다운로드를 위한 response 객체
		    excelService.download("디바이스_목록.xlsx", sheet, response);
			// ====== 서비스 [E] ======

		    
		} catch (Exception e) {
			logger.error("엑셀 파일 생성 중 오류 발생",e);
			return;
		}
		
	}
}

