package com.disabled.service;

import javax.servlet.http.HttpServletResponse;

import com.disabled.common.ExcelSheetSpec;

public interface ExcelService {
	public void download(String fileName, ExcelSheetSpec sheet, HttpServletResponse response);
}
