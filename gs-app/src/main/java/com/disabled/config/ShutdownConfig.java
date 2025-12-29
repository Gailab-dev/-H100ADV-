package com.disabled.config;

import java.time.LocalDateTime;

import javax.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;

import com.disabled.component.ConnectionPoolManager;
import com.disabled.controller.DeviceListController;

@Configuration
public class ShutdownConfig {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	@Autowired
    private ConnectionPoolManager connectionPoolManager;

	/**
	 * 
	 */
    @PostConstruct
    public void registerHook() {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
        	
        	connectionPoolManager.closeAll();
        	logger.info("shutdown and close all connection at {}",LocalDateTime.now());
        }));
    }
}
