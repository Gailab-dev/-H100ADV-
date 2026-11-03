package com.disabled.service;

import java.net.HttpURLConnection;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface ApiService {
	HttpURLConnection createPostConnection(String targetUrl, String body, String contentType);
	boolean forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp);
	boolean copyResponse(HttpURLConnection conn, HttpServletResponse res);
	String forwardStreamToJSON(HttpServletResponse res, HashMap<String, Object> json, String dvIp, String path );
	/** 실시간 영상 start/end 를 module_d /video 로 전달하고 상태코드(status)·본문(body)을 그대로 돌려준다(409 등 비-200 포함). status 0 = 통신 실패 */
	HashMap<String, Object> forwardVideoCommand(HashMap<String, Object> json, String dvIp);
}
