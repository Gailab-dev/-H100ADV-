package com.disabled.service;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.common.ExcelColumn;
import com.disabled.common.ExcelDownloadException;
import com.disabled.common.ExcelGenerator;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.model.ExcelErrorCode;

@Service
public class ExcelService {
	
	@Autowired
	ExcelGenerator excelGenerator;
	
	/**
	 * 엑셀 다운로드 
	 * @param fileName	// 파일명(String)
	 * @param sheet		// 시트(ExcelSheetSpec)
	 * @param columns	// 컬럼(List<ExcelColumn>)
	 * @param data		// 실제 데이터(List<Map<String,Object>>)
	 * @param response	// HttpServletResponse 객체
	 */
    public void download(String fileName
	            , ExcelSheetSpec sheet
	      
	            , HttpServletResponse response) {
	
		if (sheet.getData() == null || sheet.getData().isEmpty()) {
			throw new ExcelDownloadException(ExcelErrorCode.NO_DATA);
		}
		
		try {
			excelGenerator.generate(fileName, sheet, response);
		} catch (Exception e) {
			throw new ExcelDownloadException(ExcelErrorCode.EXCEL_GENERATION_FAIL, e);
		}
	}
}
