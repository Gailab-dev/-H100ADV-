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
import org.springframework.beans.factory.annotation.Value;
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
	@SuppressWarnings("unused")
	@Autowired
	private ServletContext servletContext;
	
	// connection pool 관리
	@Autowired
	ConnectionPoolManager connectionPoolManager;
	
	//외부 파일 저장
	
	@Value("#{servletContext.getInitParameter('imgFilePath')}")
	private String imgFilePath;
	
	@Value("#{servletContext.getInitParameter('videoFilePath')}")
	private String videoFilePath;
	
	/**
	 * 실시간 영상 스트리밍
	 * @param req : HttpServletRequest 객체
	 * @param res : HttpServletResponse 객체
	 * @Param dvIp: 디바이스 IP주소 (String)
	 * 
	 */
	@Override
	public boolean forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp) {
		
		// content-type : application/x-www-form-urlencoded 
		String contentType = "application/x-www-form-urlencoded";
		
		// 디바이스Url
		String targetUrl = "https://" + dvIp +"/video";
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
	 * 실시간 영상 스트리밍을 위한 connection 생성
	 * @param targetUrl: 스트리밍을 할 device의 ip주소, port번호 등을 포함한 url
	 * @param body: 전송데이터
	 * @param contentType : 문자열 : application/x-www-form-urlencoded / JSON : application/json
	 * @return : HttpURLConnection 객체
	 */
	@Override
	public HttpURLConnection createPostConnection(String targetUrl, String body, String contentType) {
		
		logger.info("파라미터 정보 / targetUrl : " + targetUrl + " / body : " + body + " / contentType : " + contentType);
		
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
	        conn.setConnectTimeout(8000);  
	        conn.setReadTimeout(8000); 
	        
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
	 * @param conn : HttpURLConnection 객체
	 * @param res : HttpServletResponse 객체
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
		            }
		            
		            int code = conn.getResponseCode();
		            if(code != HttpURLConnection.HTTP_OK) {
		            	logger.error("응답코드 : " + code);
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
	 * 디바이스와 통신하여 이미지, 영상 파일 스트리밍하여 filePath에 저장
	 * @param conn : HttpURLConnection 객체
	 * @param filePath : 이미지, 영상 파일 저장할 파일 경로
	 * 
	 */
	public boolean fileResponse(HttpURLConnection conn, String filePath) {
		
		logger.info("파라미터 정보 / conn : " + conn + "/ filePath : " + filePath);
		
		java.nio.file.Path out = java.nio.file.Paths.get(filePath);
		
		try {
			
			// 1. 통신상태 200 체크
			if(conn.getResponseCode() != 200) {
				logger.error("통신 불가 : ",conn.getResponseCode());
				return false;
			}
			
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
        } catch (java.io.FileNotFoundException fnfe) {
            // RO FS일 때 가장 먼저 여기서 터짐 → 원인 메시지 명확히
            String parentWritable = "unknown";
            try 
            { 
            	parentWritable = String.valueOf(java.nio.file.Files.isWritable(out.getParent())); 
            } catch (Exception ignore) {
            	logger.error("외부 파일 시스템에서 쓰기 불가 오류 : ",ignore);
            	logger.error("부모 디렉토리 writable 여부 : ",parentWritable);
                return false;
            }
        } catch (IOException e) {
        	logger.error("fileResponse 에서 에러 발생 : ",e);
        	return false;
		}
		
		return true;
		
	}
	
	/**
	 * 송신 데이터 타입이 json객체일 때 실시간 영상 스트리밍
	 * @return tokenId : 디바이스에서 보내준 토큰 ID(String)
	 * @return error : 오류 발생시 'error'라는 문자열 보내기(String)
	 */
	@Override
	public String forwardStreamToJSON(HttpServletResponse res, HashMap<String, Object> json, String dvIp, String path ) {
		
		logger.info("파라미터 정보 / json : " + json + "/ dvIp : " + dvIp + " / path : " + path);
		
		// content-type : application/json 
		String contentType = "application/json";
		
		// connetion 객체
		HttpURLConnection conn = null;
		
		// 디바이스 Url
		String targetUrl = "";
		
		try {
			
			// 1. 입력 값 검증
			if(json == null || dvIp == null || dvIp.isBlank()) {
				logger.error("입력 값 검증시 오류!");
				return "error";
			}
			
	        // 2. JSON → 문자열(오류 방어 => catch문)
	        ObjectMapper mapper = new ObjectMapper();
	        String body = mapper.writeValueAsString(json);
			
        	// 3. 디바이스 Url 검증
        	// targetUrl = "https://" + dvIp + path;
        	targetUrl = "http://" + dvIp + path;
        	logger.info("통신할 디바이스 주소 : "+ targetUrl);
        	if(isValidUrl(targetUrl)) {
        		logger.error("targetUrl이 잘못되었습니다. : " + targetUrl);
        		return "error";
        	}
        	
        	// 4. connection pool 생성
    		conn = createPostConnection(targetUrl, body, contentType);
    		if(conn == null) {
    			logger.error("connection이 생성되지 않았습니다. / targetUrl : " + targetUrl + "body : " + body + "contentType : " + contentType);
    			return "error";
    		}	
    		
    		// 5. device와 통신 중 오류 발생시 오류코드
        	Integer code = conn.getResponseCode();
        	if(code != 200) {
        		logger.error("device와 통신중 오류 발생, 오류코드 : "+code);
        		return "error";
        	}
	        
	        
	        // 6. type 값 추출 
	        Object obj = json.get("type");
	        String type = "";
	        
	        if(obj != null) {
	        	type = obj.toString();
	        	
	        }else {
	        	logger.error("type 값 없음");
	        	return "error";
	        }
	        
	        // 7. type 값 별 분기 실행
	        // 7-1. 실시간 영상 스트리밍 
	        if(type.equals("start") | type.equals("end")) {
	        	
	        	// tokenId 수신
	            try (InputStream in = conn.getInputStream()) {
	                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
	            }
				
			// 7-2. 디바이스 화각 변경
	        } else if(type.equals("U") | type.equals("D") | type.equals("L") | type.equals("R")) {
	        	// 추후 고도화

	        	return "true";
	        
	        // 7-3. 이벤트 발생시 이미지, 영상 파일 송수신	
	        } else if(type.equals("image") | type.equals("video")) {
	        	
	        	String filePath = "";
	        	if(type.equals("image")) {
	        		filePath = imgFilePath + "/" + json.get("fileName");
	        	}else if(type.equals("video")) {
	        		filePath = videoFilePath + "/" + json.get("fileName");
	        	}
	        			
				// file stream
	        	boolean fileResponseCheck = fileResponse(conn, filePath);
	        	if (!fileResponseCheck) {
	        	    try {
	        	        logger.error("디바이스에서 이미지 파일 수신 실패 / url: " + conn.getURL() + " / filePath: "+filePath+" / parentWritable: "+java.nio.file.Files.isWritable(java.nio.file.Paths.get(filePath).getParent()));
	        	            
	        	    } catch (RuntimeException ignore) {
	        	    	logger.error("",ignore);
	        	    }
	        	    return "error";
	        	}
	        	
	        	return "true";
	        	
	        }  else {
	        	logger.error("잘못된 type 값 전송");
	        	return "error";
	        }
			
		} catch (JsonProcessingException e) {
			logger.error("JSON 변환 에러 : ",e);
			return "error";
		} catch(IOException e3) {
			logger.error("response 결과 200이 아님 : ",e3);
			return "error";
		} finally {
			// 모든 작업 후에도 conn 객체 남아 있다면 close
			try {
				if(conn != null) {
					conn.disconnect();
				}
			} catch (RuntimeException e2) {
				logger.error("connection 객체 disconnect 실패 : ",e2);
				return "error";
			}
		}
		
	}
	
	// url 검증
	private boolean isValidUrl(String Url) {
		
		if(Url == null) return false;
		return isValidIPv4(Url) || isValidDomain(Url);
		
	}
	
	// ip 검증
	private boolean isValidIPv4(String ip) {
	    String regex = 
	        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\.)){3}"
	        + "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";

	    return ip != null && ip.matches(regex);
	}
	
	// 도메인 검증
	private boolean isValidDomain(String domain) {
	    String regex =
	        "^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)\\."
	        + "([A-Za-z]{2,6}|[A-Za-z0-9-]{2,30}\\.[A-Za-z]{2,6})$";

	    return domain != null && domain.matches(regex);
	}
	
	
	
}
