<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<div class="vehicle-context">
	<c:if test="${vehicleContext.hasLocation}">
		<section class="vehicle-location" aria-labelledby="vehicleLocationTitle">
			<div class="vehicle-section-heading">
				<h4 id="vehicleLocationTitle">장비 설치 위치</h4>
				<a href="https://map.kakao.com/link/map/${vehicleContext.lat},${vehicleContext.lng}" target="_blank" rel="noopener noreferrer">카카오맵</a>
			</div>
			<div id="vehicleLocationMap" class="vehicle-location-map" hidden
				data-lat="${vehicleContext.lat}" data-lng="${vehicleContext.lng}"
				data-kakao-key="<c:out value='${kakaoMapJsKey}' />"></div>
			<div class="vehicle-location-address"><c:out value="${eventListDetail.ev_dv_addr}" /> <c:out value="${eventListDetail.device_addr_detail}" /></div>
			<div class="vehicle-coordinates"><span>위도 <c:out value="${vehicleContext.lat}" /></span><span>경도 <c:out value="${vehicleContext.lng}" /></span></div>
		</section>
	</c:if>
	<c:if test="${vehicleContext.identified}">
		<section class="vehicle-history" aria-labelledby="vehicleHistoryTitle">
			<div class="vehicle-section-heading">
				<h4 id="vehicleHistoryTitle">동일 차량 최근 발생 이력</h4>
			</div>
			<ol class="vehicle-timeline">
				<c:forEach var="event" items="${vehicleContext.history}">
					<li class="${event.ev_id == eventListDetail.ev_id ? 'is-current' : ''}">
						<c:url var="vehicleEventUrl" value="/eventList/eventListDetail">
							<c:param name="evId" value="${event.ev_id}" /><c:param name="dvId" value="${event.ev_dv_id}" />
						</c:url>
						<a href="<c:out value='${vehicleEventUrl}' />" <c:if test="${event.ev_id == eventListDetail.ev_id}">aria-current="page"</c:if>>
							<time><c:out value="${event.ev_date_display}" /></time>
							<span class="vehicle-history-place"><c:out value="${event.ev_dv_name}" /><small><c:out value="${event.ev_dv_addr}" /></small></span>
							<span class="vehicle-event-type type-${event.ev_cd}"><c:choose>
								<c:when test="${event.ev_cd == 0}">정상</c:when>
								<c:when test="${event.ev_cd == 1}">미등록차량</c:when>
								<c:when test="${event.ev_cd == 2}">장애인미탑승</c:when>
								<c:when test="${event.ev_cd == 3}">스티커 불법 사용</c:when>
								<c:when test="${event.ev_cd == 4}">위험상황</c:when>
								<c:when test="${event.ev_cd == 5}">물건적재</c:when>
								<c:when test="${event.ev_cd == 6}">이중주차</c:when>
								<c:otherwise>기타</c:otherwise>
							</c:choose></span>
						</a>
					</li>
				</c:forEach>
			</ol>
		</section>
	</c:if>
</div>
