package com.disabled.common;

import java.util.List;
import java.util.Map;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class ExcelSheetSpec {
	private String sheetName;
    private List<ExcelColumn> columns;
    private List<Map<String, Object>> data;

    public ExcelSheetSpec(String sheetName,
                          List<ExcelColumn> columns,
                          List<Map<String, Object>> data) {
        this.sheetName = sheetName;
        this.columns = columns;
        this.data = data;
    }
}
