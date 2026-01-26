package com.disabled.service;

import javax.servlet.http.HttpServletResponse;

import com.disabled.common.ExcelSheetSpec;
import com.disabled.model.FineAdvanceNoticeSpec;

public interface ExcelService {
	public void download(String fileName, ExcelSheetSpec sheet, HttpServletResponse response);

	public void downloadFineAdvanceNotice(String string, FineAdvanceNoticeSpec sheet, HttpServletResponse response);
}
