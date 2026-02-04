package com.disabled.service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Iterator;
import java.util.List;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class VideoDecryptionService {

    private static final Logger logger = LoggerFactory.getLogger(VideoDecryptionService.class);

    // ✅ 파이썬 decrypt_test.py / parking_system_rtsp.py 의 SECRET_KEY 와 반드시 동일
    private static final String SECRET_KEY = "gailab3883!";

    private static final String TRANSFORMATION = "AES/CBC/PKCS5Padding";
    private static final int IV_SIZE = 16; // AES block size

    // 🔥 더 이상 외부 @Autowired 로 받지 않고, 파이썬과 동일하게 내부에서 생성
    private final SecretKey videoSecretKey;

    public VideoDecryptionService() throws Exception {
        this.videoSecretKey = createVideoSecretKey();
        logger.info("VideoDecryptionService 초기화 - 키 길이: {} bytes, 키 hex: {}",
                videoSecretKey.getEncoded().length,
                bytesToHex(videoSecretKey.getEncoded()));
    }

    /**
     * 파이썬의 get_aes_key 와 동일:
     * key = SHA256(SECRET_KEY UTF-8) → 32 bytes → AES-256 키
     */
    private SecretKey createVideoSecretKey() throws Exception {
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        byte[] keyBytes = sha.digest(SECRET_KEY.getBytes(StandardCharsets.UTF_8)); // 32 bytes
        return new SecretKeySpec(keyBytes, "AES");
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
            cipher.init(Cipher.DECRYPT_MODE, videoSecretKey, ivSpec);

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
            cipher.init(Cipher.DECRYPT_MODE, videoSecretKey, ivSpec);

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

        // .enc 파일이 아니면 복사만 수행
        if (!encryptedFilePath.endsWith(".enc")) {
            logger.info("암호화되지 않은 파일 - 복사만 수행: {}", encryptedFilePath);
            return copyFile(encryptedFilePath, outputFilePath);
        }

        // .enc 파일인 경우 복호화 수행
        try (FileInputStream fis = new FileInputStream(encryptedFile)) {
            // 파일 크기 확인
            long fileSize = encryptedFile.length();
            System.out.println("======암호화된 파일 크기: " + fileSize + " bytes");
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

            // 디버깅: 키 정보 확인
            logger.info("복호화 키 알고리즘: {}, 키 길이: {} bytes, 키 hex: " + bytesToHex(videoSecretKey.getEncoded()),
                    videoSecretKey.getAlgorithm(),
                    videoSecretKey.getEncoded().length
                    );

            // 복호화
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            cipher.init(Cipher.DECRYPT_MODE, videoSecretKey, ivSpec);

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
