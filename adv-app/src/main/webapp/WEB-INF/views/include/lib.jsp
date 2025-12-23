<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 

<c:set var="path" value="${pageContext.request.contextPath}" />

<head>
	 <meta charset="utf-8" />
    <meta content="width=device-width, initial-scale=1.0" name="viewport" />
	<link type="image/x-icon" rel="shortcut icon" href="${path}/resources/images/favicon.ico">
	
    <link href="${path}/resources/css/bootstrap.min.css" rel="stylesheet">
    
    <link href="${path}/resources/css/style.css" rel="stylesheet">
    <link href="${path}/resources/css/main_style.css" rel="stylesheet">
    
    <script src="${path }/resources/js/stopPrntScr.js"></script>
    <script src="${path}/resources/js/jquery-3.3.1.min.js"></script>
    <script src="${path}/resources/js/bootstrap.bundle.min.js"></script>
     
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/jstree.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/themes/default/style.min.css">
     
     <!--
    <script src="${path}/resources/js/jstree.min.js"></script>
    <link href="${path}/resources/css/style.min.css" rel="stylesheet">
    -->
    

</head>