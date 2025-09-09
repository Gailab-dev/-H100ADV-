package com.disabled.component;

import java.net.HttpURLConnection;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.disabled.controller.DeviceListController;

@Component
public class ConnectionPoolManager {
    
	// connection pool
	private final Map<String, HttpURLConnection> connectionPool = new ConcurrentHashMap<>();
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
    
    /**
     * 디바이스 IP에 해당하는 connection 객체를 Connection pool에서 저장 
     * @param dvIp : 디바이스 IP
     * @param conn : HttpURLConnection 객체 
     */
    public void addConnection(String dvIp, HttpURLConnection conn) {
    	
    	// 차후 고도화시 ID별로 conncetion 관리할 수 있도록 수정해야 함
    	// 현재 소스코드는 한 IP당 한 Connection만 유지할 수 있음
    	// 모든 connecion 종료
    	closeAll();
    	
    	connectionPool.put(dvIp, conn);
        logger.info("create connection for device {} at {}",dvIp,LocalDateTime.now());
    }
    
    /**
     * 디바이스 IP에 해당하는 connection 객체 가져오기	
     * @param dvIp : 디바이스 IP
     * @return HttpURLConnection 객체
     */
    public HttpURLConnection getConnection(String dvIp) {
    	logger.info("get connection for device {} at {}",dvIp,LocalDateTime.now());
        return connectionPool.get(dvIp);
    }
    
    /**
     * 디바이스 IP에 해당하는 connection 객체 종료
     */ 
    public void closeConnection(String dvIp) {
        HttpURLConnection conn = connectionPool.remove(dvIp);
        if (conn != null) {
            conn.disconnect();
            logger.info("disconnect connection for device {} at {}",dvIp,LocalDateTime.now());
        }
    }
    
    /**
     * 모든 connection pool 자원 할당 해제
     * 시스템 종료 등의 경우에 사용할 것
     */
    public void closeAll() {
        for (HttpURLConnection conn : connectionPool.values()) {
        	
            conn.disconnect();
        }
        connectionPool.clear();
        logger.info("All connection disconnect and connectionPool clear at {}",LocalDateTime.now());
    }
}
