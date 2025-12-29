package com.minwon.vo;

public class PositionVO {
	private int ps_id;  // ID
	private String ps_name;  //이름
	private int ps_rank;  //정렬순서
	
	public int getPs_id() {
		return ps_id;
	}
	public void setPs_id(int ps_id) {
		this.ps_id = ps_id;
	}
	public String getPs_name() {
		return ps_name;
	}
	public void setPs_name(String ps_name) {
		this.ps_name = ps_name;
	}
	public int getPs_rank() {
		return ps_rank;
	}
	public void setPs_rank(int ps_rank) {
		this.ps_rank = ps_rank;
	}

}
