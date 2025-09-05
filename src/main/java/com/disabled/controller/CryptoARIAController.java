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
