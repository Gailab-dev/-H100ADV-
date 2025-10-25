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
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.ApiService;
import com.disabled.service.DeviceListService;

@Controller
@RequestMapping("/deviceList")
public class DeviceListController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	@Autowired
	DeviceListService deviceListService;
	
	@Autowired
	ApiService apiService;
	
	// 디바이스 리스트 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/deviceList/viewDeviceList.do";
	}
	
	// 디바이스 리스트 화면
	@RequestMapping("/viewDeviceList.do")
	private String viewDeviceList(
			@RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", required=false) Integer page
			, Model model
			, HttpSession session  ) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 deviceList 화면 접속.", session.getAttribute("id"),LocalDateTime.now());
		
		// 페이지 null 방지
		if (page == null || page < 1) page = 1;
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 페이징 설정
		paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
		paginationInfo.setRecordCountPerPage(15);  // 한 페이지에 출력할 게시글 수
		paginationInfo.setPageSize(10); // 페이지 블록 수
		
		int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
		int totalRecordCount = deviceListService.getTotalRecordCount(searchKeyword);
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
		
		// 디바이스 리스트 가져오기
		List<Map<String, Object>> deviceList = deviceListService.getDeviceList(paramMap);
			
		// 디바이스 리스트 주소별로 그룹화
		// Map<String, List<Map<String, Object>>> groupAddrByDeviceList = groupedByAddr(deviceList);
		
		// 첫번째 디바이스 값 따로 분리
		// Integer firstDeviceId = (Integer) deviceList.get(0).get("dv_id");
		
		//model add
		// model.addAttribute("groupAddrByDeviceList", groupAddrByDeviceList);
		model.addAttribute("deviceList", deviceList);
		model.addAttribute("paginationInfo", paginationInfo);
		model.addAttribute("searchKeyword", searchKeyword == null ? "" : searchKeyword);
		// model.addAttribute("deviceId", firstDeviceId);
		
		return "/deviceList/deviceList";
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
			
			// 디바이스 IP를 통한 실시간 스트리밍
			String streamCheck;
			streamCheck = apiService.forwardStreamToJSON(res, json, dvIp, "/video");
			if("error".equals(streamCheck)) {
				return "";
			}
			
			String playUrl = "https://"+ dvIp+ "/index.m3u8";
			String resultString = "";
			if("start".equals(json.get("type"))) {
				resultString = extractJsonObject(streamCheck,playUrl);
			}
			if("end".equals(json.get("type"))) {
				resultString = "{\"result\":null,\"playUrl\":null}";

			}
			if("U".equals(json.get("type")) || "D".equals(json.get("type")) || "L".equals(json.get("type")) || "R".equals(json.get("type"))) {
				resultString = "{\"result\":ok,\"playUrl\":null}";
			}
			if("zoomIn".equals(json.get("type")) || "zoomOut".equals(json.get("type"))) {
				resultString = "{\"result\":ok,\"playUrl\":null}";
			}
			
			logger.info("resultString : " + resultString);
			
			return resultString;
			
		} catch (IllegalArgumentException e) {
			logger.error("유효성 검사 오류: ",e);
			return "";
		}

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
	public String viewRealTimeVideoPopup(Integer dvId, Model model) {
		
		model.addAttribute("deviceId", dvId);
		return "/popup/deviceList/realTimeVideoPopup";
	}
	
	// 디바이스 등록, 수정 팝업창
	@GetMapping("/viewDeviceInfoPopup")
	public String viewDeviceInfoPopup(
			@RequestParam(value = "dvId", required = false) Integer dvId
			, Model model
			) {
		
		if(dvId != null) {
			Map<String,Object> dvInfo = deviceListService.getDeviceInfo(dvId);
			model.addAttribute("dvInfo",dvInfo);
		}	
		
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
			, @RequestParam("dvIp") String dvIp
			) {
		
		// connetion 객체
		HttpURLConnection conn = null;
		
		// dv 상태
		Integer dvStatus = 1;
		
		// resultMap
		Map<String, Object> res = new HashMap<>();
		
		try {
			
			// device 상태 확인
			conn = apiService.createPostConnection(dvIp, "", "application/json");
			if(conn == null || conn.getResponseCode() != 200) {
				dvStatus = 0;
			}
			
			// 디바이스 등록
			deviceListService.insertDeviceInfo(dvName,dvAddr,dvIp,dvStatus);
			
			
		} catch (RuntimeException e) {
			logger.error("디바이스 등록 중 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg", "디바이스 수정 중 오류 발생");
			return res;
			
		} catch (IOException e) {
			logger.error("디바이스 등록 중 connection 객체 생성 중 오류 발생 : ",e);
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
			, @RequestParam("dvIp") String dvIp
			) {
		
		// connetion 객체
		HttpURLConnection conn = null;
		
		// dv 상태(1 = 정상, 0 = 비정상)
		Integer dvStatus = 1;
		
		// resultMap
		Map<String, Object> res = new HashMap<>();
		
		try {
			
			// device 상태 확인
			conn = apiService.createPostConnection(dvIp, "", "application/json");
			if(conn == null || conn.getResponseCode() != 200) {
				dvStatus = 0;
			}
			
			// 디바이스 수정
			deviceListService.updateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvStatus);
			
			
		} catch (RuntimeException e) {
			logger.error("디바이스 수정 중 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg", "디바이스 수정 중 오류 발생");
			return res;
			
		} catch (IOException e) {
			logger.error("디바이스 수정 중 connection 객체 생성 중 오류 발생 : ",e);
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
			
			List<Integer> dvIds = body.get("dvIds");
			if(dvIds == null || dvIds.isEmpty()) {
				res.put("ok", false);
				res.put("msg","삭제할 데이터가 없습니다.");
				return res;
			}
			
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
}

