<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div>
	<!-- title -->
	<div>
		<h3>
	    	<c:choose>
      			<c:when test="${rg_depth eq 1}">지역</c:when>
      			<c:when test="${rg_depth eq 2}">구</c:when>
      			<c:when test="${rg_depth eq 3}">동</c:when>
      			<c:otherwise>주차장</c:otherwise>
   			</c:choose>
		</h3>
	</div>
	<div>
		<input type="text" name="rg_name" >
	  	<input type="hidden" name="rg_depth" value="${rg_depth}"/>
  		<input type="hidden" name="rg_org"   value="${rg_org}"/>
  		<input type="hidden" name="rg_p_id"   value="${rg_p_id}"/>
		<button type="button" onclick="addNode()">추가</button>
		<button type="button" onclick="closeTreePopup()">취소</button>
	</div>

</div>