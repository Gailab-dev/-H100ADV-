package com.disabled.common;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ImageByteLoader {
	
	// 이미지 읽어들이는 경로 = 복호화된 이미지 저장 경로
	@Value("${image.dec.path}")
    private String externalBaseDir;

    // 외부 저장소(디스크)에서 파일명/상대경로로 불법주차 단속 이미지를 byte[] 타입으로 읽기
    public byte[] readillegalParkingImage(String fileNameOrRelativePath) throws IOException {
        if (fileNameOrRelativePath == null || fileNameOrRelativePath.trim().isEmpty()) return null;

        System.out.println("externalBaseDir : " + externalBaseDir);
        
        Path base = Paths.get(externalBaseDir).toAbsolutePath().normalize();
        Path target = base.resolve(fileNameOrRelativePath).normalize();
        
        System.out.println("[IMG] base  =" + base);
        System.out.println("[IMG] input =" + fileNameOrRelativePath);
        System.out.println("[IMG] target=" + target);

        // Path Traversal 방어
        if (!target.startsWith(base)) {
            throw new SecurityException("Invalid path: " + fileNameOrRelativePath);
        }

        if (!Files.exists(target) || !Files.isRegularFile(target)) {
            return null; // 없으면 null (또는 예외로 처리)
        }

        // 너무 큰 파일 방어(예: 10MB)
        long size = Files.size(target);
        if (size > 10 * 1024 * 1024) {
            throw new IOException("File too large: " + size);
        }

        return Files.readAllBytes(target);
    }

    // 웹앱 내부(/resources/...) 정적 리소스 byte[] 읽기
    public byte[] readWebAppResource(javax.servlet.ServletContext sc, String webPath) throws IOException {
        try (InputStream is = sc.getResourceAsStream(webPath)) {
            if (is == null) return null;
            return is.readAllBytes();
        }
    }
}
