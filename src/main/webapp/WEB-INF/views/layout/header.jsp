<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%-- 공용 헤더 (Tiles defaultLayout). deviceList 하드코딩 헤더를 공유 레이아웃으로 이관
     (요청 2026-07-16) 내 정보 진입점을 left 사이드바 → 헤더(사용자명 왼쪽 사람아이콘)로 이동, 클릭 시 모달로 표시 --%>
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
		position: absolute; top: calc(100% + 8px); right: 0; z-index: 1001;
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
</style>

<header class="header">
	<div class="logo">
		<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
	</div>
	<div class="right-group">
		<c:if test="${useTblLog eq false}">
			<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.</div>
		</c:if>
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
		<div class="user">
			<span class="user-name"><c:out value="${uName}" escapeXml="true" /></span>
		</div>
		<div class="logout">
			<button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
		</div>
	</div>
</header>

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
	var POLL_MS = 30000;   // 계획서 §3-3 결정: 30초

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
		$(document).on('click', '.noti-card', function() {
			var notiId = $(this).data('noti-id');
			if (notiId) {
				$.ajax({ url: CTX + '/notification/read/' + notiId, method: 'POST' });
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
