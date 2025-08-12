package com.disabled.service.impl;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.disabled.controller.DeviceListController;
import com.disabled.service.ApiService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

// 공통 api 모듈
@Service
public class ApiServiceImpl implements ApiService{
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	// 실시간 스트리밍을 위한 버퍼 크기
	private static final int BUFFER_SIZE = 8192;
	
	/**
	 * 실시간 영상 스트리밍
	 * @Param
	 * - dvIp: 디바이스 IP주소 (String)
	 */
	@Override
	public void forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp) {
		
		// GS인증시 지워야함
		System.out.println(dvIp);
		// GS인증시 지워야함
		
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
			copyResponse(conn, res);
			
		} catch (UnsupportedEncodingException e) {
			
			logger.error("connection pool 생성 오류 : {}",e);
			
		} finally {
			if (conn != null) conn.disconnect();
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
		
		System.out.println("createPostConnection in");
		
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
	        
	        // 실시간 스트리밍 결과 받기
	        try(OutputStream os = conn.getOutputStream()){
	        	
	        	os.write(body.getBytes(StandardCharsets.UTF_8));
	        }
	        
		} catch (MalformedURLException e) {
			
			logger.error("open connection 생성 에러 : ",e);
			
		} catch (IOException e) {
			logger.error("실시간 스트리밍 에러 : ",e);
			
		} finally {
			if(conn != null) {
				conn.disconnect();
			}
			
		}
		
		return conn;
	}
	
	/**
	 * 영상 스트리밍 결과 수신 및 전송
	 */
	@Override
	public void copyResponse(HttpURLConnection conn, HttpServletResponse res) {
		
		try {
			// 1. connection pool의 respose code와 contentType 설정값 설정
			res.setStatus(conn.getResponseCode());
			res.setContentType(conn.getContentType());
			
			// 2. connetion pool 객체가 연결되어 있는 동안 outputStream 객체 실행하여 데이터 수신
	        try (InputStream inputStream = conn.getInputStream();
                OutputStream outputStream = res.getOutputStream()) {
	           	
               byte[] buffer = new byte[BUFFER_SIZE];
               int bytesRead;
               
               // 3. outpusStream 객체에 받은 데이터 저장
               while ((bytesRead = inputStream.read(buffer)) != -1) {
                   outputStream.write(buffer, 0, bytesRead);
               }
               
               // 4. 받은 데이터를 실시간 스트리밍
               outputStream.flush();
            }
		} catch (IOException e) {
			
			logger.error("response 에러 :{}",e);
		} finally {
			if(conn != null) {
				conn.disconnect();
			}
		}
		
	}
	
	/**
	 * 송신 데이터 타입이 json객체일 때 실시간 영상 스트리밍
	 */
	@Override
	public void forwardStreamToJSON(HttpServletResponse res, HashMap<String, Object> json, String dvIp ) {
		
		// content-type : application/json 
		String contentType = "application/json";
		
		try {
			// 디바이스Url
			String targetUrl = "http://" + dvIp +"/video";
			
	        // 1. JSON → 문자열
	        ObjectMapper mapper = new ObjectMapper();
	        String body = mapper.writeValueAsString(json);
			
			// 2. connection pool 생성
			HttpURLConnection conn = createPostConnection(targetUrl, body, contentType);
			
			// 3. output Stream
			copyResponse(conn, res);
			
		} catch (JsonProcessingException e) {
			logger.error("JSON 변환 에러 : ",e);
		}
		
	}
}
