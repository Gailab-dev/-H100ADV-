/*
 * ROI 편집기 핵심 로직 (브라우저 + Node 공용, DOM/Konva 비의존).
 * 34번 작업계획서 §5.1: 도형 객체 배열 상태, commit/undo/redo(최대 100단계), 그리는 중·편집 중 검증,
 * 빈 종류 경고, 임시본(localStorage 24시간) 저장·복원.
 * 화면(Konva) 코드는 roiEditor.js 가 이 모듈을 호출한다. 기하 알고리즘은 roiGeometry.js 를 그대로 쓴다.
 */
(function (root, factory) {
    if (typeof module === 'object' && module.exports) module.exports = factory(require('./roiGeometry.js'));
    else root.RoiEditorCore = factory(root.RoiGeometry);
}(typeof self !== 'undefined' ? self : this, function (G) {
    'use strict';

    var KINDS = G.KINDS, CAMERAS = G.CAMERAS, W = G.WIDTH, H = G.HEIGHT;
    var UNDO_LIMIT = 100;
    var DRAFT_TTL_MS = 24 * 60 * 60 * 1000;
    var DRAFT_PREFIX = 'roiDraft:';
    // 빈 종류 경고를 장비 전체(두 카메라 합계)로 판단할지 카메라별로 판단할지. 계획서 11.1-6 이 확정되면 바꾼다.
    var EMPTY_KIND_SCOPE = 'device'; // 'device' | 'camera'

    var KIND_LABEL = { parking: '주차칸', driveway: '통로', ignore: '식별 제외 영역' };
    var CAMERA_LABEL = { Cam1: 'Cam1 (불릿)', Cam2: 'Cam2 (PTZ)' };
    var PROBLEM_TEXT = {
        POINTS_MIN: '점이 3개 이상이어야 합니다',
        POINT_FORMAT: '점 좌표 형식이 올바르지 않습니다',
        POINT_NOT_INTEGER: '좌표는 정수여야 합니다',
        OUT_OF_RANGE: '화면 밖으로 나갈 수 없습니다',
        DUPLICATE_POINT: '같은 위치에 점이 두 번 있습니다',
        SELF_INTERSECTION: '선이 서로 교차합니다',
        ZERO_AREA: '면적이 없는 도형입니다',
        OVERLAP: '다른 영역과 겹칩니다',
        CAMERA_MISSING: '카메라 정보가 없습니다',
        KIND_MISSING: '영역 종류 정보가 없습니다',
        SHAPE_FORMAT: '도형 형식이 올바르지 않습니다',
        ROIS_FORMAT: 'ROI 형식이 올바르지 않습니다',
        FORMAT: 'ROI 형식이 올바르지 않습니다',
        INVALID: 'ROI 검증에 실패했습니다'
    };

    var uidCounter = 0;
    function nextKey() { uidCounter += 1; return 'k' + uidCounter; }

    function emptyRois() {
        var r = {};
        CAMERAS.forEach(function (c) { r[c] = {}; KINDS.forEach(function (k) { r[c][k] = []; }); });
        return r;
    }

    // 서버/임시본에서 받은 ROI 를 편집용으로 만든다: 구조 보정 + 내부 키(_k) 부여. 입력은 바꾸지 않는다.
    function normalizeLoaded(rois) {
        var out = emptyRois();
        if (!rois || typeof rois !== 'object') return out;
        CAMERAS.forEach(function (cam) {
            KINDS.forEach(function (kind) {
                var list = rois[cam] && Array.isArray(rois[cam][kind]) ? rois[cam][kind] : [];
                list.forEach(function (s) {
                    if (!s || typeof s !== 'object') return;
                    out[cam][kind].push({
                        _k: nextKey(),
                        id: typeof s.id === 'string' ? s.id : '',
                        name: typeof s.name === 'string' ? s.name : '',
                        points: Array.isArray(s.points) ? s.points.map(function (p) { return Array.isArray(p) ? p.slice() : p; }) : []
                    });
                });
            });
        });
        return out;
    }

    // 저장/임시본용: 내부 키를 빼고 {id,name,points} 만 남긴다.
    function stripForSave(rois) {
        var out = {};
        CAMERAS.forEach(function (cam) {
            out[cam] = {};
            KINDS.forEach(function (kind) {
                out[cam][kind] = ((rois[cam] && rois[cam][kind]) || []).map(function (s) {
                    return { id: s.id || '', name: s.name || '', points: s.points.map(function (p) { return [p[0], p[1]]; }) };
                });
            });
        });
        return out;
    }

    function serialize(rois) { return JSON.stringify(stripForSave(rois)); }

    function defaultName(rois, cam, kind) {
        var n = ((rois[cam] && rois[cam][kind]) || []).length + 1;
        return KIND_LABEL[kind] + ' ' + n;
    }

    function findShape(rois, cam, key) {
        var list;
        for (var i = 0; i < KINDS.length; i++) {
            list = rois[cam][KINDS[i]];
            for (var j = 0; j < list.length; j++) {
                if (list[j]._k === key) return { kind: KINDS[i], index: j, shape: list[j] };
            }
        }
        return null;
    }

    // ---------------------------------------------------------------- undo / redo
    // 스냅샷은 serialize() 문자열. 선택 상태는 담지 않는다.
    function History(limit) {
        this.limit = limit || UNDO_LIMIT;
        this.stack = [];
        this.pos = -1;
    }
    History.prototype.reset = function (rois) { this.stack = [serialize(rois)]; this.pos = 0; };
    History.prototype.commit = function (rois) {
        var snap = serialize(rois);
        if (this.pos >= 0 && this.stack[this.pos] === snap) return false; // 변화 없음
        this.stack = this.stack.slice(0, this.pos + 1);
        this.stack.push(snap);
        if (this.stack.length > this.limit + 1) this.stack.shift(); // 처음 상태 + undo 100단계
        this.pos = this.stack.length - 1;
        return true;
    };
    History.prototype.canUndo = function () { return this.pos > 0; };
    History.prototype.canRedo = function () { return this.pos >= 0 && this.pos < this.stack.length - 1; };
    History.prototype.undo = function () { return this.canUndo() ? normalizeLoaded(JSON.parse(this.stack[--this.pos])) : null; };
    History.prototype.redo = function () { return this.canRedo() ? normalizeLoaded(JSON.parse(this.stack[++this.pos])) : null; };

    // ---------------------------------------------------------------- 검증
    function problemText(code) { return PROBLEM_TEXT[code] || ('검증 오류(' + code + ')'); }

    // 화면에 보여줄 문제 목록(서버 형식과 같은 {camera,kind,index,code}) — 전체 문서 검증
    function documentProblems(rois) { return G.validateRois(stripForSave(rois)); }

    function problemKeyMap(rois, problems) {
        var map = {};
        problems.forEach(function (p) {
            if (p.kind === undefined || p.index === undefined) return;
            var list = rois[p.camera] && rois[p.camera][p.kind];
            if (!list || !list[p.index]) return;
            map[p.camera + '|' + list[p.index]._k] = true;
            if (p.other && list) {
                var oList = rois[p.camera][p.other.kind];
                if (oList && oList[p.other.index]) map[p.camera + '|' + oList[p.other.index]._k] = true;
            }
        });
        return map;
    }

    function shapeLabel(rois, p) {
        var s = rois[p.camera] && rois[p.camera][p.kind] && rois[p.camera][p.kind][p.index];
        var name = s && s.name ? s.name : (KIND_LABEL[p.kind] || '') + ' #' + (p.index + 1);
        return (CAMERA_LABEL[p.camera] ? p.camera : p.camera) + ' · ' + name;
    }

    function otherPolygons(rois, cam, excludeKey) {
        var out = [];
        KINDS.forEach(function (kind) {
            rois[cam][kind].forEach(function (s) {
                if (s._k !== excludeKey && G.polygonProblem(s.points) === null) out.push(s.points);
            });
        });
        return out;
    }

    // 도형 하나가 (자기 문제 + 다른 도형과의 겹침) 없이 놓일 수 있는지. 문제 코드 또는 null.
    function checkShape(rois, cam, excludeKey, points) {
        var why = G.polygonProblem(points);
        if (why) return why;
        var others = otherPolygons(rois, cam, excludeKey);
        for (var i = 0; i < others.length; i++) {
            if (G.polygonsOverlap(points, others[i])) return 'OVERLAP';
        }
        return null;
    }

    // 그리는 중 새 점을 추가해도 되는지. 아직 닫히지 않은 선이므로 닫는 변은 검사하지 않는다.
    // 문제 코드 또는 null. (닫을 때 checkShape 로 전체를 다시 검사한다)
    function checkDrawPoint(rois, cam, pts, pt) {
        if (pt[0] < 0 || pt[0] > W - 1 || pt[1] < 0 || pt[1] > H - 1) return 'OUT_OF_RANGE';
        if (pts.length) {
            var last = pts[pts.length - 1];
            if (last[0] === pt[0] && last[1] === pt[1]) return 'DUPLICATE_POINT';
        }
        // 새 선분이 이미 그린 선분과 (이웃 선분 제외) 교차/접촉하면 안 된다
        if (pts.length >= 2) {
            var a = pts[pts.length - 1];
            for (var i = 0; i < pts.length - 2; i++) {
                if (G.segmentsIntersect(a, pt, pts[i], pts[i + 1])) return 'SELF_INTERSECTION';
            }
            // 바로 앞 선분과 정반대로 되돌아 겹치는 경우(일직선 되돌림)
            var b = pts[pts.length - 2];
            var cr = (a[0] - b[0]) * (pt[1] - b[1]) - (a[1] - b[1]) * (pt[0] - b[0]);
            var dot = (b[0] - a[0]) * (pt[0] - a[0]) + (b[1] - a[1]) * (pt[1] - a[1]);
            if (cr === 0 && dot > 0) return 'SELF_INTERSECTION';
        }
        // 다른 영역 안쪽으로 들어가거나(허용 두께 이상) 다른 영역의 변을 가로지르면 겹치게 된다
        var others = otherPolygons(rois, cam, null);
        for (var k = 0; k < others.length; k++) {
            var poly = others[k];
            if (G.strictlyInside(pt, poly) && G.distToBoundary(pt, poly) > G.OVERLAP_TOLERANCE_PX / 2) return 'OVERLAP';
            if (pts.length) {
                var from = pts[pts.length - 1];
                for (var e = 0; e < poly.length; e++) {
                    if (G.properCrossing(from, pt, poly[e], poly[(e + 1) % poly.length])) return 'OVERLAP';
                }
            }
        }
        return null;
    }

    // ---------------------------------------------------------------- 편집 동작 (순수 함수: 새 점 배열을 돌려준다)
    function clampPoint(x, y) {
        return [Math.max(0, Math.min(W - 1, Math.round(x))), Math.max(0, Math.min(H - 1, Math.round(y)))];
    }

    // 점 p 와 가장 가까운 변(maxDist 이하). {index(변 시작 점 번호), point(정수로 반올림한 변 위 점)} 또는 null.
    function nearestEdge(points, p, maxDist) {
        var best = null, n = points.length;
        for (var i = 0; i < n; i++) {
            var a = points[i], b = points[(i + 1) % n];
            var d = G.pointSegmentDistance(p[0], p[1], a, b);
            if (d <= maxDist && (!best || d < best.d)) best = { index: i, d: d };
        }
        if (!best) return null;
        var a2 = points[best.index], b2 = points[(best.index + 1) % n];
        var dx = b2[0] - a2[0], dy = b2[1] - a2[1], len2 = dx * dx + dy * dy;
        var t = len2 ? Math.max(0, Math.min(1, ((p[0] - a2[0]) * dx + (p[1] - a2[1]) * dy) / len2)) : 0;
        return { index: best.index, point: clampPoint(a2[0] + t * dx, a2[1] + t * dy) };
    }

    function insertPoint(points, edgeIndex, pt) {
        var out = points.map(function (p) { return [p[0], p[1]]; });
        out.splice(edgeIndex + 1, 0, [pt[0], pt[1]]);
        return out;
    }

    function removePoint(points, index) {
        if (points.length <= 3) return null; // 3점 미만이 되는 삭제는 허용하지 않는다
        var out = points.map(function (p) { return [p[0], p[1]]; });
        out.splice(index, 1);
        return out;
    }

    // ---------------------------------------------------------------- 빈 종류 경고
    // 계획서 §7 경고 문구. ignore 는 경고하지 않는다. 경고할 것이 없으면 null.
    function emptyKindWarning(rois, scope) {
        scope = scope || EMPTY_KIND_SCOPE;
        function count(kind) {
            if (scope === 'camera') return null;
            return CAMERAS.reduce(function (n, c) { return n + rois[c][kind].length; }, 0);
        }
        var noParking, noDriveway;
        if (scope === 'camera') {
            noParking = CAMERAS.some(function (c) { return rois[c].parking.length === 0; });
            noDriveway = CAMERAS.some(function (c) { return rois[c].driveway.length === 0; });
        } else {
            noParking = count('parking') === 0;
            noDriveway = count('driveway') === 0;
        }
        var items = [];
        if (noParking) items.push('미등록주차');
        if (noDriveway) items.push('이중주차');
        if (!items.length) return null;
        return items.join(' 및 ') + ' 식별이 되지 않습니다. 그래도 이렇게 설정하시겠습니까?';
    }

    // ---------------------------------------------------------------- 임시본(draft)
    function draftKey(uid, deviceId) { return DRAFT_PREFIX + uid + ':' + deviceId; }

    function saveDraft(storage, key, baseHash, rois, now) {
        try {
            storage.setItem(key, JSON.stringify({ savedAt: now, baseHash: baseHash || '', rois: stripForSave(rois) }));
            return true;
        } catch (e) { return false; }
    }

    // 24시간 지난 것·깨진 것은 지우고 null. 정상이면 {savedAt, baseHash, rois}.
    function loadDraft(storage, key, now) {
        var raw;
        try { raw = storage.getItem(key); } catch (e) { return null; }
        if (!raw) return null;
        try {
            var d = JSON.parse(raw);
            if (!d || typeof d.savedAt !== 'number' || now - d.savedAt > DRAFT_TTL_MS || d.savedAt > now + 60000 ||
                typeof d.baseHash !== 'string' || !d.rois || typeof d.rois !== 'object') throw new Error('stale');
            return d;
        } catch (e) {
            try { storage.removeItem(key); } catch (e2) { /* 무시 */ }
            return null;
        }
    }

    function clearDraft(storage, key) { try { storage.removeItem(key); } catch (e) { /* 무시 */ } }

    function clearAllDrafts(storage) {
        try {
            var remove = [];
            for (var i = 0; i < storage.length; i++) {
                var k = storage.key(i);
                if (k && k.indexOf(DRAFT_PREFIX) === 0) remove.push(k);
            }
            remove.forEach(function (k) { storage.removeItem(k); });
        } catch (e) { /* 무시 */ }
    }

    return {
        KINDS: KINDS, CAMERAS: CAMERAS, WIDTH: W, HEIGHT: H, UNDO_LIMIT: UNDO_LIMIT, DRAFT_TTL_MS: DRAFT_TTL_MS,
        KIND_LABEL: KIND_LABEL, CAMERA_LABEL: CAMERA_LABEL, PROBLEM_TEXT: PROBLEM_TEXT, EMPTY_KIND_SCOPE: EMPTY_KIND_SCOPE,
        emptyRois: emptyRois, normalizeLoaded: normalizeLoaded, stripForSave: stripForSave, serialize: serialize,
        defaultName: defaultName, findShape: findShape, nextKey: nextKey,
        History: History,
        problemText: problemText, documentProblems: documentProblems, problemKeyMap: problemKeyMap, shapeLabel: shapeLabel,
        checkShape: checkShape, checkDrawPoint: checkDrawPoint,
        clampPoint: clampPoint, nearestEdge: nearestEdge, insertPoint: insertPoint, removePoint: removePoint,
        emptyKindWarning: emptyKindWarning,
        draftKey: draftKey, saveDraft: saveDraft, loadDraft: loadDraft, clearDraft: clearDraft, clearAllDrafts: clearAllDrafts
    };
}));
