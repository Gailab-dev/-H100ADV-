package com.disabled.common;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.ClientAnchor;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.Drawing;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.ss.util.RegionUtil;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

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
	 * 과탤 부과 엑셀 파일 생성
	 * @param fileName
	 * @param spec
	 * @param response
	 */
	public void generateFineAdvanceNotice(String fileName, FineAdvanceNoticeSpec spec, HttpServletResponse response) {

	    String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replace("+", "%20");
	    response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
	    response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + encoded);

	    // 색상
	    XSSFColor BLUE = new XSSFColor(new java.awt.Color(0x0F, 0x9E, 0xD5), null);
	    XSSFColor RED  = new XSSFColor(new java.awt.Color(0xFF, 0x00, 0x00), null);
	    XSSFColor WHITE = new XSSFColor(new java.awt.Color(0xFF, 0xFF, 0xFF), null);

	    try (XSSFWorkbook wb = new XSSFWorkbook(); OutputStream os = response.getOutputStream()) {

	        XSSFSheet sheet = wb.createSheet("사전통지서");

	        // 1) 전체: 행높이 16 / 열너비 12
	        sheet.setDefaultRowHeightInPoints(16f);
	        for (int c = 0; c <= 10; c++) sheet.setColumnWidth(c, 12 * 256); // A~K (0~10)

	        // 필요한 행(최소 0~24 = 25행)
	        for (int r = 0; r <= 24; r++) {
	            Row row = sheet.createRow(r);
	            row.setHeightInPoints(16f);
	        }

	        Map<String, CellStyle> st = createStylesV2(wb, BLUE, RED, WHITE);

	        // ─────────────────────────────────────────────
	        // 2) 대상자/주소 (A4,A5 라벨은 병합 X)
	        //   - 라벨 폰트 #0F9ED5
	        // ─────────────────────────────────────────────
	        setCell(sheet, 3, 0, "대상자", st.get("blueText")); // A4
	        setCell(sheet, 4, 0, "주소",   st.get("blueText")); // A5

	        // 대상자 값
	        setCell(sheet, 3, 1, nvl(spec.getSubjectName()), st.get("plain")); // B4

	        // 주소값 병합: B5:D5
	        CellRangeAddress rgAddrVal = new CellRangeAddress(4, 4, 1, 3); // B5:D5
	        mergeAndStyle(sheet, rgAddrVal, st.get("wrap"));
	        setCell(sheet, 4, 1, nvl(spec.getAddress()), st.get("wrap"));

	        // ─────────────────────────────────────────────
	        // 3) 안내문 (A8:F8, A9:F9) + 폰트 #0F9ED5
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgN1 = new CellRangeAddress(7, 7, 0, 5); // A8:F8
	        CellRangeAddress rgN2 = new CellRangeAddress(8, 8, 0, 5); // A9:F9
	        mergeAndStyle(sheet, rgN1, st.get("blueWrap"));
	        mergeAndStyle(sheet, rgN2, st.get("blueWrap"));
	        setCell(sheet, 7, 0, "귀하에 대하여 장애인·노인·임산부 등의 편익증진 보장에 관한 법률 제 27조에 따라 아래와", st.get("blueWrap"));
	        setCell(sheet, 8, 0, "같이 과태료를 부과하고자 하오니 의견이 있으시면 기한내 의견을 주시기 바랍니다.", st.get("blueWrap"));

	        // ─────────────────────────────────────────────
	        // 4) 표 (A11~F14)
	        // - 테두리: 모든 테두리 / 얇은 실선 / 색 #0F9ED5
	        // - 라벨: A11,A12,A13,A14 (병합 X)
	        // - 값: B~C 병합 + 가운데
	        // - 라벨2: D11.. (병합 X)
	        // - 값2: E~F 병합 + 가운데
	        // ─────────────────────────────────────────────
	        int r0 = 10; // 11행
	        setTableRow6(sheet, r0,     "차량번호", nvl(spec.getCarNumber()),       "위반일시", nvl(spec.getViolationDateTime()), st.get("tblBlue"));
	        setTableRow6(sheet, r0 + 1, "위반장소", nvl(spec.getViolationPlace()),  "과태료금액", nvl(spec.getFineAmount()),      st.get("tblBlue"));
	        setTableRow6(sheet, r0 + 2, "위반내용", nvl(spec.getViolationContent()),"적용방법", nvl(spec.getApplyLawOrMethod()),  st.get("tblBlue"));
	        setTableRow6(sheet, r0 + 3, "감경금액", nvl(spec.getReducedAmount()),   "의견제출기한", nvl(spec.getOpinionDeadline()), st.get("tblBlue"));

	        // ─────────────────────────────────────────────
	        // 5) 전자납부번호 (C16~F16)
	        // - 전체 테두리 빨강, 얇은 실선
	        // - 라벨(A16:B16) 폰트 빨강
	        // - 값(C16:F16) 병합, 왼쪽 정렬
	        // ─────────────────────────────────────────────
	        // CellRangeAddress rgPayAll = new CellRangeAddress(15, 15, 2, 5); // C16:F16
	        // mergeAndStyle(sheet, rgPayAll, st.get("payBorder")); // 전체 스타일 도포(테두리)

	        CellRangeAddress rgPayLabel = new CellRangeAddress(15, 15, 0, 1); // A16:B16
	        CellRangeAddress rgPayVal   = new CellRangeAddress(15, 15, 2, 5); // C16:F16
	        mergeAndStyle(sheet, rgPayLabel, st.get("payLabel"));
	        mergeAndStyle(sheet, rgPayVal,   st.get("payValue"));

	        setCell(sheet, 15, 0, "전자납부번호", st.get("payLabel"));
	        setCell(sheet, 15, 2, nvl(spec.getEPaymentNumber()), st.get("payValue"));

	        // ─────────────────────────────────────────────
	        // 6) 하단 안내문 (A18:F20) 폰트 #0F9ED5
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgBottom = new CellRangeAddress(17, 19, 0, 5); // A18:F20
	        mergeAndStyle(sheet, rgBottom, st.get("blueWrap"));
	        setCell(sheet, 17, 0, "귀하께서 위 의견제출기한 내에 이의제기 없이 과태료를 납부 하고자하는 경우에는 \n 감경금액으로 납부하실 수 있습니다. 의견제출은 기한 내에만 가능하며 의견진술을 \n 하여도 자진납부 기한은 연장되지 않습니다.", st.get("blueWrap"));

	        // ─────────────────────────────────────────────
	        // 7) 발급일 (B23:D23)
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgIssueDate = new CellRangeAddress(22, 22, 1, 3); // B23:D23
	        mergeAndStyle(sheet, rgIssueDate, st.get("center"));
	        setCell(sheet, 22, 1, nvl(spec.getIssueDate()), st.get("center"));

	        // 8) 기관 (D24)
	        setCell(sheet, 23, 3, nvl(spec.getIssuerOrg()), st.get("center")); // D24

	        Drawing<?> drawing = sheet.createDrawingPatriarch();

	        // ─────────────────────────────────────────────
	        // 9) 도장 이미지 병합(E23:E25)
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgSeal = new CellRangeAddress(22, 24, 4, 4); // E23:E25
	        mergeAndStyle(sheet, rgSeal, st.get("plain"));

	        // ─────────────────────────────────────────────
	        // 10) 수납인 이미지 병합(F23:F25) 
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgCollector = new CellRangeAddress(22, 24, 5, 5); // F23:F25
	        mergeAndStyle(sheet, rgCollector, st.get("plain"));

	        addImageToArea(wb, drawing, spec.getSealImage(), detectPictureType(spec.getSealImage()), 4, 22, 5, 25);
	        addImageToArea(wb, drawing, spec.getCollectorImage(), detectPictureType(spec.getCollectorImage()), 5, 22, 6, 25);

	        // ─────────────────────────────────────────────
	        // 11) 우측 이미지 (H4:K12, H13:K22) + 테두리(흰색)
	        // ─────────────────────────────────────────────
	        CellRangeAddress rgImg1 = new CellRangeAddress(3, 11, 7, 10);  // H4:K12
	        CellRangeAddress rgImg2 = new CellRangeAddress(12, 21, 7, 10); // H13:K22
	        mergeAndStyle(sheet, rgImg1, st.get("imgWhiteBorder"));
	        mergeAndStyle(sheet, rgImg2, st.get("imgWhiteBorder"));

	        // 이미지 삽입(끝좌표는 +1 개념)
	        addImageToArea(wb, drawing, spec.getPhoto1(), detectPictureType(spec.getPhoto1()), 7, 3, 11, 12);
	        addImageToArea(wb, drawing, spec.getPhoto2(), detectPictureType(spec.getPhoto2()), 7, 12, 11, 22);

	        wb.write(os);
	        response.flushBuffer();

	    } catch (Exception e) {
	        logger.error("사전통지서 엑셀 생성 중 오류", e);
	    }
	}    

	// ======================================================================
	// 스타일 생성 (색상은 스샷 느낌으로 세팅, 필요시 RGB만 조정하면 됨)
	// ======================================================================
	private Map<String, CellStyle> createStylesV2(XSSFWorkbook wb, XSSFColor BLUE, XSSFColor RED, XSSFColor WHITE) {
	    Map<String, CellStyle> m = new HashMap<>();

	    XSSFFont normal = wb.createFont();
	    normal.setFontHeightInPoints((short)10);

	    XSSFFont blueFont = wb.createFont();
	    blueFont.setFontHeightInPoints((short)10);
	    blueFont.setColor(BLUE);

	    XSSFFont redFont = wb.createFont();
	    redFont.setFontHeightInPoints((short)10);
	    redFont.setColor(RED);

	    XSSFCellStyle plain = wb.createCellStyle();
	    plain.setFont(normal);
	    plain.setVerticalAlignment(VerticalAlignment.CENTER);
	    m.put("plain", plain);

	    XSSFCellStyle blueText = wb.createCellStyle();
	    blueText.cloneStyleFrom(plain);
	    blueText.setFont(blueFont);
	    m.put("blueText", blueText);

	    XSSFCellStyle wrap = wb.createCellStyle();
	    wrap.cloneStyleFrom(plain);
	    wrap.setWrapText(true);
	    wrap.setVerticalAlignment(VerticalAlignment.TOP);
	    m.put("wrap", wrap);

	    XSSFCellStyle blueWrap = wb.createCellStyle();
	    blueWrap.setWrapText(true);
	    blueWrap.cloneStyleFrom(wrap);
	    blueWrap.setFont(blueFont);
	    m.put("blueWrap", blueWrap);

	    // 표(파란 테두리)
	    XSSFCellStyle tblBlue = wb.createCellStyle();
	    tblBlue.cloneStyleFrom(plain);
	    setAllBorders(tblBlue, BorderStyle.THIN, BLUE);
	    tblBlue.setAlignment(HorizontalAlignment.CENTER);
	    tblBlue.setWrapText(true);
	    m.put("tblBlue", tblBlue);

	    // 전자납부번호 전체 테두리(빨강)
	    XSSFCellStyle payBorder = wb.createCellStyle();
	    payBorder.cloneStyleFrom(plain);
	    setAllBorders(payBorder, BorderStyle.THIN, RED);
	    m.put("payBorder", payBorder);

	    XSSFCellStyle payLabel = wb.createCellStyle();
	    payLabel.cloneStyleFrom(payBorder);
	    payLabel.setFont(redFont);
	    payLabel.setAlignment(HorizontalAlignment.CENTER);
	    m.put("payLabel", payLabel);

	    XSSFCellStyle payValue = wb.createCellStyle();
	    payValue.cloneStyleFrom(payBorder);
	    payValue.setAlignment(HorizontalAlignment.LEFT);
	    m.put("payValue", payValue);

	    XSSFCellStyle center = wb.createCellStyle();
	    center.cloneStyleFrom(plain);
	    center.setAlignment(HorizontalAlignment.CENTER);
	    m.put("center", center);

	    // 우측 이미지 박스(흰 테두리)
	    XSSFCellStyle imgWhiteBorder = wb.createCellStyle();
	    imgWhiteBorder.cloneStyleFrom(plain);
	    setAllBorders(imgWhiteBorder, BorderStyle.THIN, WHITE);
	    m.put("imgWhiteBorder", imgWhiteBorder);

	    return m;
	}

	private void setAllBorders(XSSFCellStyle st, BorderStyle bs, XSSFColor color) {
	    st.setBorderTop(bs);    st.setTopBorderColor(color);
	    st.setBorderBottom(bs); st.setBottomBorderColor(color);
	    st.setBorderLeft(bs);   st.setLeftBorderColor(color);
	    st.setBorderRight(bs);  st.setRightBorderColor(color);
	}

	private void setThinBorder(CellStyle st) {
	    st.setBorderTop(BorderStyle.THIN);
	    st.setBorderBottom(BorderStyle.THIN);
	    st.setBorderLeft(BorderStyle.THIN);
	    st.setBorderRight(BorderStyle.THIN);
	}

	// ======================================================================
	// 병합 + 병합된 모든 셀에 스타일 깔기
	// ======================================================================
	private void mergeAndStyle(Sheet sheet, CellRangeAddress region, CellStyle style) {
	    sheet.addMergedRegion(region);
	    for (int r = region.getFirstRow(); r <= region.getLastRow(); r++) {
	        Row row = sheet.getRow(r);
	        if (row == null) row = sheet.createRow(r);
	        for (int c = region.getFirstColumn(); c <= region.getLastColumn(); c++) {
	            Cell cell = row.getCell(c);
	            if (cell == null) cell = row.createCell(c);
	            if (style != null) cell.setCellStyle(style);
	        }
	    }
	}

	private void setCell(Sheet sheet, int r, int c, String v, CellStyle style) {
	    Row row = sheet.getRow(r);
	    if (row == null) row = sheet.createRow(r);
	    Cell cell = row.getCell(c);
	    if (cell == null) cell = row.createCell(c);
	    cell.setCellValue(v == null ? "" : v);
	    if (style != null) cell.setCellStyle(style);
	}

	// 표 1행 생성: [A~B]라벨1 [C~D]값1 [E~F]라벨2 [G~H]값2
	private void setTableRow(Sheet sheet, int rowIdx,
	                         String l1, String v1, String l2, String v2,
	                         CellStyle labelStyle, CellStyle valueStyle) {

	    CellRangeAddress rL1 = new CellRangeAddress(rowIdx, rowIdx, 0, 1);
	    CellRangeAddress rV1 = new CellRangeAddress(rowIdx, rowIdx, 2, 3);
	    CellRangeAddress rL2 = new CellRangeAddress(rowIdx, rowIdx, 4, 5);
	    CellRangeAddress rV2 = new CellRangeAddress(rowIdx, rowIdx, 6, 7);

	    mergeAndStyle(sheet, rL1, labelStyle);
	    mergeAndStyle(sheet, rV1, valueStyle);
	    mergeAndStyle(sheet, rL2, labelStyle);
	    mergeAndStyle(sheet, rV2, valueStyle);

	    setCell(sheet, rowIdx, 0, l1, labelStyle);
	    setCell(sheet, rowIdx, 2, v1, valueStyle);
	    setCell(sheet, rowIdx, 4, l2, labelStyle);
	    setCell(sheet, rowIdx, 6, v2, valueStyle);
	}

	// 굵은 테두리(이미지 박스용)
	private void setThickBorder(Sheet sheet, CellRangeAddress region) {
	    RegionUtil.setBorderTop(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderBottom(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderLeft(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderRight(BorderStyle.THICK, region, sheet);
	}

	// 이미지 삽입: (col1,row1) ~ (col2,row2) 영역에 꽉 차게
	private void addImageToArea(Workbook wb, Drawing<?> drawing, byte[] imageBytes, int poiPictureType,
	                            int col1, int row1, int col2, int row2) {
	    if (imageBytes == null || imageBytes.length == 0) return;

	    int pictureIdx = wb.addPicture(imageBytes, poiPictureType);
	    CreationHelper helper = wb.getCreationHelper();
	    ClientAnchor anchor = helper.createClientAnchor();
	    anchor.setCol1(col1);
	    anchor.setRow1(row1);
	    anchor.setCol2(col2);
	    anchor.setRow2(row2);
	    anchor.setAnchorType(ClientAnchor.AnchorType.MOVE_AND_RESIZE);

	    drawing.createPicture(anchor, pictureIdx);
	}

	private String nvl(String s) {
	    return (s == null) ? "" : s;
	}
	
	private int detectPictureType(byte[] bytes) {
	    if (bytes == null || bytes.length < 4) return Workbook.PICTURE_TYPE_PNG;

	    // PNG: 89 50 4E 47
	    if ((bytes[0] & 0xFF) == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
	        return Workbook.PICTURE_TYPE_PNG;
	    }
	    // JPG: FF D8
	    if ((bytes[0] & 0xFF) == 0xFF && (bytes[1] & 0xFF) == 0xD8) {
	        return Workbook.PICTURE_TYPE_JPEG;
	    }
	    return Workbook.PICTURE_TYPE_PNG;
	}

	private void setTableRow6(Sheet sheet, int rowIdx,
	        String leftLabel, String leftValue,
	        String rightLabel, String rightValue,
	        CellStyle cellStyleBlueBorder) {

	// 라벨: A, D (병합 X)
	setCell(sheet, rowIdx, 0, leftLabel, cellStyleBlueBorder); // A
	setCell(sheet, rowIdx, 3, rightLabel, cellStyleBlueBorder); // D

	// 값: B~C 병합, E~F 병합 (가운데)
	CellRangeAddress v1 = new CellRangeAddress(rowIdx, rowIdx, 1, 2); // B:C
	CellRangeAddress v2 = new CellRangeAddress(rowIdx, rowIdx, 4, 5); // E:F
	mergeAndStyle(sheet, v1, cellStyleBlueBorder);
	mergeAndStyle(sheet, v2, cellStyleBlueBorder);

	setCell(sheet, rowIdx, 1, leftValue, cellStyleBlueBorder);
	setCell(sheet, rowIdx, 4, rightValue, cellStyleBlueBorder);
	}
    
}


