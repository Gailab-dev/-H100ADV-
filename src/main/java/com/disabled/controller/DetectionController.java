package com.disabled.controller;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import com.disabled.mapper.DeviceListMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/** Authenticated operator -> edge capture -> cloud storage receipt. */
@Controller
@RequestMapping("/deviceList/detection")
public class DetectionController {
    @Autowired private DeviceListMapper devices;
    @Value("${H100_TRIGGER_TOKEN:}") private String triggerToken;
    private final ObjectMapper json = new ObjectMapper();

    @GetMapping("/token")
    @ResponseBody
    public ResponseEntity<?> token(HttpSession session) {
        if (session.getAttribute("uId") == null) return ResponseEntity.status(401).build();
        synchronized (session) {
            if (session.getAttribute("captureCsrf") == null) session.setAttribute("captureCsrf", UUID.randomUUID().toString());
            return ResponseEntity.ok().header("Cache-Control", "no-store").body(Map.of("token", session.getAttribute("captureCsrf")));
        }
    }

    @PostMapping("/{deviceId}")
    @ResponseBody
    public ResponseEntity<?> capture(@PathVariable int deviceId, @RequestBody Map<String,String> body,
            HttpServletRequest request, HttpSession session) {
        if (session.getAttribute("uId") == null) return failure(401, "로그인이 필요합니다.");
        String expected = (String) session.getAttribute("captureCsrf");
        String supplied = request.getHeader("X-H100-CSRF");
        if (expected == null || supplied == null || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8)))
            return failure(403, "요청 인증에 실패했습니다.");
        String requestId = body.get("request_id");
        if (requestId == null || !requestId.matches("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}") || deviceId <= 0)
            return failure(400, "잘못된 캡처 요청입니다.");
        if (triggerToken.isBlank()) return failure(503, "이상탐지 연결 설정이 없습니다.");
        HttpURLConnection connection = null;
        try {
            Map<String,Object> device = devices.getOneDeviceInfo(deviceId);
            if (device == null) return failure(404, "장비를 찾을 수 없습니다.");
            String host = String.valueOf(device.get("dv_ip"));
            String serial = String.valueOf(device.get("dv_serial_number"));
            // Address comes only from the registered device, never from the browser request.
            if (!host.matches("[A-Za-z0-9.-]+(:[0-9]{1,5})?") || !serial.matches("[0-9]{13}"))
                return failure(422, "장비 주소 또는 시리얼을 확인하십시오.");
            if (!host.contains(":")) host += ":8087";
            URI uri = new URI("https://" + host + "/detection/trigger");
            connection = (HttpURLConnection) uri.toURL().openConnection();
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(35000);
            connection.setInstanceFollowRedirects(false);
            connection.setRequestMethod("POST");
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Authorization", "Bearer " + triggerToken);
            byte[] payload = json.writeValueAsBytes(Map.of("request_id", requestId, "serial", serial));
            try (java.io.OutputStream out = connection.getOutputStream()) { out.write(payload); }
            int status = connection.getResponseCode();
            if (status != 200) return failure(502, "카메라 캡처 또는 관제 저장에 실패했습니다.");
            byte[] response;
            try (InputStream in = connection.getInputStream()) { response = in.readNBytes(4097); }
            if (response.length > 4096) return failure(502, "저장 결과를 확인할 수 없습니다.");
            JsonNode receipt = json.readTree(response);
            if (!receipt.path("ok").asBoolean() || receipt.path("event_id").asInt() <= 0 || !requestId.equals(receipt.path("request_id").asText()))
                return failure(502, "저장 결과를 확인할 수 없습니다.");
            return ResponseEntity.ok(receipt);
        } catch (Exception error) {
            // Never expose camera addresses, credentials, or upstream response bodies.
            return failure(502, "장비 연결 또는 캡처 저장에 실패했습니다.");
        } finally {
            if (connection != null) connection.disconnect();
        }
    }
    private ResponseEntity<?> failure(int status, String message) {
        return ResponseEntity.status(status).body(Map.of("ok", false, "msg", message));
    }
}
