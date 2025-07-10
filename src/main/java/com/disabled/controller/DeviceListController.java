package com.disabled.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.ApiService;
import com.disabled.service.DeviceListService;

@Controller
@RequestMapping("/deviceList")
public class DeviceListController {
	
	@Autowired
	DeviceListService deviceListService;
	
	@Autowired
	ApiService apiService;
	
	// 디바이스 리스트 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		System.out.println("deviceList rootRedirect");
		
		return "redirect:/deviceList/viewDeviceList.do";
	}
	
	// 디바이스 리스트 화면
	@RequestMapping("/viewDeviceList.do")
	private String viewDeviceList(Model model ) {
		
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
		
		System.out.println("return DeviceList");
		
		return "/deviceList/deviceList";
	}
	
	/*
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

	/*
	 * httpServlet을 이용한 on-device 장비와 실시간 스트리밍
	 * 
	 */
	@RequestMapping("/sendCommand")
	private void sendCommand(HttpServletRequest req, HttpServletResponse res){
		
		try {
			
			// deviceId를 통해 deviceIp 조회
			String dvIp = deviceListService.getDvIpByDvID( Integer.parseInt(req.getParameter("id")));
			
			//deviceIp를 url로 한 실시간 데이터 스트리밍
			apiService.forwardStream(req, res, dvIp);
				
		} catch (Exception e) {
			System.out.println("영상 스트리밍 에러");
			e.printStackTrace();
		}
		
		
	}
		
	
}

