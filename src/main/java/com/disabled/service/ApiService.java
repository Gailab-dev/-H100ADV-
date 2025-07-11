package com.disabled.service;

import java.net.HttpURLConnection;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface ApiService {
	void forwardStream(HttpServletRequest req, HttpServletResponse res, String dvIp);
	HttpURLConnection createPostConnection(String targetUrl, String body);
	void copyResponse(HttpURLConnection conn, HttpServletResponse res);
	void forwardStreamToJSON(HashMap<String, Object> json, String dvIp);
}
