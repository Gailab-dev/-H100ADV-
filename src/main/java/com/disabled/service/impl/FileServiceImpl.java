package com.disabled.service.impl;

import java.io.File;
import java.io.IOException;

import org.springframework.stereotype.Service;

import com.disabled.service.FileService;

@Service
public class FileServiceImpl implements FileService{
	
	// 추후 BASE_PATH 변경시 해당 내용 변경
	final String BASE_PATH_WIN = "C:\\gstest";
	final String BASE_PATH_LINUX = "/gstest";
	final static String OS = System.getProperty("os.name").toLowerCase();
	
	/**
	 * OS에 맞는 패스 구분자 변경 함수
	 * @param filePath: 파일 경로(String)
	 * @return convertPath: OS에 맞게 구분자 변경된 파일 경로(String)
	 */
	public String convertPathByOS(String filePath) {
		
		System.out.println("convertPathByOs : " +filePath);
		
		String convertPath = null;
		
		// 윈도우라면 구분자를 / 에서 \로 변경
		if(OS.contains("win")) {
			System.out.println("window os");
			convertPath = filePath.replace("/", "\\");
		}
		if(OS.contains("linux")) {
			System.out.println("linux os");
			convertPath = filePath;
		}
		// 아래에 다른 운영체제별 구분자 변경이 필요하다면 추가로 고도화 진행할 것
		
		System.out.println("convertPath : " + convertPath);
		
		return convertPath;
		
	}
	
	/**
	 * OS에 맞는 디렉토리 추출 함수
	 * @param filePath: 파일 경로(String)
	 * @return directoryPath: OS에 맞게 디렉토리만 구분된 파일 경로(String)
	 */
	public String extractDirectoryPath(String filePath) {
		
		System.out.println("extractDirectoryPath in : "+ filePath);
		
		// return String, OS에 맞게 디렉토리만 구분된 파일 경로
		String directoryPath = null;
		
		//구분자, linux 기준
		String separator = "/";
		
		//Window인 경우 \를 구분자로 하여 디렉토리 path만 구분
		if(OS.contains("win")) {
			
			System.out.println("use window separator");
			separator = "\\";
		}
		// 추후 다른 구분자가 필요한 경우 아래에 고도화할 것
		
		// filePath에서 마지막 구분자를 찾아서 그 위치를 반환
		int lastIndex = filePath.lastIndexOf(separator);
		if(lastIndex == -1) return filePath; // 구분자 없음
		
		// 문자열 처음부터 마지막 구분자 위치까지 문자열을 잘라서 반환(디렉토리 위치까지만 반환)
		directoryPath = filePath.substring(0,lastIndex);
		
		System.out.println("directoryPath : " + directoryPath);
		
		return directoryPath;
	}
	
    /**
     * 디렉토리를 생성하며 오류 발생시 오류 내용을 리턴함.
     * @param directoryPath: 디렉토리 경로
     * @return errMsg: null이면 성공, 실패시 에러 메시지
     */
	 public String ensureDirectory(String directoryPath) {
		
		 System.out.println("ensureDirectory in : " + directoryPath);
		 
		File dir = new File(directoryPath);
		
		//디렉토리가 없는 경우 디렉토리 생성
		if(!dir.exists()) {
			boolean created = dir.mkdirs();
			if(!created) return "디렉토리 생성 실패: " + directoryPath;
		}
		// 디렉토리가 존재하지 않은 경우 에러 발생
		if(!dir.isDirectory()) return "디렉토리 확인 실패: " + directoryPath;
		
		System.out.println("dir.exists(): " + dir.exists());
		System.out.println("dir.isDirectory(): " + dir.isDirectory());
		System.out.println("dir.canWrite(): " + dir.canWrite());
		
		// 성공시 null
		return null;

	}
	
	/**
	 * OS별 pullPath를 만들어 return
	 * @param filePath: 파일 경로(String)
	 * @return pullPath: OS별 basePath와 filePath를 결합하여 return, 오류시 filePath를 그대로 리턴
	 */
	 public String makePullPath(String filePath) {
		 
		 System.out.println("makePullPath in "+ filePath);
		 
		 //windows인 경우
		 if(OS.contains("win")) {
			 
			 System.out.println("make window pullPath : "+ BASE_PATH_WIN + filePath);
			 
			 return BASE_PATH_WIN + filePath;
		 }
		 // 리눅스인 경우
		 else if(OS.contains("linux")) {
			 
			 System.out.println("make linux pullPath : "+ BASE_PATH_LINUX + filePath);
			 
			 return BASE_PATH_LINUX + filePath;
		 }
		 // 그 어느 것도 아닌 경우 오류 리턴
		 else {
			 throw new RuntimeException("fullFilePath를 만들 수 없습니다.");
		 }
		 // 추후 OS 별로 고도화 필요할 시 추가 작성할 것
		 
	 }
	 
	 /**
	  * BASE_DIR를 
	  */
	@Override
	public void isCanonicalPath(File file) {
		
		System.out.println("isCanonicalPath : " + file);
		
		String basePath = null;
		if(OS.contains("win")) basePath = BASE_PATH_WIN;
		if(OS.contains("linux")) basePath = BASE_PATH_LINUX;
		
		System.out.println("basePath : " +basePath);
		
		// 디렉토리 이탈 방지
		try {
			if(!file.getCanonicalPath().startsWith(new File(basePath).getCanonicalPath())) {
				throw new RuntimeException("basePath가 아닙니다."); // 디렉토리 이탈
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
	
	/**
	 * 파일 경로를 검증하여 오류가 있다면 에러 발생
	 * @param file: file 객체
	 */
	@Override
	public void isExistFilePath(File file) {
		// 파일 경로 검증
		if(!file.exists()) {
			throw new RuntimeException("파일 경로를 찾을 수 없음."); // 파일 경로를 찾을 수 없음
		}
	}
}
