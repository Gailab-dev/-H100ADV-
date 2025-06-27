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
	String member_id = "";
	String position = "";
	String department = "";
	String u_name = "";
	String email = "";
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
		
		if (paramName.equals("member_id"))  {
			member_id = URLDecoder.decode(paramValue,"UTF-8");
		} else if (paramName.equals("position")) {
			position = URLDecoder.decode(paramValue,"UTF-8");
		} else if (paramName.equals("department")) {
			department = URLDecoder.decode(paramValue,"UTF-8");
		} else if (paramName.equals("u_name")) {
			u_name = URLDecoder.decode(paramValue,"UTF-8");
		} else if (paramName.equals("email")) {
			email = URLDecoder.decode(paramValue,"UTF-8");
		} else if (paramName.equals("password")) {
			password = URLDecoder.decode(paramValue,"UTF-8");
		}
	}
	
	Connection conn=null;
	PreparedStatement pstmt=null;
    String str="";

    try{
	   String jdbcUrl = "jdbc:mariadb://127.0.0.1:3307/minwon";
       String dbId = "root";
       String dbPass = "asdf";
	
	   Class.forName("org.mariadb.jdbc.Driver");
	   conn = DriverManager.getConnection(jdbcUrl,dbId ,dbPass );
	   
	   String sql= "insert into membership_app (u_name, dp_id, ps_id, u_grade, u_login_id, u_login_pwd, u_email, u_gpki_dn)" +  
			   "values (?,(select dp_id from department where dp_name=?),(select ps_id from position where ps_name=?),?,?,?,?, ?)";
	   pstmt=conn.prepareStatement(sql);
	   pstmt.setString(1, u_name);
       pstmt.setString(2, department);
 	   pstmt.setString(3, position);
 	   pstmt.setString(4, "1");
 	   pstmt.setString(5, member_id);
 	   pstmt.setString(6, password);
 	   pstmt.setString(7, email);
 	   pstmt.setString(8, subDN);
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