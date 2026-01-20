package com.disabled.common;

import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

@Service
public class CodeConversionService {
	
	/**
	 * stCd 코드의 integer값을 String으로 변환
	 * @param listContainStCds stCd(유형) 값이 포함된 ArrayList
	 * @return
	 */
	public List<Map<String,Object>> StCdConverstionIntToStr(List<Map<String,Object>> listContainStCds){
		
		// 코드 별 숫자를 문자로 변환
		for (Iterator iterator = listContainStCds.iterator(); iterator.hasNext();) {
			Map<String, Object> map = (Map<String, Object>) iterator.next();
			
			Object stCdObj = map.get("st_cd");
			Integer stCd = null;
			if(stCdObj != null) {
				stCd = Integer.parseInt(stCdObj.toString());
			}else {
				continue;
			}
			
			switch (stCd) {
			case 1:
				map.put("st_cd", "미등록차량");
				break;
			// 2와 3은 추후 고도화
			case 2:
			case 3:
				break;
			case 4:
				map.put("st_cd", "위험상황");
				break;
			case 5:
				map.put("st_cd", "물건적재");
				break;
			case 6:
				map.put("st_cd", "이중주차");
			default:
				break;
			}
		}
		
		return listContainStCds;
	}
	
	/**
	 * evCd 코드의 integer값을 String으로 변환
	 * @param listContainevCds evCd(유형) 값이 포함된 ArrayList
	 * @return
	 */
	public List<Map<String,Object>> evCdConverstionIntToStr(List<Map<String,Object>> listContainEvCds){
		
		// 코드 별 숫자를 문자로 변환
		for (Iterator iterator = listContainEvCds.iterator(); iterator.hasNext();) {
			Map<String, Object> map = (Map<String, Object>) iterator.next();
			
			Object evCdObj = map.get("ev_cd");
			Integer evCd = null;
			if(evCdObj != null) {
				evCd  = Integer.parseInt(evCdObj.toString());
			}else {
				continue;
			}
			
			switch (evCd) {
			case 1:
				map.put("ev_cd", "미등록차량");
				break;
			// 2와 3은 추후 고도화
			case 2:
			case 3:
				break;
			case 4:
				map.put("ev_cd", "위험상황");
				break;
			case 5:
				map.put("ev_cd", "물건적재");
				break;
			case 6:
				map.put("ev_cd", "이중주차");
			default:
				break;
			}
		}
		
		return listContainEvCds;
	}
	
	/**
	 * evCd 코드의 integer값을 String으로 변환
	 * @param MapContainEvCds evCd(유형) 값이 포함된 Map
	 * @return
	 */
	public Map<String,Object> evCdConverstionIntToStr(Map<String,Object> MapContainEvCds){
		
		Object evCdObj = MapContainEvCds.get("ev_cd");
		Integer evCd = null;
		if(evCdObj != null && !"".equals(evCdObj.toString().trim())) {
			evCd = Integer.parseInt(evCdObj.toString());
		} else {
			return MapContainEvCds;
		}
		
		switch (evCd) {
		case 1:
			MapContainEvCds.put("ev_cd", "미등록차량");
			break;
		// 2와 3은 추후 고도화
		case 2:
		case 3:
			break;
		case 4:
			MapContainEvCds.put("ev_cd", "위험상황");
			break;
		case 5:
			MapContainEvCds.put("ev_cd", "물건적재");
			break;
		case 6:
			MapContainEvCds.put("ev_cd", "이중주차");
		default:
			break;
		}
		
		return MapContainEvCds;
	}
	
	
}
