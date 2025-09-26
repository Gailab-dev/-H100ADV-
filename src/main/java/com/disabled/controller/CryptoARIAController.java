package com.disabled.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import com.disabled.service.CryptoARIAService;

@RestController
@RequestMapping("/crypto")
public class CryptoARIAController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(CryptoARIAController.class);
	
	@Autowired
	CryptoARIAService cryptoARIAService;
	
	/**
	 * 순수 문자열을 해시 암호화하여 암호화된 문자열을 반환
	 * @param plainText(String) : 암호화 전 문자열
	 * @return encryptText(String) : 해시 암호화 된 문자열
	 */
	@ResponseBody
	@PostMapping("/encryptPassword")
	public String cryptoPasswordController(@RequestBody String plainText) {
		
		String encryptText = null;
		
		try {
			
			// 암호화
			encryptText = cryptoARIAService.encryptPassword(plainText);
			
		} catch (RuntimeException e) {
			logger.error("cryptoPasswordController에서 오류 발생: {}",e);
		}
		
		return encryptText;
	}
}
