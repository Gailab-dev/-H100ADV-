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

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLSession;
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
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

// 공통 api 모듈
@Service
public class ApiServiceImpl implements ApiService{
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(ApiServiceImpl.class);

	// (24번) 디바이스 파일 수신 실패 상세 전용 로그 — log4j2.xml의 com.disabled.deviceFileFetchError
	// 로거로 라우팅되어 일반 애플리케이션 로그와 섞이지 않고 별도 파일에 남는다.
	private static final Logger deviceFileFetchErrorLogger = LoggerFactory.getLogger("com.disabled.deviceFileFetchError");
	
	// 실시간 스트리밍을 위한 버퍼 크기
	private static final int BUFFER_SIZE = 4096;
	
	//context path
	@SuppressWarnings("unused")
	@Autowired
	private ServletContext servletContext;
	
	// connection pool 관리
	@Autowired
	ConnectionPoolManager connectionPoolManager;
	
	/**
	 * (긴급복구 2026-07-16) 디바이스 실시간 스트리밍 포트 임시 하드코딩.
	 *  - module_d 는 .env 의 PORT=8087 로 TLS listen 하는데, 기존 코드는 포트 없이 https://{ip} (=443) 로 호출해
	 *    연결 자체가 실패하고 있었음(실시간 영상 장애 1순위 원인).
	 *  - dv_ip 에 이미 포트가 포함된 경우(예: 192.168.0.31:8087)는 그대로 사용.
	 *  ※ 임시 조치 — 추후 properties(또는 DB 컬럼)로 이관 필요.
	 */
	private static final String DEVICE_STREAM_PORT = "8087";

	/** dvIp 에 포트가 없으면 스트리밍 포트를 붙여 반환 */
	private static String withDevicePort(String dvIp) {
		if (dvIp == null) return null;
		String host = dvIp.trim();
		return host.contains(":") ? host : host + ":" + DEVICE_STREAM_PORT;
	}

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
		String targetUrl = "https://" + withDevicePort(dvIp) + "/video";
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
	        conn.setConnectTimeout(5000);   // ADR-008(2026-06-17): 연결 5초 — 죽은 디바이스 빨리 실패
	        conn.setReadTimeout(10000);  // ADR-008(2026-06-17): 응답 10초 상한

