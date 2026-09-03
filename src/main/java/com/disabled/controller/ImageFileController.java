package com.disabled.controller;

import java.io.IOException;

import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import com.disabled.common.ImageByteLoader;

/**
 * 복호화된 불법주차 단속 이미지 스트리밍 (/imgFile/{fileName})
 *
 * eventListDetail.jsp 의 <img src="/imgFile/..."> 가 참조하는 경로였으나, 이 컨트롤러가 없어
 * 항상 404 였던 것을 신규 구현. ImageByteLoader(기존에 엑셀 다운로드 기능이 쓰던 서비스)를
 * 재사용해 image.dec.path 에 이미 복호화되어 있는 파일을 그대로 읽어 스트리밍한다.
 *
 * 이미지가 로컬에 없는 경우(디바이스 재수신 등)는 이 컨트롤러의 범위가 아니다 — 목록 화면에서
 * 상세 진입 전 /eventList/detail/check 로 사전검증해 로컬에 파일을 확보한 뒤 진입하는
 * ADR-008 흐름을 전제로 한다(eventListDetail.jsp 상단 주석 참조).
 */
@Controller
@RequestMapping("/imgFile")
public class ImageFileController {

	private static final Logger logger = LoggerFactory.getLogger(ImageFileController.class);

	@Autowired
	private ImageByteLoader imageByteLoader;

	@GetMapping("/{fileName:.+}")
	public void getImage(@PathVariable("fileName") String fileName, HttpServletResponse response) {
		try {
			byte[] bytes = imageByteLoader.readillegalParkingImage(fileName);
			if (bytes == null) {
				logger.info("[imgFile] 파일 없음: {}", fileName);
				response.setStatus(HttpServletResponse.SC_NOT_FOUND);
				return;
			}
			response.setContentType(contentTypeOf(fileName));
			response.setContentLengthLong(bytes.length);
			response.getOutputStream().write(bytes);
			response.getOutputStream().flush();
		} catch (SecurityException se) {
			logger.warn("[imgFile] 잘못된 파일 경로 요청: {}", fileName);
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
		} catch (IOException ioe) {
			logger.error("[imgFile] 이미지 스트리밍 실패: {}", fileName, ioe);
			if (!response.isCommitted()) {
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			}
		}
	}

	/** 확장자별 Content-Type (SipCallServiceImpl.contentTypeOf 와 동일 패턴) */
	private String contentTypeOf(String name) {
		String lower = name.toLowerCase();
		if (lower.endsWith(".png")) return "image/png";
		if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
		if (lower.endsWith(".gif")) return "image/gif";
		if (lower.endsWith(".webp")) return "image/webp";
		return "application/octet-stream";
	}
}
