package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
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
	private String viewDeviceList(Model model, HttpSession session  ) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 deviceList 화면 접속.", session.getAttribute("id"),LocalDateTime.now());
		
		// 디바이스 리스트
		List<Map<String, Object>> deviceList = new ArrayList<Map<String,Object>>();
		
		// 디바이스 리스트 가져오기
		deviceList = deviceListService.getDeviceList();
		
		// 주소 기준으로 그룹화 한 디바이스 리스트
		Map<String, List<Map<String, Object>>> groupAddrByDeviceList = new HashMap<String, List<Map<String,Object>>>();
				
		// 디바이스 리스트 주소별로 그룹화
		groupAddrByDeviceList = groupedByAddr(deviceList);
		
		// 첫번째 디바이스 값 따로 분리
		Integer firstDeviceId = (Integer) deviceList.get(0).get("dv_id");
		
		//model add
		model.addAttribute("deviceList", groupAddrByDeviceList);
		model.addAttribute("deviceId", firstDeviceId);
		
		return "/deviceList/deviceList";
	}
	
	/**
	 * 디바이스 리스트를 주소를 기준으로 그룹화하여 리턴
	 * @prarm 
	 *   - deviceList: 디바이스 리스트 ( List<Map<String,Object>> )
	 * @return
	 *   - groupAddrByDeviceList : 주소 기준으로 그룹화 된 디바이스 리스트 ( List<Map<String, List<Map<String,Object>>>> )	 
	 */
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
	
	/*
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
	
	// 문자열 자르기
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

