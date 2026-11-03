package com.disabled.backup;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.NoRouteToHostException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;

import javax.net.ssl.SSLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.disabled.service.ApiService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 장비(module_d) /fileSend 로 "파일을 서버(module_c)로 보내라"고 요청하는 PULL 클라이언트.
 *
 * <p>연결 생성(TLS 설정 포함)은 상세보기·통화 재생과 같은 {@link ApiService#createPostConnection} 을 그대로 재사용한다
 * (같은 장비 인증서 처리·같은 요청 규약: POST JSON {type,fileName}, 연결 5초/응답 10초). 이 클래스는 응답의
 * code·bytes 를 해석하는 일만 따로 하며, 응답 10초를 넘기는 대용량 전송은 {@link #TIMEOUT} 으로 돌려주어
 * 호출측({@link DeviceFileFetcher})이 서버 디스크 도착을 더 기다려 판정한다.</p>
 *
 * <p>module_d 응답(계약 4.2): {"result":"true|false","code":"OK|NO_FILE|SERVER_REJECTED|SEND_FAILED","bytes":N}.
 * 구형 module_d 는 code·bytes 없이 result 만 준다.</p>
 */
@Component
public class DeviceFilePullClient {

	private static final Logger logger = LoggerFactory.getLogger(DeviceFilePullClient.class);

	private static final ObjectMapper MAPPER = new ObjectMapper();

	/** 응답 본문은 확인 JSON 이므로 작게 제한 */
	private static final int MAX_RESPONSE_BYTES = 64 * 1024;

	/** 장비 응답 대기 초과(전송이 아직 진행 중일 수 있음 — 서버 디스크 도착으로 판정해야 한다) */
	public static final String TIMEOUT = "TIMEOUT";

	@Autowired
	private FileBackupProperties props;

	@Autowired
	private ApiService apiService;

	/** PULL 호출 결과. transportError 가 있으면 장비 응답을 해석하지 못한 것 */
	public static final class PullResponse {
		/** DEVICE_UNREACHABLE/TIMEOUT/TLS_ERROR/IO_ERROR/HTTP_nnn/BAD_RESPONSE, 응답을 해석했으면 null */
		public final String transportError;
		/** module_d 의 result 필드(없으면 null) */
		public final Boolean result;
		/** module_d 의 code 필드(구형이면 null) */
		public final String code;
		/** module_d 가 보고한 전송 바이트(없으면 null) */
		public final Long bytes;

		PullResponse(String transportError, Boolean result, String code, Long bytes) {
			this.transportError = transportError;
			this.result = result;
			this.code = code;
			this.bytes = bytes;
		}

		static PullResponse transport(String error) {
			return new PullResponse(error, null, null, null);
		}
	}

	/**
	 * 장비에 파일 전송을 요청하고 응답을 해석한다.
	 * @param dvIp     tbl_device.dv_ip (포트가 없으면 file.backup.device-port 를 붙임)
	 * @param type     image / video / audio
	 * @param fileName DB 파일명(호출 전 {@link ServerFileLocator#isSafeName} 통과 필수)
	 */
	public PullResponse pull(String dvIp, String type, String fileName) {
		HttpURLConnection conn = null;
		try {
			String host = dvIp.trim();
			if (!host.contains(":")) {
				host = host + ":" + props.getDevicePort();
			}
			Map<String, Object> body = new HashMap<String, Object>();
			body.put("type", type);
			body.put("fileName", fileName);
			String json = MAPPER.writeValueAsString(body);

			// 연결 생성 + 요청 전송(연결 5초, 응답 10초는 ApiServiceImpl 의 기존 값)
			conn = apiService.createPostConnection("https://" + host + "/fileSend", json, "application/json");
			if (conn == null) {
				return PullResponse.transport("DEVICE_UNREACHABLE");
			}

			int status = conn.getResponseCode();
			byte[] respBody = readBounded(status >= 400 ? conn.getErrorStream() : conn.getInputStream());
			if (status != HttpURLConnection.HTTP_OK) {
				return PullResponse.transport("HTTP_" + status);
			}
			return parse(respBody);

		} catch (SocketTimeoutException e) {
			return PullResponse.transport(TIMEOUT);
		} catch (ConnectException | NoRouteToHostException | UnknownHostException e) {
			return PullResponse.transport("DEVICE_UNREACHABLE");
		} catch (SSLException e) {
			return PullResponse.transport("TLS_ERROR");
		} catch (IOException e) {
			logger.warn("[FileBackup] 장비 PULL 통신 오류 type={} file={} : {}", type, fileName, e.toString());
			return PullResponse.transport("IO_ERROR");
		} finally {
			if (conn != null) {
				try {
					conn.disconnect();
				} catch (RuntimeException ignore) {
					// 연결 정리 실패는 결과에 영향 없음
				}
			}
		}
	}

	private static byte[] readBounded(InputStream in) throws IOException {
		if (in == null) {
			return new byte[0];
		}
		try (InputStream is = in; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
			byte[] buf = new byte[4096];
			int n;
			while ((n = is.read(buf)) != -1) {
				if (out.size() + n > MAX_RESPONSE_BYTES) {
					break;
				}
				out.write(buf, 0, n);
			}
			return out.toByteArray();
		}
	}

	private static PullResponse parse(byte[] body) {
		if (body == null || body.length == 0) {
			return PullResponse.transport("BAD_RESPONSE");
		}
		try {
			JsonNode node = MAPPER.readTree(body);
			if (node == null || !node.isObject()) {
				return PullResponse.transport("BAD_RESPONSE");
			}
			Boolean result = null;
			if (node.hasNonNull("result")) {
				result = "true".equalsIgnoreCase(node.get("result").asText());
			}
			String code = node.hasNonNull("code") ? node.get("code").asText().trim() : null;
			if (code != null && code.isEmpty()) {
				code = null;
			}
			Long bytes = null;
			if (node.hasNonNull("bytes")) {
				JsonNode b = node.get("bytes");
				if (b.isNumber()) {
					bytes = b.asLong();
				} else {
					try {
						bytes = Long.parseLong(b.asText().trim());
					} catch (NumberFormatException ignore) {
						bytes = null;
					}
				}
			}
			if (result == null && code == null) {
				return PullResponse.transport("BAD_RESPONSE");
			}
			return new PullResponse(null, result, code, bytes);
		} catch (IOException e) {
			return PullResponse.transport("BAD_RESPONSE");
		}
	}
}
