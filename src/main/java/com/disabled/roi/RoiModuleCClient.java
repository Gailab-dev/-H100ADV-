package com.disabled.roi;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.SocketTimeoutException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * 웹(Java) -> module_c ROI 중계 호출(34번 작업계획서 §3, §6.2).
 *   POST {roi.modulec.base-url}/ROI_get | /ROI_snapshot | /ROI_send, Authorization: Bearer {roi.modulec.token}
 * 장비 주소·서명키는 module_c 가 다룬다. 이 클래스는 장비 주소를 알지 못하고, 오류 원문(주소·내부 메시지)은 로그에만 남긴다.
 * 시간 제한: Java -> module_c 13초(계획서 6.3), module_c -> module_d 12초, 웹 팝업 15초.
 */
@Component
public class RoiModuleCClient {
    private static final Logger logger = LoggerFactory.getLogger(RoiModuleCClient.class);
    private static final int MAX_RESPONSE_BYTES = 2 << 20;

    /** HTTP 응답을 받지 못한 경우의 종류. */
    public enum Failure { TIMEOUT, UNREACHABLE, NOT_CONFIGURED }

    /** module_c 응답. failure 가 null 이 아니면 HTTP 응답 자체가 없는 것(status=0). */
    public static final class Reply {
        public final int status;
        public final JsonNode body;
        public final Failure failure;

        Reply(int status, JsonNode body, Failure failure) {
            this.status = status;
            this.body = body;
            this.failure = failure;
        }

        public boolean ok() {
            return failure == null && status == 200 && body != null && body.path("ok").asBoolean(false);
        }
    }

    private final String baseUrl;
    private final String token;
    private final int connectTimeoutMs;
    private final int readTimeoutMs;

    public RoiModuleCClient(
            @Value("${roi.modulec.base-url:}") String baseUrl,
            @Value("${roi.modulec.token:}") String token,
            @Value("${roi.modulec.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${roi.modulec.read-timeout-ms:13000}") int readTimeoutMs) {
        this.baseUrl = baseUrl == null ? "" : baseUrl.trim().replaceAll("/+$", "");
        this.token = token == null ? "" : token.trim();
        this.connectTimeoutMs = connectTimeoutMs;
        this.readTimeoutMs = readTimeoutMs;
    }

    public Reply post(String path, Map<String, Object> payload) {
        if (baseUrl.isEmpty() || token.isEmpty()) {
            logger.error("[ROI] roi.modulec.base-url 또는 roi.modulec.token(H100_ROI_TOKEN) 이 설정되지 않았습니다");
            return new Reply(0, null, Failure.NOT_CONFIGURED);
        }
        HttpURLConnection conn = null;
        try {
            conn = (HttpURLConnection) URI.create(baseUrl + path).toURL().openConnection();
            conn.setConnectTimeout(connectTimeoutMs);
            conn.setReadTimeout(readTimeoutMs);
            conn.setInstanceFollowRedirects(false);
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Authorization", "Bearer " + token);
            byte[] body = RoiCodec.mapper().writeValueAsBytes(payload);
            try (OutputStream out = conn.getOutputStream()) {
                out.write(body);
            }
            int status = conn.getResponseCode();
            InputStream in = status >= 400 ? conn.getErrorStream() : conn.getInputStream();
            byte[] data = in == null ? new byte[0] : readLimited(in);
            JsonNode json = null;
            if (data.length > 0) {
                try {
                    json = RoiCodec.mapper().readTree(new String(data, StandardCharsets.UTF_8));
                } catch (IOException e) {
                    logger.warn("[ROI] module_c 응답을 JSON 으로 읽을 수 없음 (path={}, status={})", path, status);
                }
            }
            return new Reply(status, json, null);
        } catch (SocketTimeoutException e) {
            logger.warn("[ROI] module_c 응답 시간 초과 (path={})", path);
            return new Reply(0, null, Failure.TIMEOUT);
        } catch (IOException | RuntimeException e) {
            logger.warn("[ROI] module_c 호출 실패 (path={}): {}", path, e.toString());
            return new Reply(0, null, Failure.UNREACHABLE);
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static byte[] readLimited(InputStream in) throws IOException {
        try (InputStream is = in) {
            ByteArrayOutputStream buf = new ByteArrayOutputStream();
            byte[] chunk = new byte[8192];
            int n;
            while ((n = is.read(chunk)) > 0) {
                buf.write(chunk, 0, n);
                if (buf.size() > MAX_RESPONSE_BYTES) throw new IOException("응답이 너무 큽니다");
            }
            return buf.toByteArray();
        }
    }
}
