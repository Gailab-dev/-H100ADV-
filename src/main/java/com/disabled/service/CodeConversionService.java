package com.disabled.service;

import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

@Service
public class CodeConversionService {
	
	/**
	 * statistics의 Stcd 코드의 integer값을 String으로 변환
	 * @param statsByMonth
	 * @return
	 */
	public List<Map<String,Object>> StCdConverstionIntToStr(List<Map<String,Object>> statistics){
		
		// 코드 별 숫자를 문자로 변환
		for (Iterator iterator = statistics.iterator(); iterator.hasNext();) {
			Map<String, Object> map = (Map<String, Object>) iterator.next();
			Integer stCd = Integer.parseInt(map.get("st_cd").toString());
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
		
		return statistics;
	}
}
