package com.disabled.service.impl;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.component.ConnectionPoolManager;
import com.disabled.service.ApiService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

// 공통 api 모듈
@Service
public class ApiServiceImpl implements ApiService{
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(ApiServiceImpl.class);
	
	// 실시간 스트리밍을 위한 버퍼 크기
	private static final int BUFFER_SIZE = 4096;
	
	//context path
	@Autowired
	private ServletContext servletContext;
	
	// connection pool 관리
	@Autowired
	ConnectionPoolManager connectionPoolManager;
	
	/**
	 * 실시간 영상 스트리밍
	 * @Param
	 * - dvIp: 디바이스 IP주소 (String)
	 */
	@Override
	public boolean forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp) {
		
		// content-type : application/x-www-form-urlencoded 
		String contentType = "application/x-www-form-urlencoded";
		
		// 디바이스Url
		String targetUrl = "http://" + dvIp +"/video";
		// connection 객체
		HttpURLConnection conn = null;
		// 인코딩 할 명령어
		String encodeCommand = "";
		
		try {
			// 1. 인코딩 설정
			encodeCommand = URLEncoder.encode(req.getParameter("type"), "UTF-8");
			
			// 2. connection pool 생성
			conn = createPostConnection(targetUrl, encodeCommand, contentType);
			
			// 3. output Stream
			boolean streamCheck = false;
			streamCheck = copyResponse(conn, res);
			if(!streamCheck) {
				return false;
			}else {
				return true;
			}
			
		} catch (UnsupportedEncodingException e) {
			
			logger.error("connection pool 생성 오류 : ",e);
			return false;
			
		} 
		
		
	}

	/**
	 * 실시간 영상 스트리밍을 위한 connection pool 생성
	 * 	- targetUrl: 스트리밍을 할 device의 ip주소, port번호 등을 포함한 url
	 *  - body: 전송데이터
	 *  - contentType : 문자열 : application/x-www-form-urlencoded / JSON : application/json
	 * @return : HttpURLConnection 객체
	 */
	@Override
	public HttpURLConnection createPostConnection(String targetUrl, String body, String contentType) {
		
		logger.info("파라미터 정보 / targetUrl : " + targetUrl + "/ body : " + body + "/ contentType : " + contentType);
		
		URL url = null;
		HttpURLConnection conn = null;
		
		try {
			
			// url 객체 생성
			url = new URL(targetUrl);
			
			// connection pool 생성
			conn = (HttpURLConnection) url.openConnection();
	        conn.setRequestMethod("POST");
	        conn.setDoOutput(true);
	        conn.setRequestProperty("Content-Type", contentType);
	        conn.setRequestProperty("Accept", "application/octet-stream");
	        
	        // 요청 송신
	        try(OutputStream os = conn.getOutputStream()){
	        	
	        	os.write(body.getBytes(StandardCharsets.UTF_8));
	        	os.flush();
	        }
	        
	        
		} catch (MalformedURLException e) {
			
			logger.error("createPostConnection에서 open connection 생성 에러 : ",e);
			return null;
			
		} catch (IOException e) {
			
			logger.error("createPostConnection에서 실시간 스트리밍 에러 : ",e);
			return null;
			
		}
		
		return conn;
	}
	
	/**
	 * 영상 스트리밍 결과 수신 및 전송
	 */
	@Override
	public boolean copyResponse(HttpURLConnection conn, HttpServletResponse res) {
		
		try {
			
			// 응답 수신
			try (InputStream is = conn.getInputStream();
		             BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
		            StringBuilder sb = new StringBuilder();
		            String line;
		            while ((line = br.readLine()) != null) {
		                sb.append(line);
		                logger.debug("Device로부터 응답 수신 : " + sb.toString());
		            }
		            
		            int code = conn.getResponseCode();
		            if(code != HttpURLConnection.HTTP_OK) {
		            	return false;
		            }else {
		            	return true;
		            }

            }
		} catch (IOException e) {
			logger.error("copyResponse 에서 에러 발생 : ",e);
			return false;
		} 
		
	}
	
	/**
	 * 
	 * @param conn
	 * @param res
	 */
	public boolean fileResponse(HttpURLConnection conn, String filePath) {
		
		logger.info("파라미터 정보 / conn : " + conn + "/ filePath : " + filePath);
		
		try {
		
			// 2. connetion pool 객체가 연결되어 있는 동안 outputStream 객체 실행하여 데이터 수신
			try (InputStream inputStream = conn.getInputStream();
					FileOutputStream fileOutputStream = new FileOutputStream(filePath)) {
           	
				byte[] buffer = new byte[BUFFER_SIZE];
				int bytesRead;
           
				// 3. outpusStream 객체에 받은 데이터 저장
				while ((bytesRead = inputStream.read(buffer)) != -1) {
					fileOutputStream.write(buffer, 0, bytesRead);
				}
           
				logger.info("파일 다운로드 성공 : " + filePath);
			}
        } catch (IOException e) {
        	logger.error("fileResponse 에서 에러 발생 : ",e);
        	return false;
		}
		
		return true;
		
	}
	
	/**
	 * 송신 데이터 타입이 json객체일 때 실시간 영상 스트리밍
	 */
	@Override
	public boolean forwardStreamToJSON(HttpServletResponse res, HashMap<String, Object> json, String dvIp, String path ) {
		
		logger.info("파라미터 정보 / json : " + json + "/ dvIp : " + dvIp + " / path : " + path);
		
		// content-type : application/json 
		String contentType = "application/json";
		
		// connetion 객체를 connection pool에서 가져오기
		HttpURLConnection conn = connectionPoolManager.getConnection(dvIp);
		
		// 디바이스 Url
		String targetUrl = "";
		
		try {

	        // 1. JSON → 문자열
	        ObjectMapper mapper = new ObjectMapper();
	        String body = mapper.writeValueAsString(json);
			
	        // 2. type 값 추출 
	        Object obj = json.get("type");
	        
	        
	        String type = "";
	        
	        if(obj != null) {
	        	type = obj.toString();
	        	
	        }else {
	        	logger.error("type 값 없음");
	        	return false;
	        }
	        
	        // 3. type 값 별 분기 실행
	        if(type.equals("start")) {
	        	
	        	//디바이스 Url
	        	targetUrl = "http://" + dvIp + path;
	        	logger.info("통신할 디바이스 주소 : "+ targetUrl);
	        	
	        	// 3-1. connection pool 생성
	        	if(conn == null) {
	        		// connectionPool에 해당 디바이스 IP에 해당하는 connection이 없다면 새로 생성
	        		conn = createPostConnection(targetUrl, body, contentType);
	        		if(conn == null) {
	        			logger.error("connection이 생성되지 않았습니다. / targetUrl : " + targetUrl + "body : " + body + "contentType : " + contentType);
	        			return false;
	        		}
	        			
	        		// connectionPool에 해당 디바이스 추가
	        		connectionPoolManager.addConnection(dvIp, conn);
	        	}
	        	
				// 3-2. output Stream
				boolean responseCheck = false;
				responseCheck = copyResponse(conn, res);
				if(!responseCheck) {
					logger.error("실시간 디바이스 통신 중, 실시간 데이터 수신 실패 / conn : " + conn + "res : " + res);
	        		connectionPoolManager.closeConnection(dvIp);
	        		conn.disconnect();
					return false;
				}
				
				return true;
				
	        } else if(type.equals("end")) {
	        	
	        	// 3-3. connection pool 종료
	        	if(conn != null) {
	        		
	        		connectionPoolManager.closeConnection(dvIp);
	        		conn.disconnect();
	        	}
	        	
	        	return true;
	        	
	        } else if(type.equals("U")) {
	        	// 추후 고도화
	        } else if(type.equals("D")) {
	        	// 추후 고도화
	        } else if(type.equals("L")) {
	        	// 추후 고도화
	        } else if(type.equals("R")) {
	        	// 추후 고도화
	        } else if(type.equals("image")) {
	        	
	        	//디바이스 Url
	        	targetUrl = "http://" + dvIp + path;
	        	logger.info("통신할 디바이스 주소 : "+ targetUrl);
	        	
	        	// 3-1. connection pool 생성
	        	if(conn == null) {
	        		// connectionPool에 해당 디바이스 IP에 해당하는 connection이 없다면 새로 생성
	        		conn = createPostConnection(targetUrl, body, contentType);
	        		if(conn == null) {
	        			logger.error("connection이 생성되지 않았습니다. / targetUrl : " + targetUrl + "body : " + body + "contentType : " + contentType);
	        			return false;
	        		}
	        		// connectionPool에 해당 디바이스 추가
	        		connectionPoolManager.addConnection(dvIp, conn);
	        	}
	        	
	        	String filePath = servletContext.getRealPath("/img") + "/" + json.get("fileName");
	        	
				// 3-2. file stream
	        	boolean fileResponseCheck = fileResponse(conn, filePath);
	        	if(!fileResponseCheck) {
	        		logger.error("디바이스에서 이미지 파일 수신 실패 / conn : " + conn + "filePath : " + filePath);
	        		return false;
	        	}
	        	
	        	// 3-3. connection pool 종료
	        	if(conn != null) {
	        		
	        		connectionPoolManager.closeConnection(dvIp);
	        		conn.disconnect();
	        	}
	        	
	        	return true;
	        } else if(type.equals("video")) {
	        	
	        	//디바이스 Url
	        	targetUrl = "http://" + dvIp + path;
	        	logger.info("통신할 디바이스 주소 : "+ targetUrl);
	        	
	        	// 3-1. connection pool 생성
	        	if(conn == null) {
	        		// connectionPool에 해당 디바이스 IP에 해당하는 connection이 없다면 새로 생성
	        		conn = createPostConnection(targetUrl, body, contentType);
	        		if(conn == null) {
	        			logger.error("connection이 생성되지 않았습니다. / targetUrl : " + targetUrl + "body : " + body + "contentType : " + contentType);
	        			return false;
	        		}
	        		
	        		// connectionPool에 해당 디바이스 추가
	        		connectionPoolManager.addConnection(dvIp, conn);
	        	}
	        	
	        	String filePath = servletContext.getRealPath("/img") + "/" + json.get("fileName");
	        	
				// 3-2. file stream
	        	boolean fileResponseCheck = fileResponse(conn, filePath);
	        	if(!fileResponseCheck) {
	        		logger.error("영상 파일 수신 실패 / conn : " + conn + "filePath : " + filePath);
	        		return false;
	        	}
	        	
	        	// 3-3. connection pool 종료
	        	if(conn != null) {
	        		
	        		connectionPoolManager.closeConnection(dvIp);
	        		conn.disconnect();
	        	}
	        	
	        	return true;
				
	        } else {
	        	logger.error("잘못된 type 값 전송");
	        	return false;
	        }
			
		} catch (JsonProcessingException e) {
			logger.error("JSON 변환 에러 : ",e);
			return false;
		} 
		
		return true;
		
	}
	
}
