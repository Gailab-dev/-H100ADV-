package com.disabled.service.impl;

import org.apache.ibatis.logging.LogException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.LoginMapper;
import com.disabled.service.StatsService;

@Service
public class StatsServiceImpl implements StatsService{
	
	@Autowired
	LoginMapper loginMapper;
	
	@Override
	public void loginCheck(String id, String pwd) {
		// TODO Auto-generated method stub
		
		int cnt = 0;
		
		try {
			cnt = loginMapper.cntUsrByIdAndPwd(id,pwd);
			System.out.println(cnt);
			
			if(cnt != 1) {
				throw new LogException("로그인 실패");
			};
		} catch (Exception e) {
			e.printStackTrace();
			// TODO: handle exception
		} 
	}
	
}
