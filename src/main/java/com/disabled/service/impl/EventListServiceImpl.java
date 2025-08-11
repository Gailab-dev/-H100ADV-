package com.disabled.service.impl;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.controller.DeviceListController;
import com.disabled.mapper.EventListMapper;
import com.disabled.service.EventListService;
import com.disabled.service.FileService;

@Service
public class EventListServiceImpl implements EventListService{
	
	@Autowired
	EventListMapper eventListMapper;
	
	@Autowired
	FileService fileService;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	
	@Override
	public List<Map<String, Object>> getEventList() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Integer getEventListCount() {
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
	public Map<String, Object> getEventListDetail(Integer evId) {
		
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			// 이벤트 ID를 검색조건으로 하여 리스트 상세 내역을 select
			resultMap = eventListMapper.getEventListDetail(evId);
		} catch (Exception e) {
			//GS인증시 삭제
			System.out.println("이벤트 리스트 디테일 서비스 오류");
			//GS인증시 삭제
			
			logger.error("이벤트 리스트 디테일 서비스 오류: {}"+e);
		}
		
		return resultMap;
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
			
			//GS인증시 삭제
			System.out.println(resultList);
			//GS인증시 삭제
			
		} catch (Exception e) {
			
			// GS 인증시 삭제
			System.out.println("이벤트 리스트 서비스 오류");
			System.out.println(e + "");
			// GS 인증시 삭제
			
			logger.error("이벤트 리스트 서비스 오류 발생: {}"+e);
			
		}
		
		return resultList;
		
	}
	
	/**
	 * 외부 저장소에 저장된 image 파일의 외부 경로로 웹 화면에 이미지 송출 
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
	        
		} catch (Exception e) {
			
			logger.error("이미지 스트리밍 도중 오류 발생: {}"+e);
			
		} finally {
			try {
				if(os != null) {
					os.close();
				}
				if(fs != null) {
					fs.close();
				}
			} catch (Exception e2) {
				logger.error("output straeam, file Stream 객체 종료 중 오류 발생: {}"+e2);
			}
		}
		
	}
	
	/**
	 * 외부 저장소에 저장된 video 파일의 외부 경로로 웹 화면에 비디오 파일 스트리밍
	 */
	@Override
	public void viewVideoOfFilePath(File file, HttpServletRequest req, HttpServletResponse res) {
		
		OutputStream os = null;
		
		try {
			// 브라우저 Range 요청 처리 
	        RandomAccessFile raf = new RandomAccessFile(file, "r");
	        long length = raf.length();
	        long start = 0;
	        long end = length - 1;

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

	        raf.close();
	        os.flush();
	        
		} catch (Exception e) {
			logger.error("영상 스트리밍 도중 오류 발생: {}"+e);
			
		} finally {
			try {
				if (os != null) {
					os.close();
				}
			} catch (Exception e2) {
				logger.error("output straeam 객체 종료 중 오류 발생: {}"+e2);
				
			}
		}
	}
	
	/**
	 * 외부 디렉토리에서 이미지 파일을 가져오기 위한 
	 */
	public void mkdirForStream(String filePath) {
		
		System.out.println("mkdirFroStream in : " + filePath);
		
		// OS별 경로 정리
		String filePathByOS = fileService.convertPathByOS(filePath);
		
		// 디렉토리 경로만 추출
		String dirPath = fileService.extractDirectoryPath(filePathByOS);
		
		// 디렉토리 생성
		String err = fileService.ensureDirectory(dirPath);
		if(err != null) {
			throw new RuntimeException(err);
		}
		
	}
	
	/**
	 * OS별 full file Path 경로를 가져옴
	 * @param filePath: 파일 경로(String)
	 * @return fullFilePath: OS별 baseDir까지 포함한 파일 경로(String)
	 */
	@Override
	public String mkFullFilePath(String filePath) {
		
		return fileService.makePullPath(filePath);
	}
	
	/**
	 * 외부 저장소에서 file을 불러오기 전 file 객체의 오류 체크
	 * @param file: 파일 객체
	 */
	@Override
	public void fileCheck(File file) {
		
		// 디렉토리가 실제 존재하는지 확인하여 없으면 에러 있으면 아무일도 일어나지 않음
		fileService.isExistFilePath(file);
		
		// 디렉토리가 BASE_DIR 외에 다른 dir에서 파일을 생성하려고 한다면 에러 발생
		fileService.isCanonicalPath(file);
		
		// 추후 다른 오류 검증 필요시 고도화 할 것
	}
}
