package com.disabled.service;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cryptography.EgovPasswordEncoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.disabled.controller.DeviceListController;

@Service
public class CryptoARIAService {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	@Resource(name="passwordEncoder")
	private EgovPasswordEncoder passwordEncoder;
	
	public String encryptPassword(String plainText) {
		
		String encryptText = null;
		
		try {
			// 암호화
			encryptText = passwordEncoder.encryptPassword(plainText);
		} catch (Exception e) {
			logger.error("CrypoARIAService의 SHA-256 암호화 하는 도중 오류 발생: {}"+e);
		}
		
		return encryptText;
	}

}
