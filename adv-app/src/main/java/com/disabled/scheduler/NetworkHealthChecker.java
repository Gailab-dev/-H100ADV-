package com.disabled.scheduler;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.disabled.mapper.DeviceListMapper;

@Component
public class NetworkHealthChecker {

    private static final Logger logger = LoggerFactory.getLogger(NetworkHealthChecker.class);

	@Autowired
	DeviceListMapper deviceListMapper;

    private volatile boolean isRunning = false;

    /**
     * 1분마다 특정 IP/URL에 통신이 되는지 확인
     * cron = "초 분 시 일 월 요일"
     */
    @Scheduled(cron = "0 * * * * *")  // 매분 0초에 실행
    public void checkNetworkHealth() {
        // 동시 실행 방지
        if (isRunning) {
            logger.debug("이전 네트워크 체크가 아직 실행 중입니다. 이번 실행을 건너뜁니다.");
            return;
        }

        isRunning = true;
        logger.debug("네트워크 상태 체크 시작");

        try {
        	List<String> deviceIpList = deviceListMapper.getAllDvIp();

        	if(deviceIpList != null && !deviceIpList.isEmpty()) {
        		for(String DeviceIp : deviceIpList) {
        			HttpURLConnection connection = null;
        			String urlIp = "";

        			try {
        				urlIp = "https://" + DeviceIp;
        				URL url = new URL(urlIp);
        				connection = (HttpURLConnection) url.openConnection();
        				connection.setRequestMethod("GET");
        				connection.setConnectTimeout(5000);
        				connection.setReadTimeout(5000);

        				int responseCode = connection.getResponseCode();

        				if (responseCode >= 200 && responseCode < 300) {
        					deviceListMapper.updateDeviceStatus(1, DeviceIp);
        					logger.debug("네트워크 상태 정상: {} (응답코드: {})", urlIp, responseCode);
        				} else {
        					deviceListMapper.updateDeviceStatus(0, DeviceIp);
        					logger.debug("네트워크 응답 이상: {} (응답코드: {})", urlIp, responseCode);
        				}
        			} catch (Exception e) {
        				deviceListMapper.updateDeviceStatus(0, DeviceIp);
        				logger.debug("네트워크 통신 실패: {} (오류: {})", urlIp, e.getMessage());
        			} finally {
        	            if (connection != null) {
        	                connection.disconnect();
        	            }
        	        }
        		}
        	} else {
        		logger.warn("체크할 디바이스 IP가 없습니다.");
        	}
        } catch (Exception e) {
            logger.error("네트워크 통신 확인 중 오류 발생: {}", e.getMessage(), e);
        } finally {
            isRunning = false;
        }
    }
}
