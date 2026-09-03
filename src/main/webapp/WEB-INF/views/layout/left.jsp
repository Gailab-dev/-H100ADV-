<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%-- 공용 사이드바 (Tiles defaultLayout). deviceList 하드코딩 사이드바 이관 + 대시보드·SIP CALL 신규 링크 추가.
     활성 메뉴는 요청 URI 로 판정(기존 CSS nth-child(3) 고정 대체) --%>
<c:set var="cp" value="${pageContext.request.contextPath}" />
<%-- patches 2026-07-09(6): active 미적용 진짜 원인 규명 — Spring 뷰 렌더 시 내부 forward 로 인해
     pageContext.request.requestURI 가 원래 URL 이 아니라 forward 대상(내부 JSP 경로)을 가리켜 '/dashboard' 매칭 실패.
     진짜 요청 URL 은 forward/include 속성에 남으므로 세 소스를 모두 합쳐 어디에 담기든 매칭되게 함. --%>
<c:set var="reqUri" value="${pageContext.request.requestURI}" />
<c:set var="fwdUri" value="${requestScope['javax.servlet.forward.request_uri']}" />
<c:set var="incUri" value="${requestScope['javax.servlet.include.request_uri']}" />
<c:set var="uri" value="${reqUri}|${fwdUri}|${incUri}" />
<%-- [debug] 문제 지속 시 페이지 소스에서 확인: req=[${reqUri}] fwd=[${fwdUri}] inc=[${incUri}] --%>
<%-- patches 2026-07-09(4→5): 현재 화면 메뉴를 'hover 했을 때와 똑같은 색'으로 항상 유지(요구 명확화).
     별도 강조색이 아니라 hover 배경(#f1edff)과 동일하게만 적용 → 마우스 위치와 무관하게 그 색 유지.
     CSS 파일 경유로는 계속 무력화되던 이력이 있어 각 링크에 인라인 !important 로 직접 부여(최상위 우선순위).
     linkPad(좌우 20px)는 사이드바 좌우 패딩 0 이후에도 텍스트 위치 유지 → 배경이 폭을 꽉 채움. --%>
<c:set var="linkPad" value="padding-left:20px;padding-right:20px;" />
<c:set var="actSty" />
<c:set var="onDashboard" value="${fn:contains(uri, '/dashboard')}" />
<c:set var="onEventList" value="${fn:contains(uri, '/eventList')}" />
<c:set var="onStats"     value="${fn:contains(uri, '/stats')}" />
<c:set var="onDevice"    value="${fn:contains(uri, '/deviceList')}" />
<c:set var="onSip"       value="${fn:contains(uri, '/sipcall')}" />
<c:set var="onMyInfo"    value="${fn:contains(uri, '/myInfo')}" />

<style>
	/* 헤더 내 정보 아이콘 버튼 — left 메뉴와 동일 아이콘/색상(currentColor, 기본 #000) */
	.header-icon-btn {
		background: none; border: none; cursor: pointer; color: #000;
		padding: 6px; border-radius: 6px; line-height: 0;
		display: flex; align-items: center; transition: background .2s ease, color .2s ease;
	}
	.header-icon-btn:hover { background: #f1edff; color: #6955A2; }

	/* 내 정보 모달 — 내용(iframe)을 충분히 감쌀 정도의 크기만 */
	.gi-modal { position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 1000; display: flex; align-items: center; justify-content: center; }
	.gi-modal-backdrop { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.35); }
	.gi-modal-dialog {
		position: relative; background: #fff; border-radius: 10px;
		box-shadow: 0 10px 30px rgba(0,0,0,0.25);
		width: 560px; max-width: 92vw; height: 640px; max-height: 88vh; overflow: hidden;
	}
	.gi-modal-close {
		position: absolute; top: 6px; right: 10px; z-index: 2;
		background: none; border: none; font-size: 24px; line-height: 1; color: #999; cursor: pointer; padding: 2px 6px;
	}
	.gi-modal-close:hover { color: #333; }
	.gi-modal-frame { width: 100%; height: 100%; border: 0; display: block; }

	/* ===== (15번 4-2) 헤더 알림 ===== */
	/* 주의: layout.css 의 `.header-icon-btn::after { content:'마이페이지' }` 때문에
	   알림 벨은 header-icon-btn 을 재사용하지 않고 전용 클래스를 쓴다.
	   (resources/*.css 는 NoCacheFilter 제외 대상이라 인라인으로 둔다) */
	.noti-icon-btn {
		background: none; border: none; cursor: pointer; color: #000;
		padding: 6px; border-radius: 6px; line-height: 0;
		display: flex; align-items: center; transition: background .2s ease, color .2s ease;
	}
	.noti-icon-btn:hover { background: #f1edff; color: #6955A2; }

	.noti-wrap { position: relative; display: flex; align-items: center; }
	.noti-badge {
		position: absolute; top: 0; right: 0;
		min-width: 16px; height: 16px; padding: 0 4px;
		background: #E53935; color: #fff; border-radius: 8px;
		font-size: 10px; font-weight: 700; line-height: 16px; text-align: center;
		pointer-events: none;
	}
	.noti-popup {
		position: absolute; z-index: 1001;
		width: 330px; max-height: 420px; background: #fff;
		border: 1px solid #e5e1f0; border-radius: 8px;
		box-shadow: 0 6px 20px rgba(0,0,0,0.18);
		display: flex; flex-direction: column; overflow: hidden;
	}
	.noti-popup-header {
		display: flex; align-items: center; justify-content: space-between;
		padding: 10px 12px; border-bottom: 1px solid #f0edf7;
		font-size: 13px; font-weight: 700; color: #383351;
	}
	.noti-popup-header button {
		background: none; border: none; cursor: pointer;
		font-size: 12px; color: #6955A2; padding: 2px 4px;
	}
	.noti-popup-header button:hover { text-decoration: underline; }
	.noti-list { overflow-y: auto; max-height: 372px; }
	.noti-card {
		display: block; padding: 10px 12px; border-bottom: 1px solid #f5f3fa;
		text-decoration: none; color: inherit;
	}
	.noti-card:hover { background: #f9f7ff; }
	.noti-card.unread { background: #f6f2ff; }
	.noti-card.unread .noti-card-title { font-weight: 700; }
	.noti-card-title { font-size: 13px; color: #383351; line-height: 1.4; word-break: break-all; }
	.noti-card-meta { margin-top: 3px; font-size: 11px; color: #999; }
	.noti-type-tag {
		display: inline-block; margin-right: 6px; padding: 1px 6px;
		border-radius: 3px; font-size: 10px; color: #fff;
	}
	.noti-type-tag.event        { background: #E53935; }
	.noti-type-tag.sip_call     { background: #6955A2; }
	.noti-type-tag.device_error { background: #F9A825; }
	.noti-empty { padding: 24px 12px; text-align: center; font-size: 12px; color: #999; }

	/* (33번) 새 알림 도착 시 알림 벨 깜박임. 색상은 신규 정의 대신 기존 경고색(.noti-type-tag.device_error
	   의 #F9A825)을 재사용한다. 0.5초 점등/0.5초 소등 × 3회(총 3초) 후 원래 색으로 복귀(계획서 §2-2). */
	@keyframes notiBlink {
		0%, 100% { background: none; color: #000; }
		50%      { background: #F9A825; color: #fff; }
	}
	.noti-icon-btn.noti-blink { animation: notiBlink 1s ease-in-out 3; }
</style>

<aside class="sidebar" style="padding-left:0 !important;padding-right:0 !important;">
	<div class="logo">
		<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
	</div>

	<ul class="menu">
		<%-- 대시보드 (신설) --%>
		<li><a class="${onDashboard ? 'active' : ''}" style="${linkPad}${onDashboard ? actSty : ''}" href="${cp}/dashboard">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M3 10.5L10 4l7 6.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
				<path d="M5 9.5V16h10V9.5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>대시보드
		</a></li>

		<%-- 불법주차 리스트 --%>
		<li><a class="${onEventList ? 'active' : ''}" style="${linkPad}${onEventList ? actSty : ''}" href="${cp}/eventList/viewEventList.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path fill-rule="evenodd" clip-rule="evenodd" d="M2.70837 5.83203C2.70837 5.66627 2.77422 5.5073 2.89143 5.39009C3.00864 5.27288 3.16761 5.20703 3.33337 5.20703H16.6667C16.8325 5.20703 16.9914 5.27288 17.1086 5.39009C17.2259 5.5073 17.2917 5.66627 17.2917 5.83203C17.2917 5.99779 17.2259 6.15676 17.1086 6.27397C16.9914 6.39118 16.8325 6.45703 16.6667 6.45703H3.33337C3.16761 6.45703 3.00864 6.39118 2.89143 6.27397C2.77422 6.15676 2.70837 5.99779 2.70837 5.83203ZM2.70837 9.9987C2.70837 9.83294 2.77422 9.67397 2.89143 9.55676C3.00864 9.43955 3.16761 9.3737 3.33337 9.3737H12.5C12.6658 9.3737 12.8248 9.43955 12.942 9.55676C13.0592 9.67397 13.125 9.83294 13.125 9.9987C13.125 10.1645 13.0592 10.3234 12.942 10.4406C12.8248 10.5578 12.6658 10.6237 12.5 10.6237H3.33337C3.16761 10.6237 3.00864 10.5578 2.89143 10.4406C2.77422 10.3234 2.70837 10.1645 2.70837 9.9987ZM2.70837 14.1654C2.70837 13.9996 2.77422 13.8406 2.89143 13.7234C3.00864 13.6062 3.16761 13.5404 3.33337 13.5404H7.50004C7.6658 13.5404 7.82477 13.6062 7.94198 13.7234C8.05919 13.8406 8.12504 13.9996 8.12504 14.1654C8.12504 14.3311 8.05919 14.4901 7.94198 14.6073C7.82477 14.7245 7.6658 14.7904 7.50004 14.7904H3.33337C3.16761 14.7904 3.00864 14.7245 2.89143 14.6073C2.77422 14.4901 2.70837 14.3311 2.70837 14.1654Z" fill="currentColor"/>
			</svg>주차 단속 대상 내역
		</a></li>

		<%-- 통계 --%>
		<li><a class="${onStats ? 'active' : ''}" style="${linkPad}${onStats ? actSty : ''}" href="${cp}/stats/viewStat.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<g clip-path="url(#clip0_300_3167)">
					<path d="M18.3333 18.3359H1.66663" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
					<path d="M17.5 18.3346V12.0846C17.5 11.7531 17.3683 11.4352 17.1339 11.2008C16.8995 10.9663 16.5815 10.8346 16.25 10.8346H13.75C13.4185 10.8346 13.1005 10.9663 12.8661 11.2008C12.6317 11.4352 12.5 11.7531 12.5 12.0846V18.3346V4.16797C12.5 2.98964 12.5 2.40047 12.1333 2.03464C11.7683 1.66797 11.1792 1.66797 10 1.66797C8.82083 1.66797 8.2325 1.66797 7.86667 2.03464C7.5 2.39964 7.5 2.9888 7.5 4.16797V18.3346V7.91797C7.5 7.58645 7.3683 7.26851 7.13388 7.03408C6.89946 6.79966 6.58152 6.66797 6.25 6.66797H3.75C3.41848 6.66797 3.10054 6.79966 2.86612 7.03408C2.6317 7.26851 2.5 7.58645 2.5 7.91797V18.3346" stroke="currentColor" stroke-width="1.4"/>
				</g>
				<defs><clipPath id="clip0_300_3167"><rect width="20" height="20" fill="white"/></clipPath></defs>
			</svg>통계
		</a></li>

		<%-- 디바이스 리스트 --%>
		<li><a class="${onDevice ? 'active' : ''}" style="${linkPad}${onDevice ? actSty : ''}" href="${cp}/deviceList/viewDeviceList.do">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M7.50004 15H12.5M15 2.5C15.4421 2.5 15.866 2.67559 16.1786 2.98816C16.4911 3.30072 16.6667 3.72464 16.6667 4.16667V15.8333C16.6667 16.2754 16.4911 16.6993 16.1786 17.0118C15.866 17.3244 15.4421 17.5 15 17.5H5.00004C4.55801 17.5 4.13409 17.3244 3.82153 17.0118C3.50897 16.6993 3.33337 16.2754 3.33337 15.8333V4.16667C3.33337 3.72464 3.50897 3.30072 3.82153 2.98816C4.13409 2.67559 4.55801 2.5 5.00004 2.5H15Z" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
			</svg>단속 장비 현황
		</a></li>

		<%-- SIP CALL (신설) --%>
		<li><a class="${onSip ? 'active' : ''}" style="${linkPad}${onSip ? actSty : ''}" href="${cp}/sipcall/sipCallLog">
			<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
				<path d="M5 3.5c-.8 0-1.5.7-1.4 1.5.4 6 5.4 11 11.4 11.4.8.1 1.5-.6 1.5-1.4v-2.1c0-.6-.4-1.1-1-1.3l-2-.5c-.5-.1-1 .1-1.3.5l-.6.8c-1.8-.9-3.3-2.4-4.2-4.2l.8-.6c.4-.3.6-.8.5-1.3l-.5-2c-.2-.6-.7-1-1.3-1H5Z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round"/>
			</svg>응급 연락망
		</a></li>

		<%-- (요청 2026-07-16) '내 정보' 는 헤더(사용자명 왼쪽 사람아이콘) 모달로 이동 → 사이드바에서 제거 --%>
	</ul>

	<div class="right-group">
		<c:if test="${useTblLog eq false}">
			<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.</div>
		</c:if>
		<div class="rg-option">
			<%-- (15번 4-2) 알림 벨. 30초 폴링으로 안읽은 개수를 배지에 표시하고, 클릭 시 최근 10건 팝업 --%>
			<div class="noti-wrap">
				<button type="button" id="notificationIcon" class="noti-icon-btn" title="알림" aria-label="알림">
					<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
						<path d="M10 18.333c.917 0 1.667-.75 1.667-1.666H8.333c0 .916.75 1.666 1.667 1.666zm5-5V9.167c0-2.559-1.367-4.7-3.75-5.267v-.567c0-.691-.558-1.25-1.25-1.25s-1.25.559-1.25 1.25V3.9C6.375 4.467 5 6.6 5 9.167v4.166l-1.667 1.667v.833h13.334V15L15 13.333z" fill="currentColor"/>
					</svg>
				</button>
				<span class="noti-badge" id="notificationBadge" style="display:none;">0</span>

				<div class="noti-popup" id="notificationPopup" style="display:none;">
					<div class="noti-popup-header">
						<span>알림</span>
						<button type="button" id="markAllReadBtn">모두 읽음</button>
					</div>
					<div class="noti-list" id="notificationList"></div>
				</div>
			</div>
			<%-- 내 정보 버튼(사용자명 왼쪽). 아이콘은 기존 left 사이드바의 '내 정보' 아이콘 그대로 --%>
			<button type="button" id="btnMyInfo" class="header-icon-btn" title="내 정보" aria-label="내 정보">
				<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
					<path d="M9.99998 3.33325C10.884 3.33325 11.7319 3.68444 12.357 4.30956C12.9821 4.93468 13.3333 5.78253 13.3333 6.66659C13.3333 7.55064 12.9821 8.39849 12.357 9.02361C11.7319 9.64873 10.884 9.99992 9.99998 9.99992C9.11592 9.99992 8.26808 9.64873 7.64296 9.02361C7.01784 8.39849 6.66665 7.55064 6.66665 6.66659C6.66665 5.78253 7.01784 4.93468 7.64296 4.30956C8.26808 3.68444 9.11592 3.33325 9.99998 3.33325ZM9.99998 10.8333C12.225 10.8333 16.6666 11.9416 16.6666 14.1666V16.6666H3.33331V14.1666C3.33331 11.9416 7.77498 10.8333 9.99998 10.8333Z" fill="currentColor"/>
				</svg>
			</button>
		</div>
		<div class="user">
			<span class="user-name"><c:out value="${uName}" escapeXml="true" /></span>
		</div>
		<div class="logout">
			<button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
		</div>
	</div>
</aside>

<%-- 내 정보 모달: iframe 으로 /myInfo/modal(공용 chrome 없는 문서) 로드 → 호출 화면과 CSS/JS 완전 분리 --%>
<div id="myInfoModal" class="gi-modal" style="display:none;" role="dialog" aria-modal="true" aria-label="내 정보">
	<div class="gi-modal-backdrop" data-myinfo-close></div>
	<div class="gi-modal-dialog">
		<button type="button" class="gi-modal-close" data-myinfo-close aria-label="닫기">&times;</button>
		<iframe id="myInfoFrame" class="gi-modal-frame" src="" title="내 정보"></iframe>
	</div>
</div>

<script>
	(function() {
		var MYINFO_URL = "${pageContext.request.contextPath}/myInfo/modal";

		function openMyInfoModal() {
			$('#myInfoFrame').attr('src', MYINFO_URL);   // 열 때마다 최신 정보 로드
			$('#myInfoModal').css('display', 'flex');
			$('body').css('overflow', 'hidden');
		}
		function closeMyInfoModal() {
			$('#myInfoModal').hide();
			$('#myInfoFrame').attr('src', '');           // 입력값 정리(다음 오픈 시 새로 로드)
			$('body').css('overflow', '');
		}
		// iframe 내부(저장 완료 등)에서 parent.closeMyInfoModal() 로 닫을 수 있도록 전역 노출
		window.closeMyInfoModal = closeMyInfoModal;

		$(function() {
			$('#btnMyInfo').on('click', openMyInfoModal);
			$(document).on('click', '[data-myinfo-close]', closeMyInfoModal);
			$(document).on('keydown', function(e) {
				if (e.key === 'Escape' && $('#myInfoModal').is(':visible')) closeMyInfoModal();
			});
		});
	})();

	/* ===== (15번 4-2) 헤더 알림 ===== */
	(function() {
		var CTX = "${pageContext.request.contextPath}";
		// (33번) 새 알림이 최대 5초 이내에 반영되어야 한다는 요구사항(계획서 §2-1)에 따라
		// 기존 30초 폴링을 4초로 단축. 04/05번 대시보드 디바이스 상태 갱신도 폴링 방식이라
		// 이 화면과 동일한 폴링 패턴을 그대로 재사용(신규 통신 방식 도입 안 함).
		var POLL_MS = 4000;
		var lastKnownUnread = null; // (33번) 최초 로드 값은 "새로 도착"이 아니므로 깜박임 트리거 기준에서 제외

		// noti_title 은 DB(디바이스명 포함) 에서 온 값이므로 HTML 로 넣기 전에 반드시 이스케이프한다(계획서 §8).
		function escapeHtml(s) {
			return String(s == null ? '' : s)
					.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
					.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
		}

		// 서버가 'YYYY-MM-DD HH:mm:ss' 문자열로 내려준다. 브라우저별 파싱 편차를 피해 직접 분해한다.
		function parseServerDate(s) {
			var m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/.exec(s || '');
			if (!m) return null;
			return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]);
		}

		function formatTime(s) {
			var d = parseServerDate(s);
			if (!d) return escapeHtml(s);

			var diffMin = Math.floor((Date.now() - d.getTime()) / 60000);
			if (diffMin < 1)    return '방금 전';
			if (diffMin < 60)   return diffMin + '분 전';
			if (diffMin < 1440) return Math.floor(diffMin / 60) + '시간 전';
			return escapeHtml(String(s).substring(0, 16));
		}

		var TYPE_LABEL = { event: '단속', sip_call: '응급콜', device_error: '장비이상' };

		// 알림 종류별 이동 대상 (계획서 §4-2)
		function buildTargetUrl(item) {
			if (item.noti_type === 'event') {
				return CTX + '/eventList/viewEventList.do?evId=' + encodeURIComponent(item.noti_target_id);
			}
			if (item.noti_type === 'sip_call') {
				return CTX + '/deviceList/viewDeviceList.do?triggerSerial=' + encodeURIComponent(item.noti_serial);
			}
			if (item.noti_type === 'device_error') {
				return CTX + '/deviceList/viewDeviceList.do?dvId=' + encodeURIComponent(item.noti_dv_id) + '&openErrorLog=true';
			}
			return CTX + '/dashboard/viewDashboard.do';
		}

		function buildNotificationCard(item) {
			var type = item.noti_type || '';
			var tag  = TYPE_LABEL[type] || '알림';
			var unread = (item.noti_is_read == 0) ? ' unread' : '';

			return '<a href="' + escapeHtml(buildTargetUrl(item)) + '" class="noti-card' + unread + '" ' +
					'data-noti-id="' + escapeHtml(item.noti_id) + '">' +
					'<div class="noti-card-title">' + escapeHtml(item.noti_title) + '</div>' +
					'<div class="noti-card-meta">' +
					'<span class="noti-type-tag ' + escapeHtml(type) + '">' + escapeHtml(tag) + '</span>' +
					formatTime(item.noti_reg_date) +
					'</div>' +
					'</a>';
		}

		// (33번) 알림 벨 깜박임 트리거. 연속으로 새 알림이 도착해도 재생 중인 애니메이션을
		// 강제로 재시작할 수 있도록 클래스 제거 → 리플로우 → 재부여 순서를 따른다.
		function triggerNotiBlink() {
			var btn = document.getElementById('notificationIcon');
			if (!btn) return;
			btn.classList.remove('noti-blink');
			void btn.offsetWidth; // 강제 리플로우로 animation 재시작 보장
			btn.classList.add('noti-blink');
		}

		function loadUnreadCount() {
			$.ajax({
				url: CTX + '/notification/unreadCount',
				method: 'GET',
				cache: false,
				success: function(data) {
					var count = (data && data.unread_cnt) || 0;
					if (count > 0) {
						$('#notificationBadge').text(count > 99 ? '99+' : count).show();
					} else {
						$('#notificationBadge').hide();
					}
					// (33번) 직전 폴링보다 안읽은 개수가 늘었으면 새 알림 도착으로 보고 깜박임.
					// 최초 로드(lastKnownUnread===null)는 이미 쌓여있던 개수일 뿐이므로 제외.
					if (lastKnownUnread !== null && count > lastKnownUnread) {
						triggerNotiBlink();
					}
					lastKnownUnread = count;
				}
				// 실패 시 배지를 건드리지 않는다 — 일시적 오류로 기존 표시가 사라지지 않도록.
			});
		}

		function openPopup() {
			$.ajax({
				url: CTX + '/notification/list',
				method: 'GET',
				data: { limit: 10 },
				cache: false,
				success: function(list) {
					var html = '';
					if (!list || list.length === 0) {
						html = '<div class="noti-empty">새 알림이 없습니다.</div>';
					} else {
						$.each(list, function(i, item) { html += buildNotificationCard(item); });
					}
					$('#notificationList').html(html);
					$('#notificationPopup').show();
				},
				error: function() {
					$('#notificationList').html('<div class="noti-empty">알림을 불러오지 못했습니다.</div>');
					$('#notificationPopup').show();
				}
			});
		}

		$(function() {
			loadUnreadCount();
			setInterval(loadUnreadCount, POLL_MS);

			$('#notificationIcon').on('click', function(e) {
				e.stopPropagation();
				if ($('#notificationPopup').is(':visible')) {
					$('#notificationPopup').hide();
				} else {
					openPopup();
				}
			});

			// 팝업 바깥 클릭 시 닫기 (팝업 내부 클릭은 통과)
			$('#notificationPopup').on('click', function(e) { e.stopPropagation(); });
			$(document).on('click', function() { $('#notificationPopup').hide(); });

			// 카드 클릭 — 읽음 처리는 비동기로 보내고 이동은 링크 기본 동작에 맡긴다.
			// (19번 이슈A) 일반 $.ajax(XHR) 은 클릭 직후 <a> 기본 이동이 실행되면 브라우저가
			// 응답 전에 요청 자체를 취소할 수 있어 읽음 처리가 누락되는 경우가 있었다.
			// fetch(..., {keepalive:true}) 는 페이지 이동과 무관하게 전송을 보장한다(sendBeacon과 유사한 용도).
			$(document).on('click', '.noti-card', function() {
				var notiId = $(this).data('noti-id');
				if (!notiId) return;
				var readUrl = CTX + '/notification/read/' + notiId;
				if (window.fetch) {
					fetch(readUrl, { method: 'POST', keepalive: true, credentials: 'same-origin' });
				} else {
					// keepalive 미지원 구형 브라우저 폴백
					$.ajax({ url: readUrl, method: 'POST' });
				}
			});

			$('#markAllReadBtn').on('click', function(e) {
				e.stopPropagation();
				$.ajax({
					url: CTX + '/notification/readAll',
					method: 'POST',
					success: function() {
						$('#notificationBadge').hide();
						$('.noti-card').removeClass('unread');
					}
				});
			});
		});
	})();
</script>
