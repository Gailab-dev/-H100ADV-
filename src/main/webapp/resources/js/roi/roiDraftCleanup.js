/*
 * ROI 편집 임시본 정리 (34번 작업계획서 확정사항 19: "로그아웃 시 삭제").
 * 로그아웃·장기 미사용 로그아웃·다른 PC 로그인으로 인한 로그아웃은 모두 로그인 화면으로 이동하므로,
 * 로그인 화면이 열릴 때 localStorage 의 ROI 임시본('roiDraft:' 접두사)을 모두 지운다.
 * (임시본은 사용자·장비별 키이므로 다른 사용자의 것도 이 브라우저에서는 남기지 않는다.)
 */
(function () {
    'use strict';
    try {
        var prefix = 'roiDraft:';
        var remove = [];
        for (var i = 0; i < localStorage.length; i++) {
            var key = localStorage.key(i);
            if (key && key.indexOf(prefix) === 0) remove.push(key);
        }
        remove.forEach(function (k) { localStorage.removeItem(k); });
    } catch (e) {
        // localStorage 를 쓸 수 없는 환경(차단 등)이면 임시본도 없으므로 무시한다.
    }
})();
