package com.disabled.common;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.apache.poi.common.usermodel.PictureType;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.ClientAnchor;
import org.apache.poi.ss.usermodel.Color;
import org.apache.poi.ss.usermodel.Drawing;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Picture;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.disabled.controller.StatsController;
import com.disabled.model.FineAdvanceNoticeSpec;

@Component
public class ExcelGenerator {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(ExcelGenerator.class);
	
	
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
		        response.flushBuffer(); 
		} catch (Exception e) {
			logger.error("엑셀 워크북 생성 중 오류 발생",e);
		}
       
    }
	
	  /**
     * 과태료 부과 사전통지서 및 영수증(납부자보관용) - 템플릿 기반 생성
     */
    public void generateFineAdvanceNotice(
            String fileName,
            FineAdvanceNoticeSpec spec,
            HttpServletResponse response
    ) {

        // 파일명 헤더(한글 안전)
        String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replace("+", "%20");
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + encoded);

        try (Workbook wb = new XSSFWorkbook(); OutputStream os = response.getOutputStream()) {
            Sheet sheet = wb.createSheet("사전통지서");

            // ====== 레이아웃 기본 설정 ======
            // A~N(14열) 사용한다고 가정 (왼쪽 A~H, 오른쪽 I~N)
            int[] colWidths = {
                    12, 12, 12, 12, 12, 12, 12, 12,   // A~H (텍스트)
                    12, 12, 12, 12, 12, 12           // I~N (이미지)
            };
            for (int i = 0; i < colWidths.length; i++) sheet.setColumnWidth(i, colWidths[i] * 256);

            // 행 높이(대략) - 필요 시 조정
            for (int r = 0; r <= 30; r++) {
                Row row = sheet.createRow(r);
                row.setHeightInPoints(18f);
            }
            // 이미지 들어갈 행은 더 크게
            sheet.getRow(6).setHeightInPoints(120f);
            sheet.getRow(7).setHeightInPoints(120f);
            sheet.getRow(8).setHeightInPoints(120f);
            sheet.getRow(9).setHeightInPoints(120f);

            // ====== 스타일 ======
            Font titleFont = wb.createFont();
            titleFont.setFontHeightInPoints((short) 10);

            Font normalFont = wb.createFont();
            normalFont.setFontHeightInPoints((short) 10);

            CellStyle titleStyle = wb.createCellStyle();
            titleStyle.setFont(titleFont);
            titleStyle.setAlignment(HorizontalAlignment.LEFT);
            titleStyle.setVerticalAlignment(VerticalAlignment.CENTER);

            CellStyle normalStyle = wb.createCellStyle();
            normalStyle.setFont(normalFont);
            normalStyle.setWrapText(true);
            normalStyle.setVerticalAlignment(VerticalAlignment.TOP);

            CellStyle tableLabelStyle = wb.createCellStyle();
            tableLabelStyle.setFont(normalFont);
            tableLabelStyle.setAlignment(HorizontalAlignment.CENTER);
            tableLabelStyle.setVerticalAlignment(VerticalAlignment.CENTER);
            tableLabelStyle.setBorderTop(BorderStyle.THIN);
            tableLabelStyle.setBorderBottom(BorderStyle.THIN);
            tableLabelStyle.setBorderLeft(BorderStyle.THIN);
            tableLabelStyle.setBorderRight(BorderStyle.THIN);

            CellStyle tableValueStyle = wb.createCellStyle();
            tableValueStyle.cloneStyleFrom(tableLabelStyle);
            tableValueStyle.setAlignment(HorizontalAlignment.LEFT);
            tableValueStyle.setWrapText(true);

            // ====== 병합 영역(템플릿) ======
            // 제목 (0행 A~N)
            merge(sheet, 0, 0, 0, 13);
            setCell(sheet, 0, 0, "과태료 부과 사전통지서 및 영수증 (납부자보관용)", titleStyle);

            // 대상자/주소 (2~3행 왼쪽 A~H)
            merge(sheet, 2, 2, 0, 7);
            merge(sheet, 3, 3, 0, 7);
            setCell(sheet, 2, 0, "대상자: " + nvl(spec.getSubjectName()), normalStyle);
            setCell(sheet, 3, 0, "주   소: " + nvl(spec.getAddress()), normalStyle);

            // 안내 문구 (5행~6행 왼쪽 A~H)
            merge(sheet, 5, 6, 0, 7);
            setCell(sheet, 5, 0,
                    "귀하에 대하여 장애인·노인·임산부 등의 편익증진 보장에 관한 법률 제 27조에 따라 아래와 같이 과태료를 부과하고자 하오니 의견이 있으시면 기한내 의견을 주시기 바랍니다.",
                    normalStyle);

            // 오른쪽 이미지 영역(단속 이미지 2장)
            // 사진1: (2~6행, I~N)
            merge(sheet, 2, 6, 8, 13);
            // 사진2: (7~11행, I~N)
            merge(sheet, 7, 11, 8, 13);

            // ====== 표 영역(차량번호~) ======
            // 예: 12~16행 왼쪽 A~N 전체를 표로 사용
            int base = 12;

            // 1줄: 차량번호 | 값 | 위반일시 | 값
            setTablePair(sheet, base, "차량번호", nvl(spec.getCarNumber()), "위반일시", nvl(spec.getViolationDateTime()),
                    tableLabelStyle, tableValueStyle);

            // 2줄: 위반장소 | 값 | 과태료금액 | 값
            setTablePair(sheet, base + 1, "위반장소", nvl(spec.getViolationPlace()), "과태료금액", nvl(spec.getFineAmount()),
                    tableLabelStyle, tableValueStyle);

            // 3줄: 위반내용 | 값 | 적용방법 | 값
            setTablePair(sheet, base + 2, "위반내용", nvl(spec.getViolationContent()), "적용방법", nvl(spec.getApplyLawOrMethod()),
                    tableLabelStyle, tableValueStyle);

            // 4줄: 감경금액 | 값 | 의견제출기한 | 값
            setTablePair(sheet, base + 3, "감경금액", nvl(spec.getReducedAmount()), "의견제출기한", nvl(spec.getOpinionDeadline()),
                    tableLabelStyle, tableValueStyle);

            // 전자납부번호
            merge(sheet, base + 5, base + 5, 0, 7);
            setCell(sheet, base + 5, 0, "전자납부번호: " + nvl(spec.getEPaymentNumber()), normalStyle);

            // 안내 문구(아래)
            merge(sheet, base + 7, base + 9, 0, 7);
            setCell(sheet, base + 7, 0,
                    "귀하께서 위 의견제출기한 내에 이의제기 없이 과태료를 납부 하고자하는 경우에는 감경금액으로 납부하실 수 있습니다. 의견제출은 기한 내에만 가능하며 의견진술을 하여도 자진납부 기한은 연장되지 않습니다.",
                    normalStyle);

            // 발급일/기관 (아래)
            merge(sheet, base + 11, base + 11, 0, 7);
            setCell(sheet, base + 11, 0, nvl(spec.getIssueDate()) + "    " + nvl(spec.getIssuerOrg()), normalStyle);

            // 도장/수납인 이미지 영역(아래 오른쪽)
            merge(sheet, base + 10, base + 12, 8, 10); // 도장
            merge(sheet, base + 10, base + 12, 11, 13); // 수납인

            // ====== 이미지 삽입 ======
            Drawing<?> drawing = sheet.createDrawingPatriarch();

            // 단속 사진 2장
            addImageIfExists(wb, drawing, spec.getPhoto1(), PictureType.PNG, 8, 2, 14, 7);
            addImageIfExists(wb, drawing, spec.getPhoto2(), PictureType.PNG, 8, 7, 14, 12);

            // 도장/수납인
            addImageIfExists(wb, drawing, spec.getSealImage(), PictureType.PNG, 8, base + 10, 11, base + 13);
            addImageIfExists(wb, drawing, spec.getCollectorImage(), PictureType.PNG, 11, base + 10, 14, base + 13);

            wb.write(os);
            response.flushBuffer();

        } catch (Exception e) {
            logger.error("사전통지서 엑셀 생성 중 오류", e);
            // 여기서 swallow하지 말고 상황에 따라 status 설정도 가능
            // response.setStatus(500);
        }
    }

    // ====== 유틸 ======
    /**
     * 엑셀 셀 병합
     * @param sheet	엑셀 시트 객체
     * @param r1	병합 시작열
     * @param r2	병합 끝열
     * @param c1	병합 시작행
     * @param c2	병합 끝행
     */
    private static void merge(Sheet sheet, int r1, int r2, int c1, int c2) {
        sheet.addMergedRegion(new CellRangeAddress(r1, r2, c1, c2));
    }
    
    private static void setCell(Sheet sheet, int r, int c, String v, CellStyle style) {
        Row row = sheet.getRow(r);
        if (row == null) row = sheet.createRow(r);
        Cell cell = row.getCell(c);
        if (cell == null) cell = row.createCell(c);
        cell.setCellValue(v);
        if (style != null) cell.setCellStyle(style);
    }

    private static void setTablePair(
            Sheet sheet, int rowIdx,
            String l1, String v1, String l2, String v2,
            CellStyle labelStyle, CellStyle valueStyle
    ) {
        // [A~B]=label1, [C~H]=value1, [I~J]=label2, [K~N]=value2
        merge(sheet, rowIdx, rowIdx, 0, 1);
        merge(sheet, rowIdx, rowIdx, 2, 7);
        merge(sheet, rowIdx, rowIdx, 8, 9);
        merge(sheet, rowIdx, rowIdx, 10, 13);

        setCell(sheet, rowIdx, 0, l1, labelStyle);
        setCell(sheet, rowIdx, 2, v1, valueStyle);
        setCell(sheet, rowIdx, 8, l2, labelStyle);
        setCell(sheet, rowIdx, 10, v2, valueStyle);

    }
    
    // 이미지 파일 추가
    private static void addImageIfExists(
            Workbook wb,
            Drawing<?> drawing,
            byte[] imageBytes,
            PictureType pictureType,
            int col1, int row1,
            int col2, int row2
    ) throws Exception {
        if (imageBytes == null || imageBytes.length == 0) return;

        int poiType = pictureType.getOoxmlId(); // XSSF(.xlsx) 기준
        int pictureIdx = wb.addPicture(imageBytes, poiType);

        ClientAnchor anchor = wb.getCreationHelper().createClientAnchor();
        anchor.setCol1(col1);
        anchor.setRow1(row1);
        anchor.setCol2(col2);
        anchor.setRow2(row2);
        anchor.setAnchorType(ClientAnchor.AnchorType.MOVE_AND_RESIZE);

        Picture pict = drawing.createPicture(anchor, pictureIdx);
        // pict.resize(); // resize는 셀 크기에 맞춰 자동 조정될 수 있어, 지금은 anchor로 고정 배치 권장
    }

    private static String nvl(String s) {
        return (s == null) ? "" : s;
    }
    
}
