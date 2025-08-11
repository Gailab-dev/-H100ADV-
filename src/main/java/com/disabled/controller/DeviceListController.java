package com.disabled.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.ApiService;
import com.disabled.service.DeviceListService;
import com.sun.tools.javac.util.Log;

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
		
		//GS인증시 삭제
		System.out.println("deviceList rootRedirect");
		//GS인증시 삭제
		
		logger.info("deviceList rootRedirect");
		
		return "redirect:/deviceList/viewDeviceList.do";
	}
	
	// 디바이스 리스트 화면
	@RequestMapping("/viewDeviceList.do")
	private String viewDeviceList(Model model ) {
		
		logger.info("viewDeviceList in");
		
		// 디바이스 리스트
		List<Map<String, Object>> deviceList = new ArrayList<Map<String,Object>>();
		
		// 디바이스 리스트 가져오기
		deviceList = deviceListService.getDeviceList();
		
		// 주소 기준으로 그룹화 한 디바이스 리스트
		Map<String, List<Map<String, Object>>> groupAddrByDeviceList = new HashMap<String, List<Map<String,Object>>>();
				
		// 디바이스 리스트 주소별로 그룹화
		groupAddrByDeviceList = groupedByAddr(deviceList);
		
		//model add
		model.addAttribute("deviceList", groupAddrByDeviceList);
		
		//GS인증시 삭제
		System.out.println("return DeviceList");
		//GS인증시 삭제
		
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
	private void sendCommand(HttpServletRequest req, HttpServletResponse res){
		
		logger.info("sendCommand in");
		
		try {
			
			String id = req.getParameter("id");
			
			// 디바이스 ID를 파라미터로 디바이스 IP를 조회
			String dvIp = getValidatedDvIp(id);
			
			//deviceIp를 url로 한 실시간 데이터 스트리밍
			apiService.forwardStream(req, res, dvIp);
				
		} catch (Exception e) {
			
			// GS 인증시 삭제 필요
			System.out.println("영상 스트리밍 에러");
			e.printStackTrace();
			// GS 인증시 삭제 필요
			
			logger.error("DeviceListController의 SendCommand 로직에서 오류 발생 : {}",e.getMessage(),e);
		}
		
		
	}
	
	/*
	 * json 파일로 송신시 inputStream을 이용한 on-device 장비와 실시간 스트리밍
	 */
	@ResponseBody
	@RequestMapping("/sendCommandToJSON")
	private void sendCommandToJSON(@RequestBody HashMap<String, Object> json, HttpServletResponse res) {
		
		logger.info("sendCommandToJSON in");
		
		try {
			
			String id = json.get("id").toString();
			
			// 디바이스 ID를 파라미터로 디바이스 IP를 조회
			String dvIp = getValidatedDvIp(id);
			
			// 디바이스 IP를 통한 실시간 스트리밍
			apiService.forwardStreamToJSON(res, json,dvIp);
			
		} catch (Exception e) {
			
			logger.error("On-device와 실시간 스트리밍 중 오류 발생: {}"+e);
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
			return dvIp;
			
		} catch (Exception e) {
			
			logger.error("유효성 검사 소스코드에서 오류 발생: {}"+e);
			
			return "";
		}
		
		
	}
		
	
}

