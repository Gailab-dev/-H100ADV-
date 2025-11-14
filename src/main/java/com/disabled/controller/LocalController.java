package com.disabled.controller;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.LocalService;
import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

@Controller
@RequestMapping("/local")
public class LocalController {
		
		// 로그 기록
		private static final Logger logger = LoggerFactory.getLogger(LocalController.class);
		
		@Autowired
		LocalService localService;
		
		// 초기화면으로 redirect
		@RequestMapping("")
		public String rootRedirect() {
			
			return "redirect:/local/viewLocalManage.do";
		}
		
		/**
		 * 지역관리 화면이동
		 * @return
		 */
		@RequestMapping("/viewLocalManage.do")
		public String viewLocalManage(Model model) {
			
			// 결과 map
			List<Map<String,Object>> resultMap = localService.getLocalList();
			
			//json으로 직렬화
		    ObjectMapper om = new ObjectMapper();
		    om.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);

		    String resultJson = null;
			try {
				resultJson = om.writeValueAsString(resultMap);
				
		        // </script> 안전처리 (script 태그 안에 넣을 때만)
		        resultJson = resultJson.replace("</", "<\\/");
			} catch (JsonProcessingException e) {
				logger.error("viewLocalManage.do 에서 오류 발생, ",e);
			} // ★ 유효한 JSON 문자열
		    
		    model.addAttribute("resultJson", resultJson);
			return "/local/localManage";
		}
		
		
		@ResponseBody
		@PostMapping("/saveLocalManage")
		public Map<String,Object> saveLocalManage(
				@RequestBody List<Map<String,Object>> body ) throws JsonProcessingException{
			
			Map<String,Object> resultMap = new HashMap<String,Object>();
			
			try {
				
				System.out.println(body.toString());
				
				// 데이터 검증, 삭제 지역에 해당 지역을 이용하고 있는 사용자가 있다면 리턴
				Map<String,Object> selectResult = localService.getUserUsingLocal(body);
				if(selectResult != null && selectResult.get("e") == null) {
					resultMap.put("ok", false);
					resultMap.put("msg", selectResult.get("rg_name")+"지역을 이용하는 사용자가 "+selectResult.get("selectedUsers")+"명 있기 때문에 삭제할 수 없습니다.");
					return resultMap;
				} else if(selectResult != null && selectResult.get("e") != null) {
					resultMap.put("ok", false);
					resultMap.put("msg", "데이터 검증 도중 오류가 발생했습니다.");
					return resultMap;
				}
				
				// 변경내역 저장
				Integer row1 = localService.saveLocalManage(body);
				if(row1 != 1) {
					resultMap.put("ok", false);
					resultMap.put("msg", "지역 관리 화면 저장 중 오류 발생");
					return resultMap;
				}
				
				resultMap.put("ok", true);
				resultMap.put("msg", "저장되었습니다.");
				return resultMap;
				
			} catch (RuntimeException e) {
				logger.error("saveLocalManage에서 오류 발생 : ",e);
				resultMap.put("ok", false);
				resultMap.put("msg", "saveLocalManage에서 오류 발생");
				return resultMap;
			}
			
		}
		
		
		/**
		 * json 파싱
		 */
		private List<Map<String,Object>> parsingJson(String json) {
			
			List<Map<String,Object>> resultJson = new ArrayList<Map<String,Object>>();
			
	        ObjectMapper om = new ObjectMapper()
	                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
	                .configure(DeserializationFeature.ACCEPT_SINGLE_VALUE_AS_ARRAY, true)
	                .configure(DeserializationFeature.USE_BIG_DECIMAL_FOR_FLOATS, true); // 소수 정밀도 필요 시

	        try {
	        	resultJson = om.readValue(
				        json,
				        new TypeReference<List<Map<String,Object>>>() {}
				);
			} catch (JsonParseException e) {
				logger.error("json 파싱 중 오류 발생 : ", e);
				return null;
			} catch (JsonMappingException e) {
				logger.error("json mapping 중 오류 발생 : ", e);
				return null;
			} catch (IOException e) {
				logger.error("json 변환 중 오류 발생 : ", e);
				return null;
			}
			
			return resultJson;
			
		}

		@PostMapping("/openTreeNodePopup" )
		public String openTreeNodePopup(@RequestBody Map<String, Integer> body
				 // Integer rgDepth
				 // , Integer rgOrg
				// , Integer rgPId
                 , Model model
				) {
			
			// json값 바인딩
		    Integer rgDepth = body.get("rg_depth");
		    Integer rgOrg   = body.get("rg_org");
		    Integer rgPId   = body.get("rg_p_id");
			
		    // JSP 에 넘겨줄 값 세팅
		    model.addAttribute("rg_p_id", rgPId);
		    model.addAttribute("rg_depth", rgDepth);
		    model.addAttribute("rg_org", rgOrg);
			
			return "/popup/local/treeNodePopup";
		}
}
