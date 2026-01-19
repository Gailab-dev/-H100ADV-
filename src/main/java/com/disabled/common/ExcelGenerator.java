package com.disabled.common;

import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.disabled.controller.StatsController;

@Component
public class ExcelGenerator {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(StatsController.class);
	
	
	public void generate(
            String fileName,
            ExcelSheetSpec sheetSpec,
            HttpServletResponse response) throws Exception {

		try {
			 
			System.out.println("POI ver= " + org.apache.poi.Version.getVersion());
			logger.info("POI ver={}", org.apache.poi.Version.getVersion());

			System.out.println("\"commons-io loaded from={}\"" + org.apache.commons.io.IOUtils.class.getProtectionDomain().getCodeSource().getLocation());

			logger.info("commons-io loaded from={}",
			  org.apache.commons.io.IOUtils.class.getProtectionDomain().getCodeSource().getLocation());
			
			Workbook workbook = new XSSFWorkbook();
		        Sheet sheet = workbook.createSheet(sheetSpec.getSheetName());
		        
		        List<ExcelColumn> columns = sheetSpec.getColumns();
		        List<Map<String, Object>> data = sheetSpec.getData();
		        
		        // Header
		        Row headerRow = sheet.createRow(0);
		        for (int i = 0; i < columns.size(); i++) {
		            headerRow.createCell(i)
		                     .setCellValue(columns.get(i).getHeader());
		        }

		        // Body
		        int rowIdx = 1;
		        for (Map<String, Object> rowData : data) {
		            Row row = sheet.createRow(rowIdx++);
		            for (int i = 0; i < columns.size(); i++) {
		                Object value = rowData.get(columns.get(i).getField());
		                row.createCell(i)
		                   .setCellValue(value == null ? "" : value.toString());
		            }
		        }

		        // Response 설정
		        response.setContentType(
		          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		        response.setHeader(
		          "Content-Disposition",
		          "attachment; filename=\"" +
		          URLEncoder.encode(fileName, "UTF-8") + "\"");

		        workbook.write(response.getOutputStream());
		        workbook.close();
		} catch (Exception e) {
			logger.error("엑셀 워크북 생성 중 오류 발생",e);
		}
		
       
    }
}
