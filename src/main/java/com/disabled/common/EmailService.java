package com.disabled.common;


import java.io.BufferedReader;
import java.io.InputStreamReader;
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
    /*
     * 앱 비밀번호 설정하는 방법
     * 구글 계정 - 구글 계정 관리
     * 보안 및 로그인
     * 2단계 인증( 2단계 인증 안 되어 있다면 2단계 인증 설정)
     * (페이지 하단) 앱 비밀번호
     * 앱 비밀번호 생성 또는 수정(h100)
     */
	public void sendAuthEmail(String email, String verifyUrl) {
		try {
	        String html = loadTemplate("templates/email-auth.html");
	        
	        // 인증 링크
	        html = html.replace("{{VERIFY_URL}}", verifyUrl);
		
		    MimeMessage message = mailSender.createMimeMessage();
		    MimeMessageHelper helper =
		        new MimeMessageHelper(message, true, "UTF-8");
		
		    helper.setTo(email);
		    helper.setSubject("[H100] 이메일 인증 안내");
		    helper.setText(html, true); // true = HTML
		    helper.setFrom("gailab.dev@gmail.com");
		    
		    System.out.println("mail host=" + ((org.springframework.mail.javamail.JavaMailSenderImpl)mailSender).getHost());
		    
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
