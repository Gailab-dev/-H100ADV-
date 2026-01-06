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
import org.springframework.dao.DataAccessException;
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
	
	
	@Override
	public List<Map<String, Object>> getEventList() {
		// TODO Auto-generated method stub
		return null;
	}

	/**
	 * 불법 주차 리스트에서 이벤트 상세 내역을 DB에서 가져옴
	 * @Param
	 * - evId : 이벤트 ID
	 * @return
	 * - 이벤트 상새 내력(MAP)
	 */
	@Override
	public Map<String, Object> getEventListDetail(Integer dvId, Integer evId) {
		
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
				json.put("fileName", eventListDetail.get("ev_img_path").toString());
				
				// 이미지 파일 가져오기
				String streamCheck = "";
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
		try {
			boolean decImgCheck = false;
			boolean decVideoCheck = false;
        
			// 이미지 복호화
			decImgCheck = decryptionService.decryptAndSaveFileAutoName(eventListDetail.get("ev_img_path").toString(), imgEncPath, imgDecPath);
        
			if(!decImgCheck) {
				logger.error("[이미지파일 복호화 실패] 파일명: " + eventListDetail.get("ev_img_path").toString() + ", 암호화 된 이미지 경로: " +  imgEncPath + ", 복호화 된 이미지 경로" + imgDecPath);
				return false;
			}
        
			// 영상 복호화
			decVideoCheck = decryptionService.decryptAndSaveFileAutoName(eventListDetail.get("ev_mov_path").toString(), videoEncPath, videoDecPath);
        
			if(!decVideoCheck) {
				logger.error("[영상파일 복호화 실패] 파일명: " + eventListDetail.get("ev_mov_path").toString() + ", 암호화 된 영상 경로: " +  videoEncPath + ", 복호화 된 영상 경로" + videoDecPath);
				return false;
			}
		} catch (Exception e) {
			logger.error("requestFileDec에서 파일 복호화 오류 발생 : ",e);
			return false;
		}
      
		return true;
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
	public int getTotalRecordCount(String startDate, String endDate, String searchKeyword) {
		
		try {
			// 검색 조건에 따른 천제 페이지 개수 출력
			return eventListMapper.getTotalRecordCount(startDate, endDate, searchKeyword);
		} catch (IllegalStateException e) {
			logger.error("getTotalRecordCount에서 오류 발생 : ",e);
			throw e;
		}
	}
	
}
