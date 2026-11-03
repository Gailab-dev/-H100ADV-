/**
 * H100 공통 페이지네이션 (36번 WP-C)
 *  - 총 건수, 현재/전체 페이지, 처음/이전/번호/다음/마지막을 한 줄로 그린다.
 *  - 개수 선택(10/20/30개 보기)은 없다. 한 페이지 크기는 서버가 화면별 상수로 고정한다.
 *
 * 사용법 1) 서버 렌더 화면(eventList, deviceList): 빈 div 에 data 속성만 주면 DOMContentLoaded 에서 자동 렌더.
 *   <div class="h100-pg" data-total="${paginationInfo.totalRecordCount}"
 *        data-page="${paginationInfo.currentPageNo}" data-page-size="${paginationInfo.recordCountPerPage}"
 *        data-handler="goPage"></div>
 *   → 번호 클릭 시 전역 함수 goPage(pageNo) 호출.
 *
 * 사용법 2) AJAX 화면(sipCallLog): H100Pagination.render(el, { total, page, pageSize, onPage })
 */
(function (global) {
	'use strict';

	var BLOCK_SIZE = 10; // 한 번에 보여줄 번호 개수(기존 eGov PaginationInfo.pageSize 와 동일)

	function toInt(v, def) {
		var n = parseInt(v, 10);
		return isNaN(n) ? def : n;
	}

	function fmt(n) {
		try { return Number(n).toLocaleString('ko-KR'); } catch (e) { return String(n); }
	}

	function btn(label, page, cls, disabled, title) {
		return '<button type="button" class="h100-pg-btn ' + cls + '" data-page="' + page + '"'
			+ (title ? ' title="' + title + '" aria-label="' + title + '"' : '')
			+ (disabled ? ' disabled' : '') + '>' + label + '</button>';
	}

	/** 페이지네이션 HTML 생성 */
	function build(total, page, pageSize) {
		total = Math.max(0, toInt(total, 0));
		pageSize = Math.max(1, toInt(pageSize, 10));
		var lastPage = Math.max(1, Math.ceil(total / pageSize));
		page = Math.min(Math.max(1, toInt(page, 1)), lastPage);

		var blockStart = Math.floor((page - 1) / BLOCK_SIZE) * BLOCK_SIZE + 1;
		var blockEnd = Math.min(blockStart + BLOCK_SIZE - 1, lastPage);
		var atFirst = (page <= 1);
		var atLast = (page >= lastPage);

		var nav = '';
		nav += btn('&laquo;', 1, 'pg-first', atFirst, '처음');
		nav += btn('&lsaquo;', page - 1, 'pg-prev', atFirst, '이전');
		for (var p = blockStart; p <= blockEnd; p++) {
			nav += '<button type="button" class="h100-pg-btn pg-num' + (p === page ? ' active' : '') + '" data-page="' + p + '"'
				+ (p === page ? ' aria-current="page"' : '') + '>' + p + '</button>';
		}
		nav += btn('&rsaquo;', page + 1, 'pg-next', atLast, '다음');
		nav += btn('&raquo;', lastPage, 'pg-last', atLast, '마지막');

		return '<span class="h100-pg-info">총 <b>' + fmt(total) + '</b>건 · <b>' + fmt(page) + '</b> / ' + fmt(lastPage) + ' 페이지</span>'
			+ '<span class="h100-pg-nav">' + nav + '</span>'
			+ '<span class="h100-pg-spacer"></span>';
	}

	/**
	 * el 안에 페이지네이션을 그린다.
	 * @param el  컨테이너(.h100-pg)
	 * @param opt { total, page, pageSize, onPage(pageNo) }
	 */
	function render(el, opt) {
		if (!el) return;
		el.classList.add('h100-pg');
		el.innerHTML = build(opt.total, opt.page, opt.pageSize);
		el.__h100PgHandler = opt.onPage;
		if (!el.__h100PgBound) {
			el.__h100PgBound = true;
			el.addEventListener('click', function (e) {
				var b = e.target.closest ? e.target.closest('.h100-pg-btn') : null;
				if (!b || b.disabled || !el.contains(b)) return;
				var p = toInt(b.getAttribute('data-page'), 0);
				if (p >= 1 && typeof el.__h100PgHandler === 'function') el.__h100PgHandler(p);
			});
		}
	}

	/** data 속성 기반 자동 초기화(서버 렌더 화면용) */
	function autoInit() {
		var els = document.querySelectorAll('.h100-pg[data-handler]');
		Array.prototype.forEach.call(els, function (el) {
			var name = el.getAttribute('data-handler');
			render(el, {
				total: el.getAttribute('data-total'),
				page: el.getAttribute('data-page'),
				pageSize: el.getAttribute('data-page-size'),
				onPage: function (p) {
					var fn = global[name];
					if (typeof fn === 'function') fn(p);
				}
			});
		});
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', autoInit);
	} else {
		autoInit();
	}

	global.H100Pagination = { render: render, build: build };
})(window);
