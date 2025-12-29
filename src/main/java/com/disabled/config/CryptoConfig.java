package com.disabled.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

@Configuration
@PropertySource("classpath:globals.properties")
public class CryptoConfig {

    @Value("${crypto.video.base64-key}")
    private String base64Key;

    @Bean
    public SecretKey videoSecretKey() {
        byte[] keyBytes = Base64.getDecoder().decode(base64Key);

        if (keyBytes.length != 32) {
            throw new IllegalArgumentException("AES-256 키는 32바이트여야 합니다. 현재: " + keyBytes.length + " bytes");
        }

        return new SecretKeySpec(keyBytes, "AES");
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
