package com.disabled.service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class VideoDecryptionService {

    private static final Logger logger = LoggerFactory.getLogger(VideoDecryptionService.class);

    private static final String TRANSFORMATION = "AES/CBC/PKCS5Padding";
    private static final int IV_SIZE = 16; // AES block size
    private static final int AES_256_KEY_BYTES = 32; // AES-256 = 32바이트 키

    /**
     * 디바이스 ↔ 웹 파일 암호화에 사용하는 AES-256 대칭키 (hex 문자열로 주입).
     *
     * [Phase 1 변경 이유]
     *  - 과거: 소스코드 상수 SECRET_KEY 를 SHA-256 해싱해 키 생성 → 키가 Git에 노출 + 예측 가능 + 로그 출력까지 됨
     *  - 변경: 환경변수 H100_AES_KEY (globals.properties: external.crypto.aes-key) 에서 64자 hex(=32바이트)를 직접 로드
     *  - 환경변수 값 자체가 고엔트로피 랜덤 키이므로 SHA-256 도출 단계 제거
     *
     * 보안 정책: 키 원문(hex/바이트)은 로그·예외 메시지·API 응답에 절대 출력하지 않는다.
     */
    @Value("${external.crypto.aes-key:}")
    private String aesKeyHex;

    /** 로드된 AES 키. 환경변수 미설정/형식오류 시 null 로 남고, 복호화 호출 시점에 명확히 실패한다. */
    private SecretKey videoSecretKey;

    /**
     * 시작 시 키 로드.
     *
     * 정책: 키가 없거나 형식이 틀려도 컨텍스트 기동은 막지 않는다(경고 로그만 남김).
     *      이유 — 복호화는 보조 기능이며, 키 부재로 웹 전체 가용성을 떨어뜨리지 않기 위함이다.
     *      실제 복호화가 호출되는 시점에 {@link #requireKey()} 가 명확한 예외를 던진다.
     */
    @PostConstruct
    private void initKey() {
        if (aesKeyHex == null || aesKeyHex.isBlank()) {
            logger.warn("[보안] 환경변수 H100_AES_KEY(external.crypto.aes-key) 미설정 — 복호화 호출 시 실패합니다. (부팅은 계속)");
            return;
        }
        try {
            byte[] keyBytes = HexFormat.of().parseHex(aesKeyHex.trim());
            if (keyBytes.length != AES_256_KEY_BYTES) {
                // 키 길이만 로그에 남기고 키 값은 남기지 않음
                logger.warn("[보안] H100_AES_KEY 길이가 {}바이트가 아님(현재 {}바이트) — 복호화 호출 시 실패합니다.",
                        AES_256_KEY_BYTES, keyBytes.length);
                return;
            }
            this.videoSecretKey = new SecretKeySpec(keyBytes, "AES");
            // 키 원문은 절대 로그에 남기지 않음. 로드 성공 사실과 길이만 기록.
            logger.info("VideoDecryptionService 초기화 완료 - AES-256 키 로드됨(길이 {} bytes)", keyBytes.length);
        } catch (IllegalArgumentException e) {
            // hex 파싱 실패(허용되지 않는 문자 등). 키 원문은 로그에 남기지 않음.
            logger.warn("[보안] H100_AES_KEY hex 파싱 실패 — 복호화 호출 시 실패합니다. (형식: 64자 hex)");
        }
    }

    /**
     * 복호화에 사용할 키 반환. 키가 로드되지 않았으면 명확한 예외를 던진다.
     * (부팅은 통과시키되, 실제 사용 시점에 실패시키는 정책의 집행 지점)
     *
     * @return 로드된 AES-256 키
     * @throws IllegalStateException 키 미로드 시
     */
    private SecretKey requireKey() {
        if (videoSecretKey == null) {
            throw new IllegalStateException(
                    "AES 키가 로드되지 않았습니다. 환경변수 H100_AES_KEY(64자 hex)를 설정하세요.");
        }
        return videoSecretKey;
    }

    /**
     * .enc 파일을 복호화하여 InputStream으로 반환
     * 파일의 첫 16바이트는 IV(Initialization Vector)로 사용됩니다.
     *
     * @param encryptedFile 암호화된 파일
     * @return 복호화된 데이터의 InputStream
     * @throws Exception 복호화 실패 시
     */
    public InputStream decryptFile(File encryptedFile) throws Exception {
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {
            // 첫 16바이트를 IV로 읽기
            byte[] iv = new byte[IV_SIZE];
            int ivBytesRead = fis.read(iv);

            if (ivBytesRead != IV_SIZE) {
                throw new IOException("IV를 읽을 수 없습니다. 파일이 올바르게 암호화되지 않았을 수 있습니다.");
            }

            // 나머지 암호화된 데이터 읽기
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int bytesRead;

            while ((bytesRead = fis.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }

            byte[] encryptedData = baos.toByteArray();

            // 복호화
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            cipher.init(Cipher.DECRYPT_MODE, requireKey(), ivSpec);

            byte[] decryptedData = cipher.doFinal(encryptedData);

            logger.info("파일 복호화 성공: {}", encryptedFile.getName());

            return new ByteArrayInputStream(decryptedData);

        } catch (Exception e) {
            logger.error("파일 복호화 실패: {}", encryptedFile.getName(), e);
            throw e;
        }
    }

    /**
     * .enc 파일을 복호화하여 스트리밍용 InputStream으로 반환
     * 메모리 효율적인 방식으로 대용량 파일도 처리 가능
     *
     * @param encryptedFilePath 암호화된 파일 경로
     * @return 복호화된 데이터의 InputStream
     * @throws Exception 복호화 실패 시
     */
    public InputStream decryptFileStreaming(String encryptedFilePath) throws Exception {
        File file = new File(encryptedFilePath);

        if (!file.exists()) {
            throw new FileNotFoundException("파일을 찾을 수 없습니다: " + encryptedFilePath);
        }

        return decryptFile(file);
    }

    /**
     * IV 없이 복호화 (IV가 파일에 포함되지 않은 경우)
     *
     * @param encryptedFile 암호화된 파일
     * @param iv IV 바이트 배열 (16 bytes)
     * @return 복호화된 데이터의 InputStream
     * @throws Exception 복호화 실패 시
     */
    public InputStream decryptFileWithIV(File encryptedFile, byte[] iv) throws Exception {
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int bytesRead;

            while ((bytesRead = fis.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }

            byte[] encryptedData = baos.toByteArray();

            // 복호화
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            cipher.init(Cipher.DECRYPT_MODE, requireKey(), ivSpec);

            byte[] decryptedData = cipher.doFinal(encryptedData);

            logger.info("파일 복호화 성공 (외부 IV 사용): {}", encryptedFile.getName());

            return new ByteArrayInputStream(decryptedData);

        } catch (Exception e) {
            logger.error("파일 복호화 실패 (외부 IV 사용): {}", encryptedFile.getName(), e);
            throw e;
        }
    }

    /**
     * .enc 파일을 복호화하여 파일로 저장, 일반 파일은 복사만 수행
     *
     * @param encryptedFilePath 암호화된 파일 경로
     * @param outputFilePath 복호화된 파일을 저장할 경로
     * @return true: 성공
     * @throws Exception 복호화 또는 저장 실패 시
     */
    public boolean decryptAndSaveFile(String encryptedFilePath, String outputFilePath) throws Exception {
        File encryptedFile = new File(encryptedFilePath);

        if (!encryptedFile.exists()) {
            throw new FileNotFoundException("파일을 찾을 수 없습니다: " + encryptedFilePath);
        }

        // (25번 도입 → 28번 일반화) .enc 여부와 무관하게, 원본이 디바이스 JSON 확인 응답
        // ({"result":"true"} 또는 {"result":"false"})인지 먼저 확인한다. PUSH로 정상 수신된 파일이
        // 이후 다른 경로(예: ApiServiceImpl의 검증 없는 저장)에 의해 확인 응답으로 덮어써진 경우,
        // 이 메서드가 그 내용을 그대로 복사/복호화해 dec 경로까지 오염시키는 것을 막기 위함이다
        // (2026-08-19~21 사고 — output_images_enc·output_images 양쪽 모두에서 {"result":"false"}
        // 뿐 아니라 {"result":"true"}(evId=928) 파일도 발견됨 → result 값과 무관하게 거부해야 함).
        if (isDeviceJsonConfirmation(encryptedFile)) {
            logger.error("원본 파일이 실제 미디어가 아니라 디바이스 JSON 확인 응답으로 확인됨 - 복사/복호화 거부: {}", encryptedFilePath);
            return false;
        }

        // .enc 파일이 아니면 복사만 수행
        if (!encryptedFilePath.endsWith(".enc")) {
            logger.info("암호화되지 않은 파일 - 복사만 수행: {}", encryptedFilePath);
            return copyFile(encryptedFilePath, outputFilePath);
        }

        // (요청사항) 파일명은 .enc 컨벤션이지만, 디바이스가 실제로는 암호화하지 않고 원문을
        // 그대로 보낸 경우가 있다 — 이 경우 AES 복호화를 시도하면 실패(IV/블록크기 오류)하거나
        // 잘못된 바이트가 나올 수 있으므로, 파일 내용의 매직 바이트로 평문 미디어인지 먼저 확인하고
        // 맞다면 복호화 없이 그대로 복사한다.
        if (looksLikePlainMedia(encryptedFile)) {
            logger.info("파일명은 .enc 이나 실제 내용은 암호화되지 않은 원문 미디어로 확인됨 - 복호화 없이 복사만 수행: {}", encryptedFilePath);
            return copyFile(encryptedFilePath, outputFilePath);
        }

        // .enc 파일인 경우 복호화 수행
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {
            // 파일 크기 확인
            long fileSize = encryptedFile.length();
            logger.info("암호화된 파일 크기: {} bytes", fileSize);

            // 첫 16바이트를 IV로 읽기
            byte[] iv = new byte[IV_SIZE];
            int ivBytesRead = fis.read(iv);

            if (ivBytesRead != IV_SIZE) {
                throw new IOException("IV를 읽을 수 없습니다. 파일이 올바르게 암호화되지 않았을 수 있습니다.");
            }

            // 디버깅: IV 확인
            logger.info("IV (hex): {}", bytesToHex(iv));

            // 나머지 암호화된 데이터 읽기
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int bytesRead;

            while ((bytesRead = fis.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }

            byte[] encryptedData = baos.toByteArray();
            logger.info("암호화된 데이터 크기: {} bytes", encryptedData.length);

            // 암호화된 데이터 검증
            if (encryptedData.length == 0) {
                logger.error("암호화된 데이터가 없습니다. 파일이 손상되었거나 IV만 존재합니다. 파일: {}", encryptedFilePath);
                return false;
            }

            if (encryptedData.length % 16 != 0) {
                logger.error("암호화된 데이터 크기({} bytes)가 16의 배수가 아닙니다. 파일이 손상되었거나 불완전하게 전송되었습니다. 파일: {}",
                        encryptedData.length, encryptedFilePath);
                return false;
            }

            // 키 정보 확인 (보안: 키 원문은 로그에 남기지 않음 — 알고리즘/길이만)
            logger.info("복호화 키 알고리즘: {}, 키 길이: {} bytes",
                    requireKey().getAlgorithm(),
                    requireKey().getEncoded().length);

            // 복호화
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            cipher.init(Cipher.DECRYPT_MODE, requireKey(), ivSpec);

            logger.info("복호화 시도 중...");
            byte[] decryptedData = cipher.doFinal(encryptedData);

            // 파일로 저장
            File outputFile = new File(outputFilePath);

            // 출력 디렉토리가 없으면 생성
            File parentDir = outputFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }

            try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                fos.write(decryptedData);
            }

            logger.info("파일 복호화 및 저장 성공: {} -> {}", encryptedFilePath, outputFilePath);

            return true;

        } catch (Exception e) {
            logger.error("파일 복호화 및 저장 실패: " + encryptedFilePath + " -> " + outputFilePath, e);
            throw e;
        }
    }

    /**
     * (25번 도입 → 28번 일반화) 파일이 실제 미디어가 아니라 디바이스(module_d)의 JSON 확인 응답
     * ({"result":"true"} 또는 {"result":"false"})인지 판별한다. 이런 확인 응답은 소량(수십 바이트)
     * 이므로 크기부터 걸러내고, 그 이하 크기만 JSON 파싱을 시도한다. JSON이 아니거나 result 필드가
     * 없으면 실제 파일로 간주한다(오탐 방지 — 아주 작은 정상 파일도 있을 수 있으므로 크기만으로
     * 거부하지 않고 반드시 JSON 파싱 + result 필드 존재까지 확인한다).
     *
     * (28번, evId=928) result 값의 true/false 는 더 이상 따지지 않는다 — module_d 의 응답 형식상
     * result:true 도 실제 파일 바이트가 아닌 확인 응답이므로 동일하게 거부해야 한다.
     *
     * @param file 확인할 파일
     * @return true: 디바이스 JSON 확인 응답으로 판단됨(복사·복호화하면 안 됨)
     */
    private boolean isDeviceJsonConfirmation(File file) {
        long size = file.length();
        if (size <= 0 || size > 4096) {
            return false;
        }
        byte[] bytes;
        try {
            bytes = Files.readAllBytes(file.toPath());
        } catch (IOException e) {
            return false;
        }
        try {
            JsonNode node = new ObjectMapper().readTree(bytes);
            return node != null && node.hasNonNull("result");
        } catch (IOException ignore) {
            // JSON 파싱 실패 = 실제 파일로 간주(의도된 동작)
        }
        return false;
    }

    /**
     * 파일의 앞부분(매직 바이트)을 읽어 이미지·영상·음성 파일 시그니처와 일치하는지 확인한다.
     * 파일명이 .enc 컨벤션이어도, 실제로는 디바이스가 암호화하지 않은 원문을 그대로 보낸 경우를
     * 걸러내기 위한 용도다(AES 암호문은 이런 시그니처와 우연히 일치할 확률이 사실상 0이다).
     *
     * @param file 확인할 파일(디스크상 실제 경로)
     * @return true: 알려진 평문 미디어 포맷 시그니처와 일치함
     */
    private boolean looksLikePlainMedia(File file) {
        byte[] head = new byte[16];
        int read;
        try (FileInputStream fis = new FileInputStream(file)) {
            read = fis.read(head);
        } catch (IOException e) {
            logger.warn("평문 여부 확인을 위한 파일 헤더 읽기 실패: {}", file.getAbsolutePath(), e);
            return false;
        }
        return read > 0 && isPlainMediaSignature(head, read);
    }

    /**
     * 파일 헤더 바이트를 알려진 이미지·영상·음성 포맷 매직 시그니처와 비교한다.
     *
     * @param head 파일 앞부분 바이트(최대 16바이트)
     * @param len  실제로 읽힌 바이트 수
     * @return true: 평문 미디어 포맷으로 판단됨
     */
    private static boolean isPlainMediaSignature(byte[] head, int len) {
        if (len >= 8 && (head[0] & 0xFF) == 0x89 && head[1] == 'P' && head[2] == 'N' && head[3] == 'G') {
            return true; // PNG
        }
        if (len >= 3 && (head[0] & 0xFF) == 0xFF && (head[1] & 0xFF) == 0xD8 && (head[2] & 0xFF) == 0xFF) {
            return true; // JPEG
        }
        if (len >= 4 && head[0] == 'G' && head[1] == 'I' && head[2] == 'F' && head[3] == '8') {
            return true; // GIF
        }
        if (len >= 2 && head[0] == 'B' && head[1] == 'M') {
            return true; // BMP
        }
        if (len >= 12 && head[0] == 'R' && head[1] == 'I' && head[2] == 'F' && head[3] == 'F') {
            return true; // RIFF 컨테이너 (WEBP/WAV/AVI)
        }
        if (len >= 8 && head[4] == 'f' && head[5] == 't' && head[6] == 'y' && head[7] == 'p') {
            return true; // MP4/MOV (ftyp 박스)
        }
        if (len >= 3 && head[0] == 'I' && head[1] == 'D' && head[2] == '3') {
            return true; // MP3 (ID3 태그)
        }
        if (len >= 2 && (head[0] & 0xFF) == 0xFF && (head[1] & 0xE0) == 0xE0) {
            return true; // MP3 프레임 동기(ID3 태그 없는 경우)
        }
        return false;
    }

    /**
     * 파일 복사 (암호화되지 않은 파일용)
     *
     * @param sourcePath 원본 파일 경로
     * @param destPath 목적지 파일 경로
     * @return true: 성공
     * @throws Exception 복사 실패 시
     */
    private boolean copyFile(String sourcePath, String destPath) throws Exception {
        try {
            File sourceFile = new File(sourcePath);
            File destFile = new File(destPath);

            // 출력 디렉토리가 없으면 생성
            File parentDir = destFile.getParentFile();
            if (parentDir != null && !parentDir.exists()) {
                parentDir.mkdirs();
            }

            // 파일 복사
            try (FileInputStream fis = new FileInputStream(sourceFile);
                 FileOutputStream fos = new FileOutputStream(destFile)) {

                byte[] buffer = new byte[8192];
                int bytesRead;

                while ((bytesRead = fis.read(buffer)) != -1) {
                    fos.write(buffer, 0, bytesRead);
                }
            }

            logger.info("파일 복사 성공: {} -> {}", sourcePath, destPath);
            return true;

        } catch (Exception e) {
            logger.error("파일 복사 실패: " + sourcePath + " -> " + destPath, e);
            throw e;
        }
    }

    /**
     * .enc 파일을 복호화하여 원본 파일명으로 저장 (.enc 확장자만 제거)
     *
     * @param fileName         파일명
     * @param encryptedFilePath 암호화된 파일 경로(디렉토리)
     * @param outputFilePath    복호화된 파일 경로(디렉토리)
     * @return true: 성공
     * @throws Exception 복호화 또는 저장 실패 시
     */
    public boolean decryptAndSaveFileAutoName1(String fileName, String encryptedFilePath, String outputFilePath) throws Exception {
        // fileName에서 .enc 빼기
        String fileNameTemp = fileName.replaceFirst("\\.enc$", "");

        // 전체 출력 파일 경로 생성
        String fullOutputPath = outputFilePath + File.separator + fileNameTemp;

        // output 파일 존재 여부 확인
        File outputFile = new File(fullOutputPath);

        // 파일이 이미 존재하면 복호화 안함
        if (outputFile.exists()) {
            logger.info("복호화된 파일이 이미 존재합니다. 기존 파일: {}", fullOutputPath);
            return true;
        }

        // 파일이 없으면 복호화 수행
        String fullEncryptedPath = encryptedFilePath + File.separator + fileName;
        logger.info("파일 복호화 시작: {} -> {}", fullEncryptedPath, fullOutputPath);

        return decryptAndSaveFile(fullEncryptedPath, fullOutputPath);
    }

    /**
     * 바이트 배열을 16진수 문자열로 변환 (디버깅용)
     */
    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

	public String decryptAndSaveFileAutoName(List<String> paramList, String encryptedFilePath, String outputFilePath) throws Exception {
        
		for (@SuppressWarnings("rawtypes")
		Iterator iterator = paramList.iterator(); iterator.hasNext();) {
			String fileName = (String) iterator.next();
			
			// fileName에서 .enc 빼기
	        String fileNameTemp = fileName.replaceFirst("\\.enc$", "");
	        
	        // 전체 출력 파일 경로 생성
	        String fullOutputPath = outputFilePath + File.separator + fileNameTemp;
	        
	        // output 파일 존재 여부 확인
	        File outputFile = new File(fullOutputPath);
	        
	        // 파일이 이미 존재하면 복호화 안함
	        String fullEncryptedPath = "";
	        if (outputFile.exists()) {
	            logger.info("복호화된 파일이 이미 존재합니다. 기존 파일: {}", fullOutputPath);
	            continue;
	        }else {
	        	// 파일이 없으면 복호화 수행
	            fullEncryptedPath = encryptedFilePath + File.separator + fileName;
	            logger.info("파일 복호화 시작: {} -> {}", fullEncryptedPath, fullOutputPath);
	        }
	        
	        boolean isDecrypt = decryptAndSaveFile(fullEncryptedPath, fullOutputPath);
	        if(!isDecrypt) {
	        	return fullEncryptedPath;
	        }
	        
		}
        
		return "ok";
		
	}


}
