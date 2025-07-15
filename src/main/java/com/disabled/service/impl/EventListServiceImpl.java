package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.commons.collections.map.HashedMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.EventListMapper;
import com.disabled.service.EventListService;

@Service
public class EventListServiceImpl implements EventListService{
	
	@Autowired
	EventListMapper eventListMapper;
	
	@Override
	public List<Map<String, Object>> getEventList() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Integer getEventListCount() {
		// TODO Auto-generated method stub
		return null;
	}
	
	/*
	 * 불법 주차 리스트에서 이벤트 상세 내역을 DB에서 가져옴
	 * @Param
	 * - evId : 이벤트 ID
	 * @return
	 * - 이벤트 상새 내력(MAP)
	 */
	@Override
	public Map<String, Object> getEventListDetail(Integer evId) {
		
		Map<String, Object> resultMap = new HashedMap();
		
		try {
			// 이벤트 ID를 검색조건으로 하여 리스트 상세 내역을 select
			resultMap = eventListMapper.getEventListDetail(evId);
		} catch (Exception e) {
			System.out.println("이벤트 리스트 디테일 서비스 오류");
			// TODO: handle exception
		}
		
		return resultMap;
	}

	/*
	 * 불법 주차 리스트를 가져옴
	 * @param
	 * - paramMap: 불법 주차 리스트를 가져오기 위한 DB 검색 조건
	 *   > searchKeyword: 검색어
	 *   > startDate: 검색 시작 날짜
	 *   > endDate: 검색 마지막 날짜
	 * @return
	 * - 검색 조건에 부합하는 불법 주차 리스트(List)  
	 */
	@Override
	public List<Map<String, Object>> getEventList(Map<String, Object> paramMap) {
		
		List<Map<String, Object>> resultList = new ArrayList<Map<String,Object>>();
		
		try {
			// 검색 조건에 부합하는 불법 주차 리스트 select
			resultList = eventListMapper.getEventList(paramMap);
			
			System.out.println(resultList);
		} catch (Exception e) {
			System.out.println("이벤트 리스트 서비스 오류");
			System.out.println(e + "");
			// TODO: handle exception
		}
		
		return resultList;
		
	}

}
