package com.disabled.scheduler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.disabled.mapper.DeviceListMapper;

@SuppressWarnings("unused")
@Component
public class NetworkHealthChecker {

	
    private static final Logger logger = LoggerFactory.getLogger(NetworkHealthChecker.class);

	@Autowired
	DeviceListMapper deviceListMapper;

    private volatile boolean isRunning = false;

    /**
     * 1분마다 특정 IP/URL에 통신이 되는지 확인
     * cron = "초 분 시 일 월 요일"
     *
     * ※ 비활성화 사유(2026-08-20 명시 — 최초 주석 처리는 2026-01-28 커밋 77ec1f4, 사유 미기재):
     *   디바이스 상태 확인 방식이 "서버가 주기적으로 디바이스 IP/URL에 접속해 응답 여부로 판단"하는
     *   이 폴링(pull) 방식에서, "디바이스가 자신의 상태를 주기적으로 서버에 직접 보고"하는
     *   푸시(push) 방식으로 고도화되었다(작업계획서 04번 — module_c의 POST /deviceStatus
     *   Heartbeat 수신, deviceStatus.go/DeviceListMapper.updateDeviceStatus 로 반영).
     *   따라서 이 클래스가 하던 능동적 접속 확인은 더 이상 필요하지 않다.
     *   소스코드 자체는 삭제하지 않고 아래 API 접속(HttpURLConnection) 로직만 계속 주석 처리 상태로
     *   유지한다 — 필요 시 참고·재사용 가능하도록 보존.
     */
//    @Scheduled(cron = "0 * * * * *")  // 매분 0초에 실행
    public void checkNetworkHealth() {
//        // 동시 실행 방지
//        if (isRunning) {
//            logger.debug("이전 네트워크 체크가 아직 실행 중입니다. 이번 실행을 건너뜁니다.");
//            return;
//        }
//
//        isRunning = true;
//        logger.debug("네트워크 상태 체크 시작");
//
//        try {
//        	List<String> deviceIpList = deviceListMapper.getAllDvIp();
//
//        	if(deviceIpList != null && !deviceIpList.isEmpty()) {
//        		for(String DeviceIp : deviceIpList) {
//        			HttpURLConnection connection = null;
//        			String urlIp = "";
//
//        			try {
//        				urlIp = "https://" + DeviceIp;
//        				URL url = new URL(urlIp);
//        				connection = (HttpURLConnection) url.openConnection();
//        				connection.setRequestMethod("GET");
//        				connection.setConnectTimeout(5000);
//        				connection.setReadTimeout(5000);
//
//        				int responseCode = connection.getResponseCode();
//
//        				if (responseCode >= 200 && responseCode < 300) {
//        					deviceListMapper.updateDeviceStatus(1, DeviceIp);
//        					logger.debug("네트워크 상태 정상: {} (응답코드: {})", urlIp, responseCode);
//        				} else {
//        					deviceListMapper.updateDeviceStatus(0, DeviceIp);
//        					logger.debug("네트워크 응답 이상: {} (응답코드: {})", urlIp, responseCode);
//        				}
//        			} catch (Exception e) {
//        				deviceListMapper.updateDeviceStatus(0, DeviceIp);
//        				logger.debug("네트워크 통신 실패: {} (오류: {})", urlIp, e.getMessage());
//        			} finally {
//        	            if (connection != null) {
//        	                connection.disconnect();
//        	            }
//        	        }
//        		}
//        	} else {
//        		logger.warn("체크할 디바이스 IP가 없습니다.");
//        	}
//        } catch (Exception e) {
//            logger.error("네트워크 통신 확인 중 오류 발생: {}", e.getMessage(), e);
//        } finally {
//            isRunning = false;
//        }
    }
}
