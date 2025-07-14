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

import org.springframework.stereotype.Service;

import com.disabled.service.ApiService;

// 공통 api 모듈
@Service
public class ApiServiceImpl implements ApiService{
	
	// 실시간 스트리밍을 위한 버퍼 크기
	private static final int BUFFER_SIZE = 8192;
	
	/*
	 * 실시간 영상 스트리밍
	 */
	@Override
	public void forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp) {
		
		System.out.println(dvIp);
		
		// 디바이스Url
		String targetUrl = "http://" + dvIp +":8087/video";
		// connection 객체
		HttpURLConnection conn = null;
		// 인코딩 할 명령어
		String encodeCommand = "";
		
		try {
			// 1. 인코딩 설정
			encodeCommand = URLEncoder.encode(req.getParameter("type"), "UTF-8");
			
			// 2. connection pool 생성
			conn = createPostConnection(targetUrl, encodeCommand);
			
			// 3. output Stream
			copyResponse(conn, res);
			
		} catch (UnsupportedEncodingException e) {
			System.out.println("connection pool 생성 오류 : " + e);
			e.printStackTrace();
		} finally {
			if (conn != null) conn.disconnect();
			System.out.println("conn close");
		}
		
		
	}

	/*
	 * 실시간 영상 스트리밍을 위한 connection pool 생성
	 * @return : HttpURLConnection 객체
	 */
	@Override
	public HttpURLConnection createPostConnection(String targetUrl, String body) {
		
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
	        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	        System.out.println("create connection pool");
	        
	        // 실시간 스트리밍 결과 받기
	        try(OutputStream os = conn.getOutputStream()){
	        	System.out.println("outputStream ready");
	        	os.write(body.getBytes(StandardCharsets.UTF_8));
	        }
	        
		} catch (MalformedURLException e) {
			System.out.println("open connection 생성 에러");
			e.printStackTrace();
		} catch (IOException e) {
			System.out.println("");
			e.printStackTrace();
		}
		
		System.out.println("return conn");
		
		return conn;
	}
	
	/*
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
               
               System.out.println("outputStream flush");
               
               // 4. 받은 데이터를 실시간 스트리밍
               outputStream.flush();
            }
		} catch (IOException e) {
			System.out.println("response 에러");
			e.printStackTrace();
		}
		
	}
	
	/*
	 * 송신 데이터 타입이 json객체일 때 실시간 영상 스트리밍
	 */
	@Override
	public void forwardStreamToJSON(HashMap<String, Object> json, String dvIp) {
		
		System.out.println(dvIp);
		
		try {
			
		} catch (Exception e) {
			// TODO: handle exception
		}
		
	}
}
