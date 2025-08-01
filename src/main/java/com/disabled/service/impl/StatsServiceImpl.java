package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.ibatis.logging.LogException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.LoginMapper;
import com.disabled.mapper.StatsMapper;
import com.disabled.service.StatsService;

@Service
public class StatsServiceImpl implements StatsService{
	
	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	StatsMapper statsMapper;
	
	/*
	 * 아이디와 비밀번호를 통해 DB에 해당 계정이 있는지 확인
	 * @Param
	 * - id: 아이디(String)
	 * - pw: 비밀번호(String)
	 */
	@Override
	public Integer loginCheck(String id, String pwd) {
		// TODO Auto-generated method stub
		
		int cnt = 0;
		
		try {
			cnt = loginMapper.cntUsrByIdAndPwd(id,pwd);
			System.out.println(cnt);
			
			if(cnt != 1) {
				throw new LogException("로그인 실패");
			}else {
				return 1;
			}
		} catch (Exception e) {
			e.printStackTrace();
			// TODO: handle exception
			return -1;
		} 
	}
	
	/*
	 * 사용자의 검색 조건에 따른 통계 데이터를 조회하여 리스트로 반환
	 * @Param
	 * - startDate: 검색 시작일(String)
	 * - endDate: 검색 마지막일(String)
	 * - 
	 */
	@Override
	public List<Map<String, Object>> getEventByMonth(String startDate, String endDate) {
		
		List<Map<String, Object>> getEventByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			
			Map<String,Object> param = new HashMap<String, Object>();
			param.put("startDate", startDate);
			param.put("endDate", endDate);
			
			getEventByMonth = statsMapper.getEventByMonth(param);
		} catch (Exception e) {
			System.out.println("selcet 실패");
			// TODO: handle exception
		}
		
		return getEventByMonth;
	}
	
	/*
	 * 통계 데이터 화면에 출력
	 */
	@Override
	public List<Map<String, Object>> getEventByMonth() {
		List<Map<String, Object>> getEventByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			getEventByMonth = statsMapper.getAllEvent();
		} catch (Exception e) {
			System.out.println("selcet 실패");
			// TODO: handle exception
		}
		
		return getEventByMonth;
	}
	
}
