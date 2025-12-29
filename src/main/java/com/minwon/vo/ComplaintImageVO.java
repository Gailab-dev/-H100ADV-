package com.minwon.vo;

import java.util.HashMap;

public class ComplaintImageVO {
	private int ciId;
	private int cId;
	private int uId;
	private String dpName;
	private String psName;
	private String uName;
	private String ciDate;
	private String ciContent;
	private String ciImage;
	private HashMap<String, Object> ciBlob;
	
	public int getCiId() {
		return ciId;
	}
	public void setCiId(int ciId) {
		this.ciId = ciId;
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
	public String getCiDate() {
		return ciDate;
	}
	public void setCiDate(String ciDate) {
		this.ciDate = ciDate;
	}
	public String getCiContent() {
		return ciContent;
	}
	public void setCiContent(String ciContent) {
		this.ciContent = ciContent;
	}
	public String getCiImage() {
		return ciImage;
	}
	public void setCiImage(String ciImage) {
		this.ciImage = ciImage;
	}
	public HashMap<String, Object> getCiBlob() {
		return ciBlob;
	}
	public void setCiBlob(HashMap<String, Object> ciBlob) {
		this.ciBlob = ciBlob;
	}
	
	
}
