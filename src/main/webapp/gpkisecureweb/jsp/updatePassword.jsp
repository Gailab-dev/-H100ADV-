<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.gpki.gpkiapi.exception.GpkiApiException"%>
<%@ page import="java.util.Enumeration"%>
<%@ page import="com.gpki.gpkiapi.cert.*" %>
<%@ page import="com.gpki.gpkiapi.cms.*" %>
<%@ page import="com.gpki.gpkiapi.util.*" %>
<%@ page import="com.dsjdf.jdf.Logger" %>
<%@ page import="java.net.URLDecoder" %>
<%@ include file="./gpkisecureweb.jsp"%>
<%@ page import="java.sql.*"%>
<%@ page import="com.minwon.service.CryptoAriaService" %>


<%
	X509Certificate cert      = null; 
	byte[]  signData          = null;
	byte[]  privatekey_random = null;
	String  signType          = null;
	String  subDN             = null;
	String  queryString       = "";
	boolean checkPrivateNum   = false;
	String password = "";
	
	java.math.BigInteger b = new java.math.BigInteger("-1".getBytes()); 

	int message_type =  gpkirequest.getRequestMessageType();

	if( message_type == gpkirequest.ENCRYPTED_SIGNDATA || message_type == gpkirequest.LOGIN_ENVELOP_SIGN_DATA ||
		message_type == gpkirequest.ENVELOP_SIGNDATA || message_type == gpkirequest.SIGNED_DATA){

		cert              = gpkirequest.getSignerCert(); 
		subDN             = cert.getSubjectDN();
		b                 = cert.getSerialNumber();
		signData          = gpkirequest.getSignedData();
		privatekey_random = gpkirequest.getSignerRValue();
		signType          = gpkirequest.getSignType();
	}

	queryString = gpkirequest.getQueryString();
	
	Enumeration params = gpkirequest.getParameterNames(); 
	while (params.hasMoreElements()) {
		String paramName = (String)params.nextElement(); 
		String paramValue = gpkirequest.getParameter(paramName);
		
		if (paramName.equals("password")) {
			password = URLDecoder.decode(paramValue,"UTF-8");
		}
	}
	
	Connection conn=null;
	PreparedStatement pstmt=null;
    String str="";

    try{
	   String jdbcUrl = "jdbc:mariadb://192.168.0.13:3306/minwon";
       String dbId = "root";
       String dbPass = "1234";
	
	   Class.forName("org.mariadb.jdbc.Driver");
	   conn = DriverManager.getConnection(jdbcUrl,dbId ,dbPass );
	   
	   String sql= "update user set u_login_pwd=? where u_gpki_dn=?";
	   pstmt=conn.prepareStatement(sql);
 	   pstmt.setString(1, password);
 	   pstmt.setString(2, subDN);
 	   pstmt.executeUpdate();
    }catch(Exception e){ 
	   e.printStackTrace();
    }finally{
 		if(pstmt != null) 
 			try{pstmt.close();}catch(SQLException sqle){}
 		if(conn != null) 
 			try{conn.close();}catch(SQLException sqle){}
 	}
%>
<%
	response.sendRedirect(request.getContextPath() + "/main/login.do");
%>