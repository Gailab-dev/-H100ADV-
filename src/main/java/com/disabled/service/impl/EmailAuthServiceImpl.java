package com.disabled.service.impl;

import org.springframework.stereotype.Service;

import com.disabled.common.AuthCodeGenerator;
import com.disabled.service.EmailAuthService;

@Service
public class EmailAuthServiceImpl implements EmailAuthService{
	
	/**
	 * 숫자 0 ~ 9로 이루어진 6자리 문자열 인증코드 생성
	 * @return 숫자 0 ~ 9로 이루어진 6자리 문자열 
	 */
	@Override
	public String createAuthCode() {
		
		return AuthCodeGenerator.generate6DigitCode();
	}
	
}