	        /*
	         * (긴급복구 2026-07-21) 디바이스 인증서에 IP SAN 이 없어 기본 호스트명 검증에 실패하는 문제 대응.
	         *   - 현재 디바이스 인증서: CN=example.com, 자체서명, 확장(SAN) 없음
	         *   - Java 는 IP 로 접속할 때 CN 을 보지 않고 iPAddress SAN 만 확인 → 무조건 실패
	         *   - 인증서 '체인 검증'은 그대로 유지하고(= 트러스트스토어에 디바이스 인증서 등록 필요),
	         *     디바이스로 나가는 이 연결에 한해 '호스트명 검증'만 완화한다.
	         *   ※ 임시 조치 — 디바이스 인증서를 IP SAN 포함해 재발급하면 이 블록을 반드시 제거할 것.
	         *   ※ 전역(setDefaultHostnameVerifier) 적용 금지: 앱 전체 HTTPS 검증이 무력화됨.
	         */
	        if (conn instanceof HttpsURLConnection) {
	        	((HttpsURLConnection) conn).setHostnameVerifier(new HostnameVerifier() {
	        		@Override
	        		public boolean verify(String hostname, SSLSession session) {
	        			return true; // 체인 검증은 유지되므로, 신뢰된 인증서를 제시한 상대만 통과
	        		}
	        	});
	        }

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
	 * @param evId : 로깅용(선택, null 가능) — 디바이스로 나가는 요청 본문에는 포함되지 않는다
	 *
	 * (패치 2026-09-04) module_d 의 /fileSend 는 image/video 요청에도 실제 파일 바이트를 응답 본문에
	 * 담지 않는다는 사실이 확인되어(fileSend.go 참고 — 모든 타입이 결과 JSON만 응답), 이 메서드를 호출하던
	 * forwardStreamToJSON() 의 image/video 분기를 audio 와 동일한 패턴(응답을 그대로 반환, 실제 도착
	 * 여부는 호출측이 파일 존재로 확인)으로 통일하면서 현재 이 클래스 내 호출처가 없다. module_d 가
	 * 장래에 실제 바이너리를 direct-response 로 스트리밍하는 방식으로 바뀔 가능성을 대비해 보존해둔다
	 * — 완전히 불필요해졌다고 확정되면 isDeviceJsonConfirmation()/logDeviceFileFetchError() 와 함께
	 * 정리 대상.
	 */
	public boolean fileResponse(HttpURLConnection conn, String filePath, Object evId) {

		logger.info("파라미터 정보 / conn : " + conn + "/ filePath : " + filePath);

		java.nio.file.Path out = java.nio.file.Paths.get(filePath);

		try {

			// 1. 통신상태 200 체크
			if(conn.getResponseCode() != 200) {
				logger.error("통신 불가 : ",conn.getResponseCode());
				return false;
			}

			// (24번) 응답을 파일로 그대로 쓰기 전에 전체를 먼저 읽어, 실제 파일 바이너리가 아니라
			// 디바이스(module_d)가 반환하는 확인 JSON({"result":"false"} 등)인지 먼저 검증한다.
			// 기존에는 이 검증이 없어 실패 JSON 텍스트가 통째로 이미지/영상 파일로 저장되었다(2026-08-18 발견).
			byte[] bodyBytes;
			try (InputStream inputStream = conn.getInputStream()) {
				bodyBytes = inputStream.readAllBytes();
			}

			// (28번, evId=928 조사) 당시엔 동일 conn 에 대해 fileResponse() 가 filePath/filePath2 두 번
			// 호출되어, 이미 다 읽힌 스트림에서 두 번째 호출이 빈 바이트만 받는 구조적 문제가 있었다.
			// 그 이중 호출 자체는 (패치 2026-09-03) 이미지2를 완전히 분리된 별도 요청으로 바꾸며 제거했지만,
			// 빈 응답을 "실제 바이너리"로 오인해 0바이트 파일을 만드는 것은 원인과 무관하게 항상 막아야
			// 하므로 이 방어 코드는 그대로 유지한다.
			if (bodyBytes.length == 0) {
				logger.error("[ADR-008] 디바이스 응답 본문이 비어있음(이미 읽힌 connection 재사용 의심) evId={} url={} filePath={}",
						evId, conn.getURL(), filePath);
				logDeviceFileFetchError(evId, conn.getURL(), filePath, "(empty body)");
				return false;
			}

			// (28번) evId=928 재현으로 확인된 실제 버그 — 기존에는 result:false 만 실패로 간주했으나,
			// module_d 의 /fileSend 는 성공("result":"true")이든 실패("result":"false")든 항상 이런
			// JSON 확인 응답만 반환하며 실제 파일 바이트를 이 응답 본문에 담아 보내지 않는다(실제 파일은
			// module_d 가 module_c 의 /imageFileReceive 로 별도 비동기 업로드). 즉 result 값과 무관하게
			// JSON 확인 응답 자체가 "실제 파일이 아니다"라는 뜻이므로, result:true 도 동일하게 저장을
			// 거부해야 한다 — 그렇지 않으면 "{"result":"true"}" 18바이트가 이미지/영상 파일로 저장된다.
			if (isDeviceJsonConfirmation(conn.getContentType(), bodyBytes)) {
				String bodyPreview = new String(bodyBytes, StandardCharsets.UTF_8);
				logger.error("[ADR-008] 디바이스 응답이 실제 파일이 아니라 JSON 확인 응답임(저장 거부) evId={} url={} filePath={} body={}",
						evId, conn.getURL(), filePath, bodyPreview);
				logDeviceFileFetchError(evId, conn.getURL(), filePath, bodyPreview);
				return false;
			}

			// 2. 실제 파일 바이너리로 판단됨 — 저장
			java.nio.file.Path parentDir = out.getParent();
			if (parentDir != null) {
				java.nio.file.Files.createDirectories(parentDir);
			}
			try (FileOutputStream fileOutputStream = new FileOutputStream(filePath)) {
				fileOutputStream.write(bodyBytes);
			}

			logger.info("파일 다운로드 성공 : " + filePath);

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
	 * (24번 도입 → 28번 일반화) module_d 응답이 실제 파일이 아니라 JSON 확인 응답
	 * ({"result":"true"} 또는 {"result":"false"})인지 판별한다.
	 *
	 * (28번, evId=928 재현 확인) 처음에는 result:false 만 실패로 간주했으나, module_d의 /fileSend는
	 * 성공이든 실패든 항상 이런 JSON 확인 응답만 반환하고 실제 파일 바이트는 이 응답에 담지 않는다
	 * (파일은 module_d → module_c `/imageFileReceive` 로 별도 비동기 업로드). 즉 result 값의 진위와
	 * 무관하게 "이 본문이 JSON 확인 응답이라는 사실 자체"가 "실제 파일이 아니다"를 의미하므로,
	 * result:true 도 result:false 와 동일하게 저장 거부 대상이다.
	 *
	 * 우선순위:
	 *  1) Content-Type 이 image/video/octet-stream 등 명백한 바이너리 미디어 타입이면 무조건 실제 파일로 간주.
	 *     (module_d의 /fileSend 는 현재 성공·실패 모두 Content-Type: application/json 으로 응답하므로
	 *      이 경로가 실제로 걸러내지는 못하지만, 향후 module_d가 실제 바이너리를 스트리밍하도록
	 *      바뀌더라도 오탐 없이 동작하도록 남겨둔다.)
	 *  2) 그 외에는 본문을 JSON으로 파싱해 result 필드가 존재하는지만 확인한다(값은 true/false 무관).
	 *     JSON이 아니거나 result 필드가 없으면 실제 바이너리 파일로 간주한다.
	 *
	 * @param contentType 응답 Content-Type 헤더(널 가능)
	 * @param body        응답 본문 전체 바이트
	 * @return true: JSON 확인 응답으로 판단됨(저장하면 안 됨)
	 */
	private boolean isDeviceJsonConfirmation(String contentType, byte[] body) {
		if (contentType != null) {
			String ct = contentType.toLowerCase();
			if (ct.startsWith("image/") || ct.startsWith("video/") || ct.startsWith("application/octet-stream")) {
				return false; // 명백한 바이너리 미디어 — 확인 응답 아님
			}
		}
		if (body == null || body.length == 0 || body.length > 4096) {
			return false; // 확인 JSON 은 소량이다. 이 이상 크면 실제 파일로 간주
		}
		try {
			JsonNode node = new ObjectMapper().readTree(body);
			// (28번) result 값이 true/false 인지는 더 이상 따지지 않는다 — result 필드 존재 자체가
			// "실제 파일이 아닌 JSON 확인 응답"이라는 뜻이다.
			return node != null && node.hasNonNull("result");
		} catch (IOException ignore) {
			// JSON 파싱 실패 = 실제 바이너리 파일로 간주(의도된 동작)
		}
		return false;
	}

