package com.disabled.model;

import java.util.List;
import java.util.Map;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class MonthlyStatsWithChartSpec {
	private String sheetName;
	private List<Map<String,Object>> data;
	private Integer stCd;
	
	public MonthlyStatsWithChartSpec(String sheetName, List<Map<String,Object>> statsByMonth, Integer stCd) {
		this.sheetName = sheetName;
		this.data = statsByMonth;
		this.stCd = stCd;
	}
}
