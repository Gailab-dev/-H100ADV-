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

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Service;

import com.disabled.service.ApiService;

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
		String targetUrl = "http://" + dvIp +":8087/control";
		// connection 객체
		HttpURLConnection conn = null;
		// 인코딩 할 명령어
		String encodeCommand = "";
		
		try {
			// 인코딩 설정
			encodeCommand = URLEncoder.encode(req.getParameter("command"), "UTF-8");
			
			// connection pool 생성
			conn = createPostConnection(targetUrl, encodeCommand);
			
			// output Stream
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
			
			// url 생성
			url = new URL(targetUrl);
			
			// connection pool 생성
			conn = (HttpURLConnection) url.openConnection();
	        conn.setRequestMethod("POST");
	        conn.setDoOutput(true);
	        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	        
	        // 실시간 스트리밍 결과 받기
	        try(OutputStream os = conn.getOutputStream()){
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
		// TODO Auto-generated method stub
		
		try {
			res.setStatus(conn.getResponseCode());
			res.setContentType(conn.getContentType());
			
	        try (InputStream inputStream = conn.getInputStream();
                OutputStream outputStream = res.getOutputStream()) {

               byte[] buffer = new byte[BUFFER_SIZE];
               int bytesRead;
               while ((bytesRead = inputStream.read(buffer)) != -1) {
                   outputStream.write(buffer, 0, bytesRead);
               }
               
               System.out.println("outputStream flush");
               
               outputStream.flush();
            }
		} catch (IOException e) {
			System.out.println("response 에러");
			e.printStackTrace();
		}
		
	}
}
