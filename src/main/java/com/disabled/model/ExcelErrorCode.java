package com.disabled.model;

public enum ExcelErrorCode {
    INVALID_PARAM("E001", "요청 파라미터가 올바르지 않습니다."),
    NO_DATA("E002", "다운로드할 데이터가 없습니다."),
    EXCEL_GENERATION_FAIL("E003", "엑셀 파일 생성 중 오류가 발생했습니다."),
    INTERNAL_ERROR("E999", "시스템 오류가 발생했습니다.");
	
    private final String code;
    private final String message;

    ExcelErrorCode(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public String getCode() { return code; }
    public String getMessage() { return message; }
}
