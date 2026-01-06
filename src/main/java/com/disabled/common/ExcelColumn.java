package com.disabled.common;

public class ExcelColumn {
	private String field;   // Map key
    private String header;  // 엑셀 헤더명

    public ExcelColumn(String field, String header) {
        this.field = field;
        this.header = header;
    }

    public String getField() {
        return field;
    }

    public String getHeader() {
        return header;
    }
}
