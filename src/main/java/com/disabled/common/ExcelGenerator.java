package com.disabled.common;

import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import org.apache.poi.common.usermodel.PictureType;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.ClientAnchor;
import org.apache.poi.ss.usermodel.Color;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.Drawing;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Picture;
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
	
	public void generateFineAdvanceNotice(String fileName, FineAdvanceNoticeSpec spec, HttpServletResponse response) {

	    String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replace("+", "%20");
	    response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
	    response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + encoded);

	    try (XSSFWorkbook wb = new XSSFWorkbook(); OutputStream os = response.getOutputStream()) {

	        XSSFSheet sheet = wb.createSheet("사전통지서");
	        sheet.setDefaultRowHeightInPoints(18f);

	        // ====== 컬럼 폭 (A~L: 12열) ======
	        // A~H(좌측 문서), I~L(우측 이미지)
	        int[] widths = {
	                12, 14, 14, 16, 12, 14, 14, 16,   // A~H
	                18, 18, 18, 18                    // I~L
	        };
	        for (int c = 0; c < widths.length; c++) sheet.setColumnWidth(c, widths[c] * 256);

	        // ====== 필요한 행 생성 ======
	        // 스샷은 대략 1~25행 사용. POI는 0-based라 0~24 생성.
	        for (int r = 0; r <= 24; r++) {
	            Row row = sheet.createRow(r);
	            row.setHeightInPoints(18f);
	        }

	        // 우측 이미지 영역 행 높이 크게 (스샷 느낌)
	        // 4~11행(인덱스 3~10), 12~19행(인덱스 11~18)
	        for (int r = 3; r <= 10; r++) sheet.getRow(r).setHeightInPoints(32f);
	        for (int r = 11; r <= 18; r++) sheet.getRow(r).setHeightInPoints(32f);

	        Map<String, CellStyle> styles = createStyles(wb);

	        // =====================================================================
	        // 1) 타이틀 (A2~D2) : 스샷처럼 왼쪽만 파란 바
	        // =====================================================================
	        CellRangeAddress rgTitle = new CellRangeAddress(1, 1, 0, 3); // A2:D2
	        mergeAndStyle(sheet, rgTitle, styles.get("title"));
	        setCell(sheet, 1, 0, "과태료 부과 사전통지서 및 영수증 (납부자보관용)", styles.get("title"));

	        // =====================================================================
	        // 2) 대상자/주소 (A4~D5)
	        // =====================================================================
	        CellRangeAddress rgSubject = new CellRangeAddress(3, 3, 0, 3); // A4:D4
	        CellRangeAddress rgAddr    = new CellRangeAddress(4, 4, 0, 3); // A5:D5
	        mergeAndStyle(sheet, rgSubject, styles.get("plain"));
	        mergeAndStyle(sheet, rgAddr, styles.get("plain"));

	        setCell(sheet, 3, 0, "대상자:", styles.get("plain"));
	        setCell(sheet, 4, 0, "주   소:", styles.get("plain"));

	        // (값을 같이 찍고 싶으면 아래처럼)
	        // setCell(sheet, 3, 2, nvl(spec.getSubjectName()), styles.get("plain"));
	        // setCell(sheet, 4, 2, nvl(spec.getAddress()), styles.get("plain"));

	        // =====================================================================
	        // 3) 안내문 (A8~H9 정도)
	        // =====================================================================
	        CellRangeAddress rgNoticeTop = new CellRangeAddress(7, 8, 0, 7); // A8:H9
	        mergeAndStyle(sheet, rgNoticeTop, styles.get("wrap"));
	        setCell(sheet, 7, 0,
	                "귀하에 대하여 장애인·노인·임산부 등의 편익증진 보장에 관한 법률 제 27조에 따라 아래와\n" +
	                "같이 과태료를 부과하고자 하오니 의견이 있으시면 기한내 의견을 주시기 바랍니다.",
	                styles.get("wrap"));

	        // =====================================================================
	        // 4) 표 (A11~H14) / 라벨 파랑, 값 흰색
	        //    [A~B]=라벨1, [C~D]=값1, [E~F]=라벨2, [G~H]=값2
	        // =====================================================================
	        int base = 10; // row 11

	        setTableRow(sheet, base,
	                "차량번호", nvl(spec.getCarNumber()),
	                "위반일시", nvl(spec.getViolationDateTime()),
	                styles.get("tblLabel"), styles.get("tblValue"));

	        setTableRow(sheet, base + 1,
	                "위반장소", nvl(spec.getViolationPlace()),
	                "과태료금액", nvl(spec.getFineAmount()),
	                styles.get("tblLabel"), styles.get("tblValue"));

	        setTableRow(sheet, base + 2,
	                "위반내용", nvl(spec.getViolationContent()),
	                "적용방법", nvl(spec.getApplyLawOrMethod()),
	                styles.get("tblLabel"), styles.get("tblValue"));

	        setTableRow(sheet, base + 3,
	                "감경금액", nvl(spec.getReducedAmount()),
	                "의견제출기한", nvl(spec.getOpinionDeadline()),
	                styles.get("tblLabel"), styles.get("tblValue"));

	        // =====================================================================
	        // 5) 전자납부번호 (A16~H16) 빨간 바
	        // =====================================================================
	        CellRangeAddress rgPay = new CellRangeAddress(15, 15, 0, 7); // A16:H16
	        mergeAndStyle(sheet, rgPay, styles.get("payRed"));
	        setCell(sheet, 15, 0, "전자납부번호", styles.get("payRed"));

	        // =====================================================================
	        // 6) 하단 안내문 (A18~H20)
	        // =====================================================================
	        CellRangeAddress rgNoticeBottom = new CellRangeAddress(17, 19, 0, 7); // A18:H20
	        mergeAndStyle(sheet, rgNoticeBottom, styles.get("wrap"));
	        setCell(sheet, 17, 0,
	                "귀하께서 위 의견제출기한 내에 이의제기 없이 과태료를 납부 하고자하는 경우에는\n" +
	                "감경금액으로 납부하실 수 있습니다. 의견제출은 기한 내에만 가능하며 의견진술을 하여도\n" +
	                "자진납부 기한은 연장되지 않습니다.",
	                styles.get("wrap"));

	        // =====================================================================
	        // 7) 발급일/기관 (A23~H23) - 가운데 정렬 느낌
	        // =====================================================================
	        CellRangeAddress rgIssue = new CellRangeAddress(22, 22, 0, 7); // A23:H23
	        mergeAndStyle(sheet, rgIssue, styles.get("center"));
	        setCell(sheet, 22, 0, nvl(spec.getIssueDate()) + "    " + nvl(spec.getIssuerOrg()), styles.get("center"));

	        // =====================================================================
	        // 8) 우측 이미지 2장 테두리 박스 + 삽입 (I4~L11, I12~L19)
	        // =====================================================================
	        CellRangeAddress rgImg1 = new CellRangeAddress(3, 10, 8, 11);  // I4:L11
	        CellRangeAddress rgImg2 = new CellRangeAddress(11, 18, 8, 11); // I12:L19
	        mergeAndStyle(sheet, rgImg1, styles.get("imgBox"));
	        mergeAndStyle(sheet, rgImg2, styles.get("imgBox"));
	        setThickBorder(sheet, rgImg1);
	        setThickBorder(sheet, rgImg2);

	        Drawing<?> drawing = sheet.createDrawingPatriarch();

	        // 사진은 보통 JPG/PNG 섞임 → bytes 실제 포맷에 맞춰 picture type 지정(여기선 PNG로)
	        addImageToArea(wb, drawing, spec.getPhoto1(), Workbook.PICTURE_TYPE_PNG, 8, 3, 12, 11);
	        addImageToArea(wb, drawing, spec.getPhoto2(), Workbook.PICTURE_TYPE_PNG, 8, 11, 12, 19);

	        // =====================================================================
	        // 9) 우측 하단 도장/수납인 (스샷처럼 아래쪽에 배치)
	        //    - 스샷은 원형 "수납인" + 사각 도장 느낌. 이미지로 넣는 게 가장 현실적.
	        //    - 배치: F22~H24 근처 느낌 → 좌측 하단 쪽에 위치시키려면 col/row 조정
	        //    여기서는 좌측 하단(A~H) 영역의 오른쪽 끝쪽에 넣음.
	        // =====================================================================
	        CellRangeAddress rgSeal = new CellRangeAddress(21, 23, 5, 6); // F22:G24
	        CellRangeAddress rgCollector = new CellRangeAddress(21, 23, 7, 7); // H22:H24 (좁게)
	        mergeAndStyle(sheet, rgSeal, styles.get("plain"));
	        mergeAndStyle(sheet, rgCollector, styles.get("plain"));

	        // 도장/수납인 이미지(리소스) 삽입
	        addImageToArea(wb, drawing, spec.getSealImage(), Workbook.PICTURE_TYPE_PNG, 5, 21, 7, 24);
	        addImageToArea(wb, drawing, spec.getCollectorImage(), Workbook.PICTURE_TYPE_PNG, 7, 21, 8, 24);

	        wb.write(os);
	        response.flushBuffer();

	    } catch (Exception e) {
	        logger.error("사전통지서 엑셀 생성 중 오류", e);
	    }
	}

	// ======================================================================
	// 스타일 생성 (색상은 스샷 느낌으로 세팅, 필요시 RGB만 조정하면 됨)
	// ======================================================================
	private Map<String, CellStyle> createStyles(XSSFWorkbook wb) {
	    Map<String, CellStyle> m = new HashMap<>();

	    // 색
	    XSSFColor titleBlue = new XSSFColor(new java.awt.Color(0, 176, 240), null);   // 타이틀 진파랑(스샷)
	    XSSFColor labelBlue = new XSSFColor(new java.awt.Color(204, 236, 255), null); // 표 라벨 연파랑
	    XSSFColor payRed    = new XSSFColor(new java.awt.Color(255, 199, 206), null); // 전자납부번호 연빨강

	    // 폰트
	    XSSFFont fTitle = wb.createFont();
	    fTitle.setBold(true);
	    fTitle.setColor(IndexedColors.WHITE.getIndex());
	    fTitle.setFontHeightInPoints((short) 11);

	    XSSFFont fNormal = wb.createFont();
	    fNormal.setFontHeightInPoints((short) 10);

	    // 타이틀
	    XSSFCellStyle stTitle = wb.createCellStyle();
	    stTitle.setFont(fTitle);
	    stTitle.setAlignment(HorizontalAlignment.LEFT);
	    stTitle.setVerticalAlignment(VerticalAlignment.CENTER);
	    stTitle.setFillForegroundColor(titleBlue);
	    stTitle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	    m.put("title", stTitle);

	    // 일반
	    XSSFCellStyle stPlain = wb.createCellStyle();
	    stPlain.setFont(fNormal);
	    stPlain.setVerticalAlignment(VerticalAlignment.CENTER);
	    stPlain.setAlignment(HorizontalAlignment.LEFT);
	    m.put("plain", stPlain);

	    // 줄바꿈 문단
	    XSSFCellStyle stWrap = wb.createCellStyle();
	    stWrap.cloneStyleFrom(stPlain);
	    stWrap.setWrapText(true);
	    stWrap.setVerticalAlignment(VerticalAlignment.TOP);
	    m.put("wrap", stWrap);

	    // 표 라벨
	    XSSFCellStyle stLbl = wb.createCellStyle();
	    stLbl.setFont(fNormal);
	    stLbl.setAlignment(HorizontalAlignment.CENTER);
	    stLbl.setVerticalAlignment(VerticalAlignment.CENTER);
	    stLbl.setFillForegroundColor(labelBlue);
	    stLbl.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	    setThinBorder(stLbl);
	    m.put("tblLabel", stLbl);

	    // 표 값
	    XSSFCellStyle stVal = wb.createCellStyle();
	    stVal.cloneStyleFrom(stLbl);
	    stVal.setFillPattern(FillPatternType.NO_FILL);
	    stVal.setAlignment(HorizontalAlignment.LEFT);
	    stVal.setWrapText(true);
	    m.put("tblValue", stVal);

	    // 전자납부번호(빨강)
	    XSSFCellStyle stPay = wb.createCellStyle();
	    stPay.setFont(fNormal);
	    stPay.setAlignment(HorizontalAlignment.LEFT);
	    stPay.setVerticalAlignment(VerticalAlignment.CENTER);
	    stPay.setFillForegroundColor(payRed);
	    stPay.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	    setThinBorder(stPay);
	    m.put("payRed", stPay);

	    // 발급일/기관(센터)
	    XSSFCellStyle stCenter = wb.createCellStyle();
	    stCenter.setFont(fNormal);
	    stCenter.setAlignment(HorizontalAlignment.CENTER);
	    stCenter.setVerticalAlignment(VerticalAlignment.CENTER);
	    m.put("center", stCenter);

	    // 이미지 박스 배경(흰색 + 테두리는 RegionUtil로)
	    XSSFCellStyle stImgBox = wb.createCellStyle();
	    stImgBox.setFont(fNormal);
	    stImgBox.setFillPattern(FillPatternType.NO_FILL);
	    m.put("imgBox", stImgBox);

	    return m;
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
    
}
