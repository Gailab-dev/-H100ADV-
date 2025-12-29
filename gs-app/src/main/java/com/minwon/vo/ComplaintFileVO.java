package com.minwon.vo;

public class ComplaintFileVO {
	private int cfId;
	private int cId;
	private int uId;
	private String uName;
	private String cfFileLogic;
	private String cfContent;
	
	public int getCfId() {
		return cfId;
	}
	public void setCfId(int cfId) {
		this.cfId = cfId;
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
	public String getCfFileLogic() {
		return cfFileLogic;
	}
	public void setCfFileLogic(String cfFileLogic) {
		this.cfFileLogic = cfFileLogic;
	}
	public String getCfContent() {
		return cfContent;
	}
	public void setCfContent(String cfContent) {
		this.cfContent = cfContent;
	}
	public String getuName() {
		return uName;
	}
	public void setuName(String uName) {
		this.uName = uName;
	}
	
}
