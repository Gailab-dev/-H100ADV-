package com.disabled.service;

import javax.servlet.http.HttpServletResponse;

import com.disabled.common.ExcelSheetSpec;
import com.disabled.model.FineAdvanceNoticeSpec;
import com.disabled.model.MonthlyStatsWithChartSpec;

public interface ExcelService {
	public void download(String fileName, ExcelSheetSpec sheet, HttpServletResponse response);

	public void downloadFineAdvanceNotice(String fileName, FineAdvanceNoticeSpec sheet, HttpServletResponse response);

	public void downloadMonthlyStatsWithChart(String fileName, MonthlyStatsWithChartSpec sheet,
			HttpServletResponse response);
}
