package com.disabled.service.impl;

import java.awt.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.common.ExcelDownloadException;
import com.disabled.common.ExcelGenerator;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.model.ExcelErrorCode;
import com.disabled.model.FineAdvanceNoticeSpec;
import com.disabled.model.MonthlyStatsWithChartSpec;
import com.disabled.service.ExcelService;

@Service
public class ExcelServiceImpl implements ExcelService{
	
	private static final Logger logger = LoggerFactory.getLogger(ExcelServiceImpl.class);

	
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
    @SuppressWarnings("unchecked")
	public void download(String fileName
	            , ExcelSheetSpec sheet
	      
	            , HttpServletResponse response) {
	
		if (sheet == null) {
			throw new ExcelDownloadException(ExcelErrorCode.NO_DATA);
		}
    	
		// 시트는 생성되었으나 데이터가 없는 경우 빈 리스트 추가
		if (sheet.getData() == null ) {
			sheet.setData((java.util.List<Map<String, Object>>) new List());
		}
		
		// 0건이면 로그만 남기고 진행(throw 금지)
		if(sheet.getData().isEmpty()) {
			logger.info("[ExcelDownload] 다운로드할 데이터가 없습니다. fileName={}, sheetName={}",
	                fileName, sheet.getSheetName());
		}
		
		try {
			excelGenerator.generate(fileName, sheet, response);
		} catch (Exception e) {
			throw new ExcelDownloadException(ExcelErrorCode.EXCEL_GENERATION_FAIL, e);
		}
	}
    
    
    /**
     * 과태료부과 사전통지서 엑셀 다운로드
     * @param fileName	// 파일명(String)
	 * @param sheet		// 시트(FineAdvanceNoticeSpec)
	 * @param response	// HttpServletResponse 객체
     */
	@Override
	public void downloadFineAdvanceNotice(String fileName, FineAdvanceNoticeSpec sheet, HttpServletResponse response) {
		
		if (sheet == null) {
			throw new ExcelDownloadException(ExcelErrorCode.NO_DATA);
		}
		
		try {
			excelGenerator.generateFineAdvanceNotice(fileName, sheet, response);
		} catch (Exception e) {
			throw new ExcelDownloadException(ExcelErrorCode.EXCEL_GENERATION_FAIL, e);
		}
	}


	/**
	 * 월별 이벤트 현황 엑셀 다운로드
	 * @param fileName	// 파일명(String)
	 * @param sheet		// 시트(MonthlyStatsWithChartSpec)
	 * @param response	// HttpServletResponse 객체
	 */
	@Override
	public void downloadMonthlyStatsWithChart(String fileName, MonthlyStatsWithChartSpec sheet,
			HttpServletResponse response) {
		if (sheet == null) {
			throw new ExcelDownloadException(ExcelErrorCode.NO_DATA);
		}
		
		try {
			excelGenerator.generateMonthlyStatsWithChart(fileName, sheet, response);
		} catch (Exception e) {
			throw new ExcelDownloadException(ExcelErrorCode.EXCEL_GENERATION_FAIL, e);
		}
		
	}
}
