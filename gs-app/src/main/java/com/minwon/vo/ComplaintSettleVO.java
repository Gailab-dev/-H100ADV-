package com.minwon.vo;

public class ComplaintSettleVO {
	private int csId;
	private int cId;
	private int uId;
	private String dpName;
	private String psName;
	private String uName;
	private String csDate;
	private String csContent;
	
	public int getCsId() {
		return csId;
	}
	public void setCsId(int csId) {
		this.csId = csId;
	}
	public int getcId() {
		return cId;
	}
	public void setcId(int cId) {
		this.cId = cId;
	}
	public int getuId() {
		return uId;
	}
	public void setuId(int uId) {
		this.uId = uId;
	}
	public String getDpName() {
		return dpName;
	}
	public void setDpName(String dpName) {
		this.dpName = dpName;
	}
	public String getPsName() {
		return psName;
	}
	public void setPsName(String psName) {
		this.psName = psName;
	}
	public String getuName() {
		return uName;
	}
	public void setuName(String uName) {
		this.uName = uName;
	}
	public String getCsDate() {
		return csDate;
	}
	public void setCsDate(String csDate) {
		this.csDate = csDate;
	}
	public String getCsContent() {
		return csContent;
	}
	public void setCsContent(String csContent) {
		this.csContent = csContent;
	}
}
