package com.disabled.common;

import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Component;

@Component
public class ExcelGenerator {
	public void generate(
            String fileName,
            ExcelSheetSpec sheetSpec,
            HttpServletResponse response) throws Exception {

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
    }
}
