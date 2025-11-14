package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.LocalMapper;
import com.disabled.service.LocalService;

@Service
@Transactional(rollbackFor = Exception.class)
public class LocalServiceImpl implements LocalService{
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(LocalServiceImpl.class);
	
	@Autowired
	LocalMapper localMapper;
	
	@Override
	public List<Map<String, Object>> getLocalList() {
		
		return localMapper.getLocalList();
	}

	@Override
	public Integer saveLocalManage(List<Map<String, Object>> mappedJson) {
		
		try {
			
			for (Map<String, Object> map : mappedJson) {
				
				String op = map.get("op").toString();
				Map<String, Object> data = (Map<String, Object>) map.get("data");
				
				if("delete".equals(op) ) {
					
					Integer rgId = Integer.parseInt(data.get("rg_id").toString());  
					Integer rows1 = localMapper.deleteLocalTreeNode(rgId);
					if(rows1 != 1) {
						throw new IllegalStateException("지역 노드 삭제 실패 (rg_id=" + rgId + ")");
						
					}
				}else {
					Integer rows1 = localMapper.InsertLocalTreeNode(data);
					if(rows1 != 1) {
						throw new IllegalStateException("지역 노드 등록 실패 (map=" + data.toString() + ")");
						
					}
				}
			}
			
			return 1;
			
		} catch (RuntimeException e) {
			logger.error("saveLocalManage에서 오류 발생 : ", e);
			throw e;
		}
	}
	
	/**
	 * 지역을 이용하는 사용자가 있는지 조회
	 */
	@Override
	public Map<String,Object> getUserUsingLocal(List<Map<String, Object>> mappedJson) {
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		Integer selectedUsers = null;
		
		try {
			
			for (Map<String, Object> map : mappedJson) {
				
				// 요청
				String op = map.get("op").toString();
				Map<String, Object> data = (Map<String, Object>) map.get("data");
				
				// 삭제 요청인 경우에만 해당 로직 진행
				if("delete".equals(op)) {
					
					Integer rgId = Integer.parseInt(data.get("rg_id").toString()); //rg_id, 삭제인 경우에만 파라미터에 포함
					String rgName = data.get("rg_name").toString(); // 지역 이름
					Integer rgDepth = Integer.parseInt(data.get("rg_depth").toString()); // 지역 depth
					
					List<String> FourDepRgNames = new ArrayList<String>();
					// 4depth가 아니라면, 4depth로 변환
					if(rgDepth != 4) {
						FourDepRgNames = localMapper.getFourDepRgNames(rgId);
						
					}else {
						
						// 해당 map이 4depth임으로 파라미터로 넣기
						FourDepRgNames = Collections.singletonList(rgName);
					}
					
					// 4depth가 없다면 다음 반복문으로
					if(FourDepRgNames == null || FourDepRgNames.isEmpty()) continue;
					
					// 검색 결과 삭제할 리스트에 해당 지역을 이용하는 사용자가 있다면, 반복을 종료하고 해당 사용자 리스트 리턴
					selectedUsers = localMapper.getCountUserUsingLocal(FourDepRgNames);
					if(selectedUsers > 0) {
						resultMap.put("rg_name", rgName);
						resultMap.put("selectedUsers", selectedUsers);
						
						return resultMap;
					}
				}

			}
			
			return null;
			
		} catch (RuntimeException e) {
			logger.error("getUserUsingLocal에서 오류 발생 : ", e);
			resultMap.put("e", e);
			return resultMap;
		}
		
	}
	
}
