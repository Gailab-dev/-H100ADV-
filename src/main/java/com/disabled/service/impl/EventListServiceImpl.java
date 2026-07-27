package com.disabled.service.impl;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.transaction.Transactional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.disabled.mapper.EventListMapper;
import com.disabled.service.ApiService;
import com.disabled.service.EventListService;
import com.disabled.service.FileService;
import com.disabled.service.VideoDecryptionService;


@Service
@Transactional
public class EventListServiceImpl implements EventListService{
	
	@Autowired
	EventListMapper eventListMapper;
	
	@Autowired
	FileService fileService;
	
	@Autowired
	ApiService apiService;
	
	@Autowired
	VideoDecryptionService decryptionService;
	
	// 암호화 된 이미지 경로
	@Value("${image.enc.path}")
	private String imgEncPath;
	  
	// 암호화 된 영상 경로
	@Value("${video.enc.path}")
	private String videoEncPath;
	  
	// 복호화 할 이미지 경로
	@Value("${image.dec.path}")
	private String imgDecPath;
	  
	// 복호화 할 영상 경로
	@Value("${video.dec.path}")
	private String videoDecPath;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(EventListServiceImpl.class);

	/**
	 * 불법 주차 리스트에서 이벤트 상세 내역을 DB에서 가져옴
	 * @Param
	 * - evId : 이벤트 ID
	 * @return
	 * - 이벤트 상새 내력(MAP)
	 */
	@Override
	public Map<String, Object> getEventListDetail(Integer evId) {
		
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			// 이벤트 ID를 검색조건으로 하여 리스트 상세 내역을 select
			resultMap = eventListMapper.getEventListDetail(evId);
			
			if(resultMap == null) {
				logger.error("SQL문 수행 도중 오류 발생, eventListMapper.getEventListDetail(evId)");
				throw new IllegalStateException("SQL문 수행 도중 오류 발생, eventListMapper.getEventListDetail(evId)");
			}
			return resultMap;
			
		} catch (IllegalStateException e) {
			logger.error("getEventListDetail 함수 수행 도중 오류 발생",e);
			throw e;
		}
	}
	
	/**
	 * 불법 주차 리스트에서 이벤트 상세 내역을 DB에서 가져옴
	 * @Param
	 * - evId : 이벤트 ID
	 * @return
	 * - 이벤트 상새 내력(MAP)
	 */
	@Override
	public Map<String, Object> getEventListDetail(Integer evId, Integer evId2) {
		
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			// 이벤트 ID를 검색조건으로 하여 리스트 상세 내역을 select
			resultMap = eventListMapper.getEventListDetail(evId2);
			
			if(resultMap == null) {
				logger.error("SQL문 수행 도중 오류 발생, eventListMapper.getEventListDetail(evId)");
				throw new IllegalStateException("SQL문 수행 도중 오류 발생, eventListMapper.getEventListDetail(evId)");
			}
			return resultMap;
			
		} catch (IllegalStateException e) {
			logger.error("getEventListDetail 함수 수행 도중 오류 발생",e);
			throw e;
		}
	}

	/**
	 * 불법 주차 리스트를 가져옴
	 * @param
	 * - paramMap: 불법 주차 리스트를 가져오기 위한 DB 검색 조건
	 *   > searchKeyword: 검색어
	 *   > startDate: 검색 시작 날짜
	 *   > endDate: 검색 마지막 날짜
	 * @return
	 * - 검색 조건에 부합하는 불법 주차 리스트(List)  
	 */
	@Override
	public List<Map<String, Object>> getEventList(Map<String, Object> paramMap) {
		
		List<Map<String, Object>> resultList = new ArrayList<Map<String,Object>>();
		
		try {
			// 검색 조건에 부합하는 불법 주차 리스트 select
			resultList = eventListMapper.getEventList(paramMap);
			
//			resultList = eventListMapper.getEventListJoinSerial(paramMap);
			
			return resultList;
			
		} catch (IllegalStateException e) {
			logger.error("이벤트 리스트 서비스 오류 발생: {}"+e);
			throw e;
		}
	}
	
	/**
	 * 외부 저장소에 저장된 image 파일의 외부 경로로 웹 화면에 이미지 송출
	 * @param file: file 타입 객체, res: HttpServletResponse 타입 객체 
	 */
	@Override
	public void viewImageOfFilePath(File file, HttpServletResponse res) {
		
		OutputStream os = null;
		FileInputStream fs = null;
		
		
		try {
			fs = new FileInputStream(file);
			os = res.getOutputStream();
			
	        // 이미지 파일 스트리밍
	        byte[] buffer = new byte[4096];
	        int bytesRead;
	        while ((bytesRead = fs.read(buffer)) != -1) {
	            os.write(buffer, 0, bytesRead);
	        }
	        os.flush();
	        
		} catch (FileNotFoundException e) {
			logger.error("FileInputStream 객체 생성 중 오류 발생 : ",e);
		} catch (IOException e2) {
			logger.error("OutputStream 객체 생성 중 오류 발생 : ", e2);
		} finally {
			try {
				if(os != null) os.close();
				if(fs != null) fs.close();
			} catch (IOException e3) {
				logger.error("객체 메모리 반환 중 오류 발생 : ",e3);
			}	
		}
		
	}
	
	/**
	 * 외부 저장소에 저장된 video 파일의 외부 경로로 웹 화면에 비디오 파일 스트리밍
	 */
	@Override
	public void viewVideoOfFilePath(File file, HttpServletRequest req, HttpServletResponse res) throws IndexOutOfBoundsException{
		
		OutputStream os = null;
		RandomAccessFile raf = null;
		
		try {
			// 브라우저 Range 요청 처리 
	        raf = new RandomAccessFile(file, "r");
	        long length = raf.length();
	        long start = 0;
	        long end = length - 1;
	        if(end <= 0) {
	        	throw new IndexOutOfBoundsException("파일 길이는 0 이하가 될 수 없습니다.");
	        }

	        String range = req.getHeader("Range");
	        if (range != null && range.startsWith("bytes=")) {
	            String[] parts = range.substring(6).split("-");
	            start = Long.parseLong(parts[0]);
	            if (parts.length > 1) {
	                end = Long.parseLong(parts[1]);
	            }
	            res.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
	        }

	        long contentLength = end - start + 1;
	        if(contentLength <= 0) {
	        	throw new IndexOutOfBoundsException("파일 길이는 0 이하가 될 수 없습니다.");
	        }
	        res.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + length);
	        res.setHeader("Accept-Ranges", "bytes");
	        res.setHeader("Content-Length", String.valueOf(contentLength));

	        // 실제 영상 전송
	        os = res.getOutputStream();
	        raf.seek(start);

	        byte[] buffer = new byte[4096];
	        long remaining = contentLength;
	        int len;
	        while ((len = raf.read(buffer)) != -1 && remaining > 0) {
	            os.write(buffer, 0, (int)Math.min(len, remaining));
	            remaining -= len;
	        }
	        
	        os.flush();
	        
		} catch (IOException e) {
			logger.error("영상 스트리밍 도중 오류 발생: {}"+e);
			
		} finally {
			try {
				if (os != null) {
					os.close();
				}
				if(raf != null) {
					raf.close();
				}
			} catch (IOException e2) {
				logger.error("Outputstream 객체 또는RandomAccessFile 객체 종료 중 오류 발생 : ",e2);
			}
		
		}
	}
	
	/**
	 * 외부 디렉토리에서 이미지 파일을 가져오기 위한 
	 */
	public void mkdirForStream(String filePath) {
		
		// OS별 경로 정리
		String filePathByOS = fileService.convertPathByOS(filePath);
		
		// 디렉토리 경로만 추출
		String dirPath = fileService.extractDirectoryPath(filePathByOS);
		
		// 디렉토리 생성
		try {
			fileService.ensureDirectory(dirPath);
		} catch (IOException e) {
			logger.error("디렉토리 생성시 오류 발생 : ",e);
		}
		
	}
	
	/**
	 * OS별 full file Path 경로를 가져옴
	 * @param filePath: 파일 경로(String)
	 * @return fullFilePath: OS별 baseDir까지 포함한 파일 경로(String)
	 */
	@Override
	public String mkFullFilePath(String filePath) {
		
		String fullFilePath = null;
		
		try {
			fullFilePath = fileService.makePullPath(filePath);
		} catch (RuntimeException e) {
			logger.error("fullFilePath 생성 중 오류 : ",e);
		}
		
		return fullFilePath;
	}
	
	/**
	 * 외부 저장소에서 file을 불러오기 전 file 객체의 오류 체크
	 * @param file: 파일 객체
	 */
	@Override
	public void fileCheck(File file) {
		
		try {
			// 디렉토리가 실제 존재하는지 확인하여 없으면 에러 있으면 아무일도 일어나지 않음
			fileService.isExistFilePath(file);
			
			// 디렉토리가 BASE_DIR 외에 다른 dir에서 파일을 생성하려고 한다면 에러 발생
			fileService.isCanonicalPath(file);
			
			// 추후 다른 오류 검증 필요시 고도화 할 것
		} catch (RuntimeException e) {
			logger.error("파일 객체 오류 체크시 오류 발생 : ",e);
		}

	}
	
	
	@Override
	/**
	 * 디바이스 리스트에서 상세보기 버튼 클릭시, 웹에 아직 이미지와 영상이 없다면 디바이스에 이미지, 영상파일 요청
	 * @param res
	 * @param dvId				디바이스 ID(Integer)
	 * @param evId				이벤트 ID(Integer)
	 * @param eventListDetail	이벤트 정보(map)
	 * @return true: 디바이스로부터 이미지, 영상 수신 성공, false: 디바이스로부터 이미지 영상 수신 실패
	 */
	public boolean requestFileFromModule(HttpServletResponse res, Integer dvId, Integer evId, Map<String, Object> eventListDetail) {
		
		// 디바이스 IP
		String dvIp = "";
		
		// 요청 json
		HashMap<String, Object> json = new HashMap<String, Object>();
		
		try {
			
			// 이미지 파일이 없다면
			if("0".equals(eventListDetail.get("ev_has_img").toString())) {
				
				
				// 이벤트 ID에 해당하는 deviceIp 가져오기
				dvIp = getDvIpByEvId(dvId, evId);
				
				
				json.put("type", "image");
				
				System.out.println("======json : " + json);
				
				// 첫번째 이미지 파일 가져오기
				String streamCheck = "";
				json.put("fileName", eventListDetail.get("ev_img_path").toString());
				streamCheck = apiService.forwardStreamToJSON(res, json, dvIp, "/fileSend" );
				if("error".equals(streamCheck)) {
					
					// 실패 처리
					logger.error("디바이스에서 이미지 가져오기 실패 / dvIp : "+ dvIp + "json : " + json);
					return false; 
				}
				
				// 두번째 이미지 파일 가져오기
				json.put("fileName", eventListDetail.get("ev_img_path2").toString());
				streamCheck = apiService.forwardStreamToJSON(res, json, dvIp, "/fileSend" );
				if("error".equals(streamCheck)) {
					// 실패 처리
					logger.error("디바이스에서 이미지 가져오기 실패 / dvIp : "+ dvIp + "json : " + json);
					return false; 
				}else{
					
					// 이미지 파일 전송 성공시 ev_has_Img update
					eventListMapper.updateEvHasImgOne(evId);
				}
				
			}
			
			// 영상 파일이 없다면
			if("0".equals(eventListDetail.get("ev_has_mov").toString())) {
				
				// 이벤트 ID에 해당하는 deviceIp 가져오기
				dvIp = getDvIpByEvId(dvId, evId);
				json.put("type", "video");
				json.put("fileName", eventListDetail.get("ev_mov_path").toString());
				
				// 영상 파일 가져오기
				String streamCheck = "";
				streamCheck = apiService.forwardStreamToJSON(res, json, dvIp, "/fileSend");
				if("error".equals(streamCheck)) {
					
					// 실패 처리
					logger.error("디바이스에서 영상 가져오기 실패 / dvIp : "+ dvIp + "json : " + json);
					return false;
				}else {
					// 영상파일 전송 성공시 ev_has_mov update
					eventListMapper.updateEvHasMovOne(evId);
				}
			}
			
			File encryptedFile = new File("/home/dsic/Desktop/H100_system/output_images_enc/20260202175054_1_Cam1_1.png.enc");
    		long fileSize = encryptedFile.length();
            System.out.println("======666666암호화된 파일 크기: " + fileSize + " bytes");
			
		} catch (IllegalStateException e2) {
			logger.error("requestFileFromModule에서 evHasMovChange 또는 evHasImgChange 오류 발생 : ",e2);
			throw e2;
		} catch (RuntimeException e) {
			logger.error("requestFileFromModule에서 오류 발생 : ",e);
			throw e;
		}
		
		return true;
	}
	
	/**
	 * 디바이스로부터 받은 영상, 이미지 파일 복호화
	 * @param res				ㅇ
	 * @param evId				이벤트 ID(Integer)
	 * @param eventListDetail	이벤트 상세 정보(map)
	 * @return
	 */
	@Override
	public boolean requestFileDec(HttpServletResponse res, Integer evId, Map<String, Object> eventListDetail) {
		// patches 2026-07-09(8): 과태료 사전통지서 엑셀 손상 원인 수정.
		//  - 기존: 2번째 이미지 결과만 검사(첫 결과 덮어씀) + 영상이 없으면 decVideoCheck=false 로 남아 return false →
		//          컨트롤러가 엑셀을 생성하지 않고 early return → 빈 200 응답 → 다운로드된 xlsx 손상("파일 형식이 잘못됨").
		//  - 통지서 엑셀은 영상을 사용하지 않으며(사진 2장·도장·수납인만 임베드), 일부 파일 부재는 정상 케이스다.
		//  - 수정: 존재하는 파일만 개별 복호화하고 부재/개별 실패는 warn 로그만 남긴 뒤 진행(엑셀은 있는 이미지로 생성).
		//          실제 예외(복호화 로직 오류)일 때만 false 반환.
		try {
			// 이미지 1 복호화 (있을 때만)
			Object img1 = eventListDetail.get("ev_img_path");
			if (img1 != null && !img1.toString().isBlank()) {
				boolean ok = decryptionService.decryptAndSaveFileAutoName1(img1.toString(), imgEncPath, imgDecPath);
				if (!ok) logger.warn("[이미지1 복호화 실패-계속진행] 파일명: {}, encPath: {}, decPath: {}", img1, imgEncPath, imgDecPath);
			}

			// 이미지 2 복호화 (있을 때만)
			Object img2 = eventListDetail.get("ev_img_path2");
			if (img2 != null && !img2.toString().isBlank()) {
				boolean ok = decryptionService.decryptAndSaveFileAutoName1(img2.toString(), imgEncPath, imgDecPath);
				if (!ok) logger.warn("[이미지2 복호화 실패-계속진행] 파일명: {}, encPath: {}, decPath: {}", img2, imgEncPath, imgDecPath);
			}

			// 영상 복호화 (있을 때만, 통지서 엑셀엔 미사용 → 실패해도 엑셀 진행)
			Object movObj = eventListDetail.get("ev_mov_path");
			if (movObj != null && !movObj.toString().isBlank()) {
				boolean ok = decryptionService.decryptAndSaveFileAutoName1(movObj.toString(), videoEncPath, videoDecPath);
				if (!ok) logger.warn("[영상 복호화 실패-계속진행] 파일명: {}, encPath: {}, decPath: {}", movObj, videoEncPath, videoDecPath);
			}
		} catch (Exception e) {
			logger.error("requestFileDec에서 파일 복호화 오류 발생 : ", e);
			return false;
		}

		return true;
	}
	
	// ====== ADR-008 디바이스 통신 우선순위 변경 (2026-06-17) ======
	// 서버 파일 우선, 없을 때만 디바이스 통신. AJAX 단계별 호출용 메서드.
	// 사유: 디바이스 라이프사이클 비의존(교체/사업종료 후에도 서버 파일로 조회 가능)

	/**
	 * (ADR-008) 서버(enc 디렉토리)에 이 이벤트의 이미지 파일이 존재하는지 빠르게 확인.
	 * "파일 존재"의 정의 = File.exists() 만 확인 (손상·권한·내용 검증은 별도 X — 단순·빠른 체크).
	 *
	 * @param eventListDetail 이벤트 상세(파일명 포함)
	 * @return 필요한 이미지 enc 파일이 모두 서버에 있으면 true
	 */
	@Override
	public boolean encImagesExistOnServer(Map<String, Object> eventListDetail) {
		if (eventListDetail == null) {
			logger.info("[DIAG] [phase=encImagesExistOnServer-null-input]"); // TEMP 진단 — 시연 후 제거
			return false;
		}
		logger.info("[DIAG] [phase=encImagesExistOnServer-entry] imgEncPath={} ev_img_path={} ev_img_path2={}",
				imgEncPath, eventListDetail.get("ev_img_path"), eventListDetail.get("ev_img_path2")); // TEMP 진단
		boolean img1 = encFileExists(imgEncPath, eventListDetail.get("ev_img_path"));
		Object p2 = eventListDetail.get("ev_img_path2");
		// 두번째 이미지 경로가 없는 이벤트는 img2 조건을 통과로 간주
		boolean img2 = isBlankName(p2) ? true : encFileExists(imgEncPath, p2);
		boolean result = img1 && img2;
		logger.info("[DIAG] [phase=encImagesExistOnServer-return] img1={} img2={} result={}", img1, img2, result); // TEMP 진단
		return result;
	}

	/** enc 디렉토리에 해당 파일명이 실제로 존재하는지(File.exists) */
	private boolean encFileExists(String dir, Object fileName) {
		if (isBlankName(fileName)) {
			return false;
		}
		File f = new File(dir + File.separator + fileName.toString());
		boolean exists = f.exists();
		logger.info("[DIAG] [phase=encFileExists-check] fullPath={} exists={}", f.getAbsolutePath(), exists); // TEMP 진단
		return exists;
	}

	/** 파일명이 null/공백/"null" 문자열인지 */
	private boolean isBlankName(Object fileName) {
		return fileName == null || fileName.toString().isBlank() || "null".equals(fileName.toString());
	}

	/**
	 * (ADR-008 / 2026-06-25) 복호화 디렉토리(dec)에 평문 원본 이미지가 존재하는지 확인.
	 *
	 * .enc 파일은 없지만 평문 원본(.png 등)만 남은 이벤트를, 디바이스 통신 없이 그대로 표시하기 위한 fallback.
	 * 판단 정책은 {@link #encImagesExistOnServer}와 동일(img1 필수, img2 있을 때만).
	 * 매칭 키는 dec 파일 명명 규칙(.enc 제거)에 맞춤 — DB값이 평문(.png)이면 무변환(동일).
	 *
	 * @return 평문 원본 이미지가 dec 디렉토리에 모두 있으면 true
	 */
	@Override
	public boolean plainImagesExistOnServer(Map<String, Object> eventListDetail) {
		if (eventListDetail == null) {
			logger.info("[DIAG] [phase=plainImagesExistOnServer-null-input]"); // TEMP 진단
			return false;
		}
		logger.info("[DIAG] [phase=plainImagesExistOnServer-entry] imgDecPath={} ev_img_path={} ev_img_path2={} ev_mov_path={}",
				imgDecPath, eventListDetail.get("ev_img_path"), eventListDetail.get("ev_img_path2"),
				eventListDetail.get("ev_mov_path")); // TEMP 진단
		boolean img1 = plainFileExists(imgDecPath, eventListDetail.get("ev_img_path"));
		logger.info("[DIAG] [phase=plainFileExists-img1] name={} result={}", eventListDetail.get("ev_img_path"), img1); // TEMP 진단
		Object p2 = eventListDetail.get("ev_img_path2");
		boolean img2;
		if (isBlankName(p2)) {
			img2 = true;
			logger.info("[DIAG] [phase=plainFileExists-img2] name={} skipped=true result=true", p2); // TEMP 진단
		} else {
			img2 = plainFileExists(imgDecPath, p2);
			logger.info("[DIAG] [phase=plainFileExists-img2] name={} result={}", p2, img2); // TEMP 진단
		}
		boolean result = img1 && img2;
		logger.info("[DIAG] [phase=plainImagesExistOnServer-return] result={}", result); // TEMP 진단
		return result;
	}

	/** dec 디렉토리에 평문 원본이 존재하는지(File.exists). 이름에 .enc가 있으면 제거 후 검사(dec 명명 규칙과 일치). */
	private boolean plainFileExists(String dir, Object fileName) {
		if (isBlankName(fileName)) {
			logger.info("[DIAG] [phase=plainFileExists-blank-name] dir={}", dir); // TEMP 진단
			return false;
		}
		String name = fileName.toString().replaceFirst("\\.enc$", "");
		File f = new File(dir + File.separator + name);
		boolean exists = f.exists();
		logger.info("[DIAG] [phase=plainFileExists-check] fullPath={} exists={}", f.getAbsolutePath(), exists); // TEMP 진단
		return exists;
	}

	/**
	 * (ADR-008) 서버에 없는 파일만 디바이스에서 가져온다. (timeout: ApiServiceImpl 연결5초/응답10초)
	 *
	 * @return "OK"(수신 완료/필요없음) | "NO_FILE"(디바이스에도 없음) | "FAIL"(통신 실패·timeout)
	 */
	@Override
	public String fetchFromDevice(HttpServletResponse res, Integer dvId, Integer evId, Map<String, Object> eventListDetail) {
		try {
			logger.info("[DIAG] [evId={}] [phase=fetchFromDevice-entry] msg=디바이스 통신 시도", evId); // TEMP 진단
			String dvIp = getDvIpByEvId(dvId, evId);
			if (dvIp == null || dvIp.isBlank()) {
				logger.warn("[ADR-008] 디바이스 IP 없음 evId={}", evId);
				return "FAIL";
			}

			// 이미지: 서버에 없을 때만 요청
			if (!encFileExists(imgEncPath, eventListDetail.get("ev_img_path"))) {
				HashMap<String, Object> json = new HashMap<String, Object>();
				json.put("type", "image");
				json.put("fileName", String.valueOf(eventListDetail.get("ev_img_path")));
				if (!isBlankName(eventListDetail.get("ev_img_path2"))) {
					json.put("fileName2", String.valueOf(eventListDetail.get("ev_img_path2")));
				}
				String r = apiService.forwardStreamToJSON(res, json, dvIp, "/fileSend");
				if ("error".equals(r)) {
					logger.error("[ADR-008] 디바이스 이미지 수신 실패 evId={}", evId);
					return "FAIL";
				}
			}

			// 영상: 존재하는 이벤트이고 서버에 없을 때만 요청
			Object mov = eventListDetail.get("ev_mov_path");
			if (!isBlankName(mov) && !encFileExists(videoEncPath, mov)) {
				HashMap<String, Object> vjson = new HashMap<String, Object>();
				vjson.put("type", "video");
				vjson.put("fileName", mov.toString());
				String r = apiService.forwardStreamToJSON(res, vjson, dvIp, "/fileSend");
				if ("error".equals(r)) {
					logger.error("[ADR-008] 디바이스 영상 수신 실패 evId={}", evId);
					return "FAIL";
				}
			}

			// 수신 후에도 서버에 이미지가 없으면 디바이스에도 없는 것(시나리오 다)
			if (!encImagesExistOnServer(eventListDetail)) {
				return "NO_FILE";
			}
			return "OK";

		} catch (Exception e) {
			logger.error("[ADR-008] fetchFromDevice 오류 evId=" + evId, e);
			return "FAIL";
		}
	}

	/**
	 * (ADR-008) 뷰 표시용 복호화. 이미지 복호화 성공 여부를 반환한다.
	 * 영상은 선택 항목이라 실패하더라도 이미지 표시는 진행한다(영상은 재생 시점에 별도 처리).
	 *
	 * @return 이미지 복호화 성공 시 true
	 */
	@Override
	public boolean decryptForView(Map<String, Object> eventListDetail) {
		try {
			boolean ok = true;
			Object p1 = eventListDetail.get("ev_img_path");
			Object p2 = eventListDetail.get("ev_img_path2");

			if (!isBlankName(p1)) {
				ok = decryptionService.decryptAndSaveFileAutoName1(p1.toString(), imgEncPath, imgDecPath);
			}
			if (ok && !isBlankName(p2)) {
				ok = decryptionService.decryptAndSaveFileAutoName1(p2.toString(), imgEncPath, imgDecPath);
			}

			// 영상은 있을 때만, 실패해도 이미지 기준으로 성공 처리
			Object mov = eventListDetail.get("ev_mov_path");
			if (!isBlankName(mov)) {
				try {
					decryptionService.decryptAndSaveFileAutoName1(mov.toString(), videoEncPath, videoDecPath);
				} catch (Exception ve) {
					logger.warn("[ADR-008] 영상 복호화 실패(이미지는 계속 진행) 영상={}", mov, ve);
				}
			}
			return ok;

		} catch (Exception e) {
			// 파일 손상 등 → false 반환(컨트롤러/프론트에서 재 connection 1회 시도: 시나리오 마)
			logger.error("[ADR-008] decryptForView 복호화 실패", e);
			return false;
		}
	}

	/**
	 * 이벤트를 보낸 디바이스의 IP를 조회
	 * @param dvId : 디바이스 ID
	 * @param evId : 이벤트 ID
	 * @return dvIp : 디바이스 IP
	 */
	@Override
	public String getDvIpByEvId(Integer dvId, Integer evId) {
		
		//dvIp
		String dvIp = "";
		
		try {
			
			dvIp = eventListMapper.getDvIpByEvId(evId);
			if(dvIp == null || dvIp.isEmpty()) {
				logger.error("eventListMapper.getDvIpByEvId(evId)에서 SQL문 오류");
				throw new IllegalStateException("eventListMapper.getDvIpByEvId(evId)에서 SQL문 오류");
			}
			return dvIp;
			
		} catch (IllegalStateException e) {
			logger.error("getDvIpByEvId에서 오류 발생 : ",e);
			throw e;
		}
		
	}
	
	/**
	 * 페이징 기능을 위한 검색 조건에 따른 총 레코드 갯수
	 * @param startDate : 검색 조건 중 시작일
	 * @param endDate : 검색 조건 중 마지막일
	 * @param searchKeyword : 검색 조건 중 검색어
	 * @return 검색 조건에 따른 총 레코드 갯수
	 */
	@Override
	public int getTotalRecordCount(Map<String,Object> paramMap) {
		
		try {
			// 검색 조건에 따른 천제 페이지 개수 출력
			return eventListMapper.getTotalRecordCount(paramMap);
		} catch (IllegalStateException e) {
			logger.error("getTotalRecordCount에서 오류 발생 : ",e);
			throw e;
		}
	}

	/**
	 * ev_cd별 이벤트 건수 조회
	 * @param paramMap 검색 조건
	 * @return ev_cd별 이벤트 건수
	 */
	@Override
	public List<Map<String, Object>> getEventCountByEvCd(Map<String, Object> paramMap) {

		try {
			return eventListMapper.getEventCountByEvCd(paramMap);
		} catch (RuntimeException e) {
			logger.error("getEventCountByEvCd에서 오류 발생 : ", e);
			throw e;
		}
	}
	
}
