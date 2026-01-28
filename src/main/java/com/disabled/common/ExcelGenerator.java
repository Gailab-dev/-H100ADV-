package com.disabled.common;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;

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
import org.apache.poi.xddf.usermodel.chart.AxisCrosses;
import org.apache.poi.xddf.usermodel.chart.AxisPosition;
import org.apache.poi.xddf.usermodel.chart.ChartTypes;
import org.apache.poi.xddf.usermodel.chart.LegendPosition;
import org.apache.poi.xddf.usermodel.chart.MarkerStyle;
import org.apache.poi.xddf.usermodel.chart.XDDFCategoryAxis;
import org.apache.poi.xddf.usermodel.chart.XDDFChartLegend;
import org.apache.poi.xddf.usermodel.chart.XDDFDataSource;
import org.apache.poi.xddf.usermodel.chart.XDDFDataSourcesFactory;
import org.apache.poi.xddf.usermodel.chart.XDDFLineChartData;
import org.apache.poi.xddf.usermodel.chart.XDDFNumericalDataSource;
import org.apache.poi.xddf.usermodel.chart.XDDFValueAxis;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFChart;
import org.apache.poi.xssf.usermodel.XSSFClientAnchor;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFDrawing;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.disabled.model.FineAdvanceNoticeSpec;
import com.disabled.model.MonthlyStatsWithChartSpec;

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
	
	// ====== 과태료부과 사전통지서 [S] ======
	/**
	 * 과태료 부과 엑셀 파일 생성
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
	// 과태료부과 사전통지서 - 스타일 생성 (색상은 스샷 느낌으로 세팅, 필요시 RGB만 조정하면 됨)
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
	
	// 과태료부과 사전통지서 - 모서리
	private void setAllBorders(XSSFCellStyle st, BorderStyle bs, XSSFColor color) {
	    st.setBorderTop(bs);    st.setTopBorderColor(color);
	    st.setBorderBottom(bs); st.setBottomBorderColor(color);
	    st.setBorderLeft(bs);   st.setLeftBorderColor(color);
	    st.setBorderRight(bs);  st.setRightBorderColor(color);
	}
	
	// 과태료부과 사전통지서 - 가는 선
	private void setThinBorder(CellStyle st) {
	    st.setBorderTop(BorderStyle.THIN);
	    st.setBorderBottom(BorderStyle.THIN);
	    st.setBorderLeft(BorderStyle.THIN);
	    st.setBorderRight(BorderStyle.THIN);
	}

	// ======================================================================
	// 과태료부과 사전통지서 - 병합 + 병합된 모든 셀에 스타일 깔기
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

	// 과태료부과 사전통지서 - 셀 설정
	private void setCell(Sheet sheet, int r, int c, String v, CellStyle style) {
	    Row row = sheet.getRow(r);
	    if (row == null) row = sheet.createRow(r);
	    Cell cell = row.getCell(c);
	    if (cell == null) cell = row.createCell(c);
	    cell.setCellValue(v == null ? "" : v);
	    if (style != null) cell.setCellStyle(style);
	}

	// 과태료부과 사전통지서 - 표 1행 생성: [A~B]라벨1 [C~D]값1 [E~F]라벨2 [G~H]값2
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

	// 과태료부과 사전통지서 - 굵은 테두리(이미지 박스용)
	private void setThickBorder(Sheet sheet, CellRangeAddress region) {
	    RegionUtil.setBorderTop(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderBottom(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderLeft(BorderStyle.THICK, region, sheet);
	    RegionUtil.setBorderRight(BorderStyle.THICK, region, sheet);
	}
	
	// 과태료부과 사전통지서 - 이미지 삽입: (col1,row1) ~ (col2,row2) 영역에 꽉 차게
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

	// 과태료부과 사전통지서 - 문자열 null 처리
	private String nvl(String s) {
	    return (s == null) ? "" : s;
	}
	
	// 과태료부과 사전통지서 - 이미지 확장자 설정(png,jpg 호환 위함)
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

	// 과태료부과 사전통지서 - 표 설정
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
	// ====== 과태료부과 사전통지서 [E] ======
	
	
	// ====== 월별 이벤트 통계 [S] ======
	/**
	 * 월별 이벤트 통계 엑셀 파일 생성
	 * @param fileName
	 * @param sheet
	 * @param response
	 */
	public void generateMonthlyStatsWithChart(String fileName, MonthlyStatsWithChartSpec monthyStatsWithChartSheet,
			HttpServletResponse response) {
		 try {
		        String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replace("+", "%20");
		        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
		        response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + encoded);

		        try (XSSFWorkbook wb = new XSSFWorkbook(); OutputStream os = response.getOutputStream()) {

		            XSSFSheet sheet = wb.createSheet("통계");
		            sheet.setDefaultRowHeightInPoints(16f);
		            sheet.setDefaultColumnWidth(12);

		            // ===== 스타일 =====
		            Map<String, CellStyle> st = createStatsStyles(wb);

		            // ===== 1) 상단 타이틀 =====
		            setCellStats(sheet, 1, 1, "불법주차 유형별 통계 (그래프)", st.get("title"));

		            // ===== 2) 하단 타이틀 =====
		            setCellStats(sheet, 21, 1, "불법주차 유형별 통계 (테이블)", st.get("title"));

		            // ===== 3) statsByMonth -> months / series 구조로 변환 =====
		            // months: ["2025.06", "2025.07", ...]
		            // seriesMap: { "미등록차량":[...], "위험상황":[...], ... }
		            StatsMatrix matrix = buildMatrix(monthyStatsWithChartSheet.getData(), monthyStatsWithChartSheet.getStCd());

		            List<String> months = matrix.months;
		            LinkedHashMap<String, List<Integer>> seriesMap = matrix.seriesMap; // 순서 유지

		            // ===== 4) 표 작성 위치 (스크린샷 느낌) =====
		            // 표 헤더: C23부터 (row=22, col=2)
		            int tableTopRow = 22; // 0-based => 23행
		            int tableLabelCol = 1; // B
		            int tableMonthStartCol = 2; // C

		            // 월 헤더 (C23~)
		            for (int i = 0; i < months.size(); i++) {
		            	setCellStats(sheet, tableTopRow, tableMonthStartCol + i, months.get(i), st.get("hdr"));
		            }

		            // 유형명 + 값
		            int row = tableTopRow + 1; // 24행부터
		            for (Map.Entry<String, List<Integer>> e : seriesMap.entrySet()) {
		            	setCellStats(sheet, row, tableLabelCol, e.getKey(), st.get("rowHdr"));

		                List<Integer> vals = e.getValue();
		                for (int i = 0; i < months.size(); i++) {
		                    int v = (vals != null && i < vals.size() && vals.get(i) != null) ? vals.get(i) : 0;
		                    setCellNumber(sheet, row, tableMonthStartCol + i, v, st.get("cell"));
		                }
		                row++;
		            }

		            int seriesCount = seriesMap.size();
		            int tableBottomRow = tableTopRow + seriesCount; // 마지막 데이터 행

		            // 테이블 외곽 포함 테두리(원하면)
		            // (B23 ~ (C+months-1)(23+seriesCount))
		            setRegionBorderThinBlue(sheet,
		                    new CellRangeAddress(tableTopRow, tableBottomRow, tableLabelCol, tableMonthStartCol + months.size() - 1),
		                    new java.awt.Color(0x0F, 0x9E, 0xD5)
		            );

		            // ===== 5) 차트 생성 (표 범위 참조) =====
		            XSSFDrawing drawing = sheet.createDrawingPatriarch();

		            // 차트 위치: B4 ~ N16 정도
		            XSSFClientAnchor anchor = new XSSFClientAnchor();
		            anchor.setCol1(1);  anchor.setRow1(3);   // B4
		            anchor.setCol2(14); anchor.setRow2(16);  // O16 근처
		            XSSFChart chart = drawing.createChart(anchor);

		            // 범례
		            XDDFChartLegend legend = chart.getOrAddLegend();
		            legend.setPosition(LegendPosition.BOTTOM);

		            // 축
		            XDDFCategoryAxis bottomAxis = chart.createCategoryAxis(AxisPosition.BOTTOM);
		            XDDFValueAxis leftAxis = chart.createValueAxis(AxisPosition.LEFT);
		            leftAxis.setCrosses(AxisCrosses.AUTO_ZERO);

		            // X축(월) 범위: C23 ~ ...
		            CellRangeAddress xRange = new CellRangeAddress(
		                    tableTopRow, tableTopRow,
		                    tableMonthStartCol, tableMonthStartCol + months.size() - 1
		            );

		            XDDFDataSource<String> xs = XDDFDataSourcesFactory.fromStringCellRange(sheet, xRange);

		            XDDFLineChartData data = (XDDFLineChartData) chart.createData(ChartTypes.LINE, bottomAxis, leftAxis);

		            // 시리즈 추가 (각 행이 한 시리즈)
		            int sIdx = 0;
		            for (int s = 0; s < seriesCount; s++) {
		                int rowIdx = tableTopRow + 1 + s;
		                CellRangeAddress yRange = new CellRangeAddress(
		                        rowIdx, rowIdx,
		                        tableMonthStartCol, tableMonthStartCol + months.size() - 1
		                );

		                XDDFNumericalDataSource<Double> ys = XDDFDataSourcesFactory.fromNumericCellRange(sheet, yRange);

		                String seriesName = (String) seriesMap.keySet().toArray()[s];
		                XDDFLineChartData.Series series = (XDDFLineChartData.Series) data.addSeries(xs, ys);
		                series.setTitle(seriesName, null);
		                series.setSmooth(false);
		                series.setMarkerStyle(MarkerStyle.CIRCLE);
		                sIdx++;
		            }

		            chart.plot(data);

		            wb.write(os);
		            response.flushBuffer();
		        }

		    } catch (Exception e) {
		        logger.error("월별 통계(표+차트) 엑셀 생성 중 오류", e);
		    }
		
	}
	
	// 월별 이벤트 통계 - 쿼리 결과를 월 별 리스트로 변환
	/** 쿼리 결과 -> 월 리스트 + (유형명 -> 월별카운트) */
	private StatsMatrix buildMatrix(List<Map<String,Object>> rows, Integer stCdFilter) {

	    // 쿼리는 ORDER BY m.month, c.st_cd 이므로 month는 순서대로 들어옴
	    LinkedHashSet<String> monthSet = new LinkedHashSet<>();
	    // st_cd -> (month -> cnt)
	    Map<Integer, Map<String, Integer>> tmp = new HashMap<>();

	    for (Map<String,Object> r : rows) {
	        String month = Objects.toString(r.get("st_date"), ""); // 예: "2025-06"
	        Integer cd = (r.get("st_cd") instanceof Number) ? ((Number) r.get("st_cd")).intValue() : null;
	        Integer cnt = (r.get("st_cnt") instanceof Number) ? ((Number) r.get("st_cnt")).intValue() : 0;

	        if (month.isEmpty() || cd == null) continue;

	        // stCdFilter가 있으면 해당 코드만 사용(표/차트에서 다른 시리즈 숨김)
	        if (stCdFilter != null && cd.intValue() != stCdFilter.intValue()) continue;

	        monthSet.add(month);
	        tmp.computeIfAbsent(cd, k -> new HashMap<>()).put(month, cnt);
	    }

	    // month 문자열을 "YYYY.MM"로 표시 (스크샷)
	    List<String> rawMonths = new ArrayList<>(monthSet); // "YYYY-MM"
	    List<String> months = new ArrayList<>();
	    for (String m : rawMonths) months.add(m.replace("-", "."));

	    // 코드 표시 순서(원하면 1,4,5,6 고정)
	    List<Integer> codeOrder = Arrays.asList(1, 4, 5, 6);
	    if (stCdFilter != null) codeOrder = Collections.singletonList(stCdFilter);

	    LinkedHashMap<String, List<Integer>> seriesMap = new LinkedHashMap<>();
	    for (Integer cd : codeOrder) {
	        // 데이터가 아예 없으면 건너뛰기(필요시)
	        if (!tmp.containsKey(cd)) continue;

	        String name = codeName(cd); // 유형명
	        List<Integer> vals = new ArrayList<>();
	        for (String rawMonth : rawMonths) {
	            int v = tmp.get(cd).getOrDefault(rawMonth, 0);
	            vals.add(v);
	        }
	        seriesMap.put(name, vals);
	    }

	    // stCdFilter가 없고 tmp가 비어버린 경우(이론상 거의 없음) 대비
	    if (seriesMap.isEmpty()) {
	        // 최소 12개월이라도 보이게 하고 싶으면 여기서 month를 생성해서 0으로 채우면 됨
	    }

	    StatsMatrix out = new StatsMatrix();
	    out.months = months;
	    out.seriesMap = seriesMap;
	    return out;
	}

	private String codeName(int cd) {
	    switch (cd) {
	        case 1: return "미등록차량";
	        case 4: return "위험상황";
	        case 5: return "물건적재";
	        case 6: return "이중주차";
	        // 2,3까지 확장 가능
	        case 2: return "장애인미탑승";
	        case 3: return "스티커불법사용";
	        default: return "코드" + cd;
	    }
	}

	// 월별 이벤트 통계
	private static class StatsMatrix {
	    List<String> months;
	    LinkedHashMap<String, List<Integer>> seriesMap;
	}

	// 월별 이벤트 통계 - 엑셀 스타일 설정
	private Map<String, CellStyle> createStatsStyles(XSSFWorkbook wb) {
	    Map<String, CellStyle> m = new HashMap<>();

	    // 타이틀
	    XSSFFont titleFont = wb.createFont();
	    titleFont.setBold(true);
	    titleFont.setFontHeightInPoints((short) 12);

	    XSSFCellStyle title = wb.createCellStyle();
	    title.setFont(titleFont);
	    title.setAlignment(HorizontalAlignment.LEFT);
	    title.setVerticalAlignment(VerticalAlignment.CENTER);
	    m.put("title", title);

	    // 테두리 + 헤더
	    XSSFFont hdrFont = wb.createFont();
	    hdrFont.setBold(true);

	    XSSFCellStyle hdr = wb.createCellStyle();
	    hdr.setFont(hdrFont);
	    hdr.setAlignment(HorizontalAlignment.CENTER);
	    hdr.setVerticalAlignment(VerticalAlignment.CENTER);
	    setThinBorderAll(hdr);
	    m.put("hdr", hdr);

	    XSSFCellStyle rowHdr = wb.createCellStyle();
	    rowHdr.cloneStyleFrom(hdr);
	    rowHdr.setAlignment(HorizontalAlignment.LEFT);
	    m.put("rowHdr", rowHdr);

	    XSSFCellStyle cell = wb.createCellStyle();
	    cell.setAlignment(HorizontalAlignment.CENTER);
	    cell.setVerticalAlignment(VerticalAlignment.CENTER);
	    setThinBorderAll(cell);
	    m.put("cell", cell);

	    return m;
	}

	// 월별 이벤트 통계 - 테두리 
	private void setThinBorderAll(CellStyle st) {
	    st.setBorderTop(BorderStyle.THIN);
	    st.setBorderBottom(BorderStyle.THIN);
	    st.setBorderLeft(BorderStyle.THIN);
	    st.setBorderRight(BorderStyle.THIN);
	}

	// 월별 이벤트 통계 - 셀 설정
	private void setCellStats(Sheet sheet, int r, int c, String v, CellStyle style) {
	    Row row = sheet.getRow(r);
	    if (row == null) row = sheet.createRow(r);
	    Cell cell = row.getCell(c);
	    if (cell == null) cell = row.createCell(c);
	    cell.setCellValue(v == null ? "" : v);
	    if (style != null) cell.setCellStyle(style);
	}

	// 월별 이벤트 통계 - 셀 스타일 설정
	private void setCellNumber(Sheet sheet, int r, int c, double v, CellStyle style) {
	    Row row = sheet.getRow(r);
	    if (row == null) row = sheet.createRow(r);
	    Cell cell = row.getCell(c);
	    if (cell == null) cell = row.createCell(c);
	    cell.setCellValue(v);
	    if (style != null) cell.setCellStyle(style);
	}

	// 테두리 색 지정까지 하고 싶을 때(원하면)
	// #0F9ED5 같이 색 지정 가능
	private void setRegionBorderThinBlue(XSSFSheet sheet, CellRangeAddress region, java.awt.Color color) {
	    XSSFColor xColor = new XSSFColor(color, null);
	    RegionUtil.setBorderTop(BorderStyle.THIN, region, sheet);
	    RegionUtil.setBorderBottom(BorderStyle.THIN, region, sheet);
	    RegionUtil.setBorderLeft(BorderStyle.THIN, region, sheet);
	    RegionUtil.setBorderRight(BorderStyle.THIN, region, sheet);

	    RegionUtil.setTopBorderColor(xColor.getIndex(), region, sheet);
	    RegionUtil.setBottomBorderColor(xColor.getIndex(), region, sheet);
	    RegionUtil.setLeftBorderColor(xColor.getIndex(), region, sheet);
	    RegionUtil.setRightBorderColor(xColor.getIndex(), region, sheet);
	}
	
	// ====== 통계 화면 엑셀 관련[E] ======
    
}


