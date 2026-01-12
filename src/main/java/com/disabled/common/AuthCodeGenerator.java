package com.disabled.common;

import java.security.SecureRandom;

/**
 * 코드 생성만 전담하는 클레스
 * @author 지아이랩
 *
 */
public class AuthCodeGenerator {
    
	private static final SecureRandom random = new SecureRandom();
    
    /**
     * 숫자 0 ~ 9 까지 6개 코드 생성
     * @return
     */
    public static String generate6DigitCode() {
        StringBuilder sb = new StringBuilder(6);

        for (int i = 0; i < 6; i++) {
            sb.append(random.nextInt(10)); // 0 ~ 9
        }

        return sb.toString();
    }
}