	/**
	 * (24번) 디바이스 파일 수신 실패 상세를 일반 애플리케이션 로그와 분리된 전용 로그 파일에 남긴다.
	 * 기록 내용: 발생 시각(로그 타임스탬프), evId, 요청 targetUrl, 저장하려던 filePath, 응답 본문 원문, 스레드명.
	 */
	private void logDeviceFileFetchError(Object evId, URL targetUrl, String filePath, String bodyPreview) {
		deviceFileFetchErrorLogger.error(
				"evId={} targetUrl={} filePath={} thread={} body={}",
				evId, targetUrl, filePath, Thread.currentThread().getName(), bodyPreview);
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
			
	        // (24번) evId 는 로깅 전용 메타데이터 — 디바이스로 나가는 요청 본문에는 포함하지 않도록
	        //   JSON 문자열 변환 전에 꺼내서 제거한다. 호출측이 넣지 않았다면 null.
	        Object evIdForLog = json.remove("_evId");

	        // 2. JSON → 문자열(오류 방어 => catch문)
	        ObjectMapper mapper = new ObjectMapper();
	        String body = mapper.writeValueAsString(json);
			
        	// 3. 디바이스 Url 검증
        	// targetUrl = "https://" + dvIp + path;
        	targetUrl = "https://" + withDevicePort(dvIp) + path;
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
				
			// 7-2. 디바이스 카메라 조종 — 화각 4방향 + 홈(H) + 줌
	        //   (15번 4-4) 기존에는 U·D·L·R 만 허용해 H·zoomIn·zoomOut 이 "잘못된 type" 으로 거부되고 있었다.
	        //   호출 경로는 DeviceListController 에서 module_d 의 /tilting 으로 지정한다.
	        } else if(type.equals("U") || type.equals("D") || type.equals("L") || type.equals("R")
	        		|| type.equals("H") || type.equals("zoomIn") || type.equals("zoomOut")) {

	        	// 디바이스가 200 을 반환한 시점에 명령 전달은 성공. 실제 카메라 구동 결과는 디바이스 담당 영역.
	        	return "true";
	        
	        // 7-3. (패치 2026-09-04) 이벤트 발생시 이미지·영상 파일 요청 — audio 타입과 동일하게 처리.
	        //   module_d(fileSend.go FileSendHandler)는 image/video/audio 세 타입 모두 동일한 방식으로
	        //   동작한다: 요청받은 파일을 module_c 의 별도 업로드 엔드포인트(/imageFileReceive,
	        //   /videoFileReceive, /audioFileReceive)로 비동기 전송한 뒤, 이 /fileSend 응답에는 항상
	        //   {"result":"true"/"false"} 확인 JSON만 돌려준다 — 실제 파일 바이트는 이 응답에 담기지 않는다.
	        //   기존 코드는 image/video 에 한해 이 확인 응답을 fileResponse() 로 "파일에 저장"하려다
	        //   28번 가드(JSON 확인 응답 저장 거부)에 걸려 항상 false 를 받고, 그걸 그대로 "error"로 취급해
	        //   반환했다. 그 결과 실제 파일이 (별도 업로드 경로로) 이미 정상 도착했더라도
	        //   fetchFromDevice() 는 파일 존재 여부를 확인해보기도 전에 매번 FAIL로 조기 종료되고 있었다
	        //   (1번 이미지는 있고 2번 이미지만 없는 이벤트에서 "첫 클릭 실패·재클릭 시 정상 표시"로
	        //   재현됨 — 재클릭 시점엔 비동기 업로드가 이미 끝나 있어 서버 파일 존재 확인만으로 성공 처리됨).
	        //   audio 타입은 처음부터 이 확인 응답을 그대로 반환하고 실제 도착 여부는 호출측이 파일
	        //   존재로 확인하도록 되어 있었다 — image/video 도 동일한 패턴으로 통일한다.
	        } else if(type.equals("image") | type.equals("video") | type.equals("audio")) {

	            try (InputStream in = conn.getInputStream()) {
	                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
	            }

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
