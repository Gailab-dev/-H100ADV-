package com.disabled.common;


import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.mail.internet.MimeMessage;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
	
    @Autowired
    private JavaMailSender mailSender;
	
    /**
     * 회원 가입시 인증 이메일 보내기
     * @param baseUrl		http 또는 https
     * @param contextPath 	
     * @param email			이메일 주소(String)
     * @param authCode		인증 코드(String)
     */
	public void sendAuthEmail(String baseUrl, String contextPath, String email, String authCode) {
		try {
	        String html = loadTemplate("templates/email-auth.html");
	        
	        // 인증 링크
	        String verifyUrl = baseUrl + contextPath + "/user/verifyEmail.do?token=" + URLEncoder.encode(authCode, "UTF-8");
	        html = html.replace("{{VERIFY_URL}}", verifyUrl);
		
		    MimeMessage message = mailSender.createMimeMessage();
		    MimeMessageHelper helper =
		        new MimeMessageHelper(message, true, "UTF-8");
		
		    helper.setTo(email);
		    helper.setSubject("[H100] 이메일 인증 안내");
		    helper.setText(html, true); // true = HTML
		    helper.setFrom("no-reply@h100.co.kr");
		
		    mailSender.send(message);
	
		} catch (Exception e) {
			throw new RuntimeException("이메일 발송 실패", e);
	    }
	}
	
	/**
	 * 이메일 템플릿 파일 불러오기
	 * @param path			템플릿 파일 경로(string)
	 * @return
	 * @throws Exception
	 */
    private String loadTemplate(String path) throws Exception {
        ClassPathResource resource = new ClassPathResource(path);
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)
        );

        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
        return sb.toString();
    }
	
}
