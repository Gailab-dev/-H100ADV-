package com.disabled.service;

import java.net.HttpURLConnection;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface ApiService {
	HttpURLConnection createPostConnection(String targetUrl, String body, String contentType);
	void forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp);
	void copyResponse(HttpURLConnection conn, HttpServletResponse res);
	void forwardStreamToJSON(HttpServletResponse res, HashMap<String, Object> json, String dvIp, String path );
}
