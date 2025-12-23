package com.disabled.component;

import javax.annotation.PreDestroy;

import org.springframework.beans.factory.annotation.Autowired;

public class ConnectionShutdownHook {
	
	@Autowired
    private ConnectionPoolManager connectionPoolManager;

    @PreDestroy
    public void cleanup() {
    	connectionPoolManager.closeAll();
    	
    }
}
