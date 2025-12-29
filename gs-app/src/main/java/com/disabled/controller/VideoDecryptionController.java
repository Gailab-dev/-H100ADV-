package com.disabled.controller;

import com.disabled.service.VideoDecryptionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

@Controller
@RequestMapping("/video")
public class VideoDecryptionController {

//    private static final Logger logger = LoggerFactory.getLogger(VideoDecryptionController.class);
//
//    @Autowired
//    private VideoDecryptionService videoDecryptionService;
//
//    // 암호화된 비디오 파일이 저장된 경로
//    @Value("${video.storage.path:C:/encrypted_videos}")
//    private String videoStoragePath;
//
//    // 복호화된 비디오 파일을 저장할 경로
//    @Value("${video.output.path:C:/decrypted_videos}")
//    private String videoOutputPath;
//
//    /**
//     * 암호화된 비디오를 복호화하여 파일로 저장
//     *
//     * @param fileName 파일명 (예: video.mp4.enc)
//     * @return 저장 결과 (성공/실패 메시지, 저장된 파일 경로)
//     */
//    @PostMapping("/decrypt/{fileName:.+}")
//    @ResponseBody
//    public ResponseEntity<Map<String, Object>> decryptVideo(@PathVariable String fileName) {
//        Map<String, Object> response = new HashMap<>();
//
//        try {
//            // 보안: 경로 탐색 공격 방지
//            if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
//                logger.warn("잘못된 파일명 요청: {}", fileName);
//                response.put("success", false);
//                response.put("message", "잘못된 파일명입니다.");
//                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
//            }
//
//            // .enc 파일 경로
//            String encryptedFilePath = videoStoragePath + File.separator + fileName;
//
//            // 복호화된 파일 저장 경로
//            String decryptedFileName = fileName.replace(".enc", "");
//            String outputFilePath = videoOutputPath + File.separator + decryptedFileName;
//
//            logger.info("비디오 복호화 요청: {} -> {}", encryptedFilePath, outputFilePath);
//
//            // 파일 존재 확인
//            File encFile = new File(encryptedFilePath);
//            if (!encFile.exists()) {
//                logger.error("파일을 찾을 수 없습니다: {}", encryptedFilePath);
//                response.put("success", false);
//                response.put("message", "파일을 찾을 수 없습니다: " + fileName);
//                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
//            }
//
//            // 복호화 및 파일 저장
//            File savedFile = videoDecryptionService.decryptAndSaveFile(encryptedFilePath, outputFilePath);
//
//            logger.info("비디오 복호화 및 저장 성공: {}", savedFile.getAbsolutePath());
//
//            response.put("success", true);
//            response.put("message", "파일 복호화 및 저장 성공");
//            response.put("savedFilePath", savedFile.getAbsolutePath());
//            response.put("fileName", savedFile.getName());
//            response.put("fileSize", savedFile.length());
//
//            return ResponseEntity.ok(response);
//
//        } catch (Exception e) {
//            logger.error("비디오 복호화 중 오류 발생: {}", fileName, e);
//            response.put("success", false);
//            response.put("message", "복호화 중 오류 발생: " + e.getMessage());
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
//        }
//    }
//
//    /**
//     * 특정 경로의 암호화된 비디오를 복호화하여 파일로 저장
//     *
//     * @param encryptedPath 암호화된 파일의 전체 경로
//     * @param outputPath 복호화된 파일을 저장할 경로 (선택사항, 없으면 .enc만 제거)
//     * @return 저장 결과
//     */
//    @PostMapping("/decrypt-by-path")
//    @ResponseBody
//    public ResponseEntity<Map<String, Object>> decryptVideoByPath(
//            @RequestParam String encryptedPath,
//            @RequestParam(required = false) String outputPath) {
//
//        Map<String, Object> response = new HashMap<>();
//
//        try {
//            logger.info("비디오 복호화 요청 (경로): {} -> {}", encryptedPath, outputPath);
//
//            // 파일 존재 확인
//            File encFile = new File(encryptedPath);
//            if (!encFile.exists()) {
//                logger.error("파일을 찾을 수 없습니다: {}", encryptedPath);
//                response.put("success", false);
//                response.put("message", "파일을 찾을 수 없습니다: " + encryptedPath);
//                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
//            }
//
//            File savedFile;
//
//            if (outputPath == null || outputPath.isEmpty()) {
//                // 출력 경로가 없으면 .enc만 제거
//                savedFile = videoDecryptionService.decryptAndSaveFileAutoName(encryptedPath);
//            } else {
//                // 지정된 경로에 저장
//                savedFile = videoDecryptionService.decryptAndSaveFile(encryptedPath, outputPath);
//            }
//
//            logger.info("비디오 복호화 및 저장 성공: {}", savedFile.getAbsolutePath());
//
//            response.put("success", true);
//            response.put("message", "파일 복호화 및 저장 성공");
//            response.put("savedFilePath", savedFile.getAbsolutePath());
//            response.put("fileName", savedFile.getName());
//            response.put("fileSize", savedFile.length());
//
//            return ResponseEntity.ok(response);
//
//        } catch (Exception e) {
//            logger.error("비디오 복호화 중 오류 발생: {}", encryptedPath, e);
//            response.put("success", false);
//            response.put("message", "복호화 중 오류 발생: " + e.getMessage());
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
//        }
//    }
//
//    /**
//     * 디렉토리 내 모든 .enc 파일을 일괄 복호화
//     *
//     * @return 일괄 복호화 결과
//     */
//    @PostMapping("/decrypt-all")
//    @ResponseBody
//    public ResponseEntity<Map<String, Object>> decryptAllVideos() {
//        Map<String, Object> response = new HashMap<>();
//
//        try {
//            File storageDir = new File(videoStoragePath);
//
//            if (!storageDir.exists() || !storageDir.isDirectory()) {
//                response.put("success", false);
//                response.put("message", "저장 경로를 찾을 수 없습니다: " + videoStoragePath);
//                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
//            }
//
//            File[] encFiles = storageDir.listFiles((dir, name) -> name.endsWith(".enc"));
//
//            if (encFiles == null || encFiles.length == 0) {
//                response.put("success", true);
//                response.put("message", "복호화할 파일이 없습니다.");
//                response.put("totalFiles", 0);
//                response.put("successCount", 0);
//                response.put("failCount", 0);
//                return ResponseEntity.ok(response);
//            }
//
//            int successCount = 0;
//            int failCount = 0;
//            Map<String, String> results = new HashMap<>();
//
//            for (File encFile : encFiles) {
//                try {
//                    String outputFilePath = videoOutputPath + File.separator +
//                                          encFile.getName().replace(".enc", "");
//
//                    videoDecryptionService.decryptAndSaveFile(
//                        encFile.getAbsolutePath(),
//                        outputFilePath
//                    );
//
//                    results.put(encFile.getName(), "성공");
//                    successCount++;
//
//                } catch (Exception e) {
//                    logger.error("파일 복호화 실패: {}", encFile.getName(), e);
//                    results.put(encFile.getName(), "실패: " + e.getMessage());
//                    failCount++;
//                }
//            }
//
//            response.put("success", true);
//            response.put("message", "일괄 복호화 완료");
//            response.put("totalFiles", encFiles.length);
//            response.put("successCount", successCount);
//            response.put("failCount", failCount);
//            response.put("results", results);
//
//            return ResponseEntity.ok(response);
//
//        } catch (Exception e) {
//            logger.error("일괄 복호화 중 오류 발생", e);
//            response.put("success", false);
//            response.put("message", "일괄 복호화 중 오류 발생: " + e.getMessage());
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
//        }
//    }
}
