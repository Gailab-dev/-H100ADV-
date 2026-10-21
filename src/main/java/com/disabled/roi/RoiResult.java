package com.disabled.roi;

import java.util.LinkedHashMap;
import java.util.Map;

/** 서비스 -> 컨트롤러 전달용: HTTP 상태코드 + JSON 본문. 오류는 {ok:false, code, msg, ...}. */
public final class RoiResult {
    public final int status;
    public final Map<String, Object> body;

    private RoiResult(int status, Map<String, Object> body) {
        this.status = status;
        this.body = body;
    }

    public static RoiResult ok(Map<String, Object> body) {
        body.put("ok", true);
        return new RoiResult(200, body);
    }

    public static RoiResult error(int status, String code, String msg) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("ok", false);
        body.put("code", code);
        body.put("msg", msg);
        return new RoiResult(status, body);
    }

    /** 오류 본문에 항목을 덧붙인다(problems, currentHash, rhId 등). */
    public RoiResult with(String key, Object value) {
        body.put(key, value);
        return this;
    }
}
