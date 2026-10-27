/*
 * ROI 기하 검증 (브라우저 + Node 공용).
 *
 * 같은 알고리즘이 Java(RoiValidator)·Go(module_d roi/validate.go)에도 있다.
 * 알고리즘을 바꾸면 세 곳을 함께 바꿀 것.
 *
 * 좌표: 1920x1080 원본 기준 정수 픽셀, 원점은 왼쪽 위.
 */
(function (root, factory) {
    if (typeof module === 'object' && module.exports) module.exports = factory();
    else root.RoiGeometry = factory();
}(typeof self !== 'undefined' ? self : this, function () {
    'use strict';

    var WIDTH = 1920, HEIGHT = 1080;
    // 겹침 허용 두께(px). 두 도형이 겹친 영역의 두께가 이 값 이하이면 허용한다(손으로 그린 인접 도형의 1~2px 오차).
    var OVERLAP_TOLERANCE_PX = 2;
    var DEPTH_THRESHOLD = OVERLAP_TOLERANCE_PX / 2;
    var EPS = 1e-9;
    var KINDS = ['parking', 'driveway', 'ignore'];
    var CAMERAS = ['Cam1', 'Cam2'];

    function cross(ax, ay, bx, by, cx, cy) { // (b-a) x (c-a)
        return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    }
    function sign(v) { return v > 0 ? 1 : (v < 0 ? -1 : 0); }

    function onSegment(ax, ay, bx, by, px, py) { // 세 점이 일직선일 때 p 가 선분 ab 위인지
        return Math.min(ax, bx) <= px && px <= Math.max(ax, bx) && Math.min(ay, by) <= py && py <= Math.max(ay, by);
    }

    // 선분 교차(끝점 접촉·겹침 포함)
    function segmentsIntersect(a, b, c, d) {
        var d1 = sign(cross(a[0], a[1], b[0], b[1], c[0], c[1]));
        var d2 = sign(cross(a[0], a[1], b[0], b[1], d[0], d[1]));
        var d3 = sign(cross(c[0], c[1], d[0], d[1], a[0], a[1]));
        var d4 = sign(cross(c[0], c[1], d[0], d[1], b[0], b[1]));
        if (d1 * d2 < 0 && d3 * d4 < 0) return true;
        if (d1 === 0 && onSegment(a[0], a[1], b[0], b[1], c[0], c[1])) return true;
        if (d2 === 0 && onSegment(a[0], a[1], b[0], b[1], d[0], d[1])) return true;
        if (d3 === 0 && onSegment(c[0], c[1], d[0], d[1], a[0], a[1])) return true;
        if (d4 === 0 && onSegment(c[0], c[1], d[0], d[1], b[0], b[1])) return true;
        return false;
    }

    // 두 선분이 서로의 안쪽에서 한 점으로 엇갈리는 경우(끝점 접촉·평행 제외)의 교점. 없으면 null
    function properCrossing(a, b, c, d) {
        var d1 = sign(cross(a[0], a[1], b[0], b[1], c[0], c[1]));
        var d2 = sign(cross(a[0], a[1], b[0], b[1], d[0], d[1]));
        var d3 = sign(cross(c[0], c[1], d[0], d[1], a[0], a[1]));
        var d4 = sign(cross(c[0], c[1], d[0], d[1], b[0], b[1]));
        if (d1 * d2 < 0 && d3 * d4 < 0) {
            var rx = b[0] - a[0], ry = b[1] - a[1], sx = d[0] - c[0], sy = d[1] - c[1];
            var denom = rx * sy - ry * sx;
            var t = ((c[0] - a[0]) * sy - (c[1] - a[1]) * sx) / denom;
            return [a[0] + t * rx, a[1] + t * ry];
        }
        return null;
    }

    function pointSegmentDistance(px, py, a, b) {
        var dx = b[0] - a[0], dy = b[1] - a[1];
        var len2 = dx * dx + dy * dy;
        if (len2 === 0) return Math.hypot(px - a[0], py - a[1]);
        var t = ((px - a[0]) * dx + (py - a[1]) * dy) / len2;
        t = Math.max(0, Math.min(1, t));
        return Math.hypot(px - (a[0] + t * dx), py - (a[1] + t * dy));
    }

    function distToBoundary(p, poly) {
        var best = Infinity, n = poly.length;
        for (var i = 0; i < n; i++) {
            var d = pointSegmentDistance(p[0], p[1], poly[i], poly[(i + 1) % n]);
            if (d < best) best = d;
        }
        return best;
    }

    function rayInside(p, poly) { // 짝홀 규칙(경계 판정은 호출측에서 distToBoundary 로)
        var inside = false, n = poly.length;
        for (var i = 0, j = n - 1; i < n; j = i++) {
            var yi = poly[i][1], yj = poly[j][1];
            if ((yi > p[1]) !== (yj > p[1])) {
                var x = (poly[j][0] - poly[i][0]) * (p[1] - yi) / (yj - yi) + poly[i][0];
                if (p[0] < x) inside = !inside;
            }
        }
        return inside;
    }

    function strictlyInside(p, poly) {
        return distToBoundary(p, poly) > EPS && rayInside(p, poly);
    }
    function insideOrOn(p, poly) {
        return distToBoundary(p, poly) <= EPS || rayInside(p, poly);
    }

    function areaCentroid(poly) {
        var a = 0, cx = 0, cy = 0, n = poly.length;
        for (var i = 0; i < n; i++) {
            var p = poly[i], q = poly[(i + 1) % n];
            var f = p[0] * q[1] - q[0] * p[1];
            a += f; cx += (p[0] + q[0]) * f; cy += (p[1] + q[1]) * f;
        }
        if (a === 0) return [poly[0][0], poly[0][1]];
        return [cx / (3 * a), cy / (3 * a)];
    }

    // 좌표·형태 검증. 문제가 없으면 null, 있으면 사유 문자열
    function polygonProblem(points) {
        if (!Array.isArray(points) || points.length < 3) return 'POINTS_MIN';
        var n = points.length, i, j;
        for (i = 0; i < n; i++) {
            var p = points[i];
            if (!Array.isArray(p) || p.length !== 2) return 'POINT_FORMAT';
            if (!isInt(p[0]) || !isInt(p[1])) return 'POINT_NOT_INTEGER';
            if (p[0] < 0 || p[0] > WIDTH - 1 || p[1] < 0 || p[1] > HEIGHT - 1) return 'OUT_OF_RANGE';
        }
        for (i = 0; i < n; i++) {
            var q = points[(i + 1) % n];
            if (points[i][0] === q[0] && points[i][1] === q[1]) return 'DUPLICATE_POINT';
        }
        for (i = 0; i < n; i++) {
            for (j = i + 1; j < n; j++) {
                var adjacent = (j === i + 1) || (i === 0 && j === n - 1);
                var a1 = points[i], a2 = points[(i + 1) % n], b1 = points[j], b2 = points[(j + 1) % n];
                if (adjacent) {
                    // 인접한 두 변은 공유 끝점 외에 겹치면 안 된다(되접힘 방지). 공유점 = 두 번째 변의 시작/첫 변의 끝
                    var shared, o1, o2;
                    if (j === i + 1) { shared = a2; o1 = a1; o2 = b2; } else { shared = a1; o1 = a2; o2 = b1; }
                    var cr = cross(shared[0], shared[1], o1[0], o1[1], o2[0], o2[1]);
                    var dot = (o1[0] - shared[0]) * (o2[0] - shared[0]) + (o1[1] - shared[1]) * (o2[1] - shared[1]);
                    if (cr === 0 && dot > 0) return 'SELF_INTERSECTION';
                } else if (segmentsIntersect(a1, a2, b1, b2)) {
                    return 'SELF_INTERSECTION';
                }
            }
        }
        // 자기교차가 없더라도 면적이 0 인 퇴화 도형(방어)
        var area2 = 0;
        for (i = 0; i < n; i++) {
            var pa = points[i], pb = points[(i + 1) % n];
            area2 += pa[0] * pb[1] - pb[0] * pa[1];
        }
        if (area2 === 0) return 'ZERO_AREA';
        return null;
    }

    function isInt(v) { return typeof v === 'number' && isFinite(v) && Math.floor(v) === v; }

    // 두 다각형이 허용 두께를 넘어 겹치는지
    function polygonsOverlap(A, B) {
        var Q = [], i, j, nA = A.length, nB = B.length;
        for (i = 0; i < nA; i++) if (insideOrOn(A[i], B)) Q.push([A[i][0], A[i][1]]);
        for (i = 0; i < nB; i++) if (insideOrOn(B[i], A)) Q.push([B[i][0], B[i][1]]);
        for (i = 0; i < nA; i++) {
            for (j = 0; j < nB; j++) {
                var x = properCrossing(A[i], A[(i + 1) % nA], B[j], B[(j + 1) % nB]);
                if (x) Q.push(x);
            }
        }
        var cand = [areaCentroid(A), areaCentroid(B)];
        if (Q.length) {
            var mx = 0, my = 0;
            for (i = 0; i < Q.length; i++) { mx += Q[i][0]; my += Q[i][1]; }
            cand.push([mx / Q.length, my / Q.length]);
            for (i = 0; i < Q.length; i++) {
                for (j = i + 1; j < Q.length; j++) {
                    cand.push([(Q[i][0] + Q[j][0]) / 2, (Q[i][1] + Q[j][1]) / 2]);
                    if (Q.length <= 12) {
                        for (var k = j + 1; k < Q.length; k++) {
                            cand.push([(Q[i][0] + Q[j][0] + Q[k][0]) / 3, (Q[i][1] + Q[j][1] + Q[k][1]) / 3]);
                        }
                    }
                }
            }
        }
        for (i = 0; i < cand.length; i++) {
            var p = cand[i];
            if (strictlyInside(p, A) && strictlyInside(p, B)) {
                if (Math.min(distToBoundary(p, A), distToBoundary(p, B)) > DEPTH_THRESHOLD) return true;
            }
        }
        return false;
    }

    // 한 카메라의 모든 도형(종류 무관) 쌍 겹침 검사. 겹치는 도형 쌍 [{a,b}] 반환 (a,b 는 {kind,index})
    function findOverlaps(camera) {
        var items = [];
        KINDS.forEach(function (kind) {
            (camera[kind] || []).forEach(function (shape, index) {
                items.push({ kind: kind, index: index, points: shape.points });
            });
        });
        var result = [];
        for (var i = 0; i < items.length; i++) {
            for (var j = i + 1; j < items.length; j++) {
                if (polygonProblem(items[i].points) === null && polygonProblem(items[j].points) === null &&
                    polygonsOverlap(items[i].points, items[j].points)) {
                    result.push({ a: { kind: items[i].kind, index: items[i].index }, b: { kind: items[j].kind, index: items[j].index } });
                }
            }
        }
        return result;
    }

    // 전체 ROI 구조 검증. 문제 목록 [{camera,kind,index,code}] (비어 있으면 통과)
    function validateRois(rois) {
        var problems = [];
        if (!rois || typeof rois !== 'object') return [{ code: 'ROIS_FORMAT' }];
        CAMERAS.forEach(function (cam) {
            var c = rois[cam];
            if (!c || typeof c !== 'object') { problems.push({ camera: cam, code: 'CAMERA_MISSING' }); return; }
            KINDS.forEach(function (kind) {
                if (!Array.isArray(c[kind])) { problems.push({ camera: cam, kind: kind, code: 'KIND_MISSING' }); return; }
                c[kind].forEach(function (shape, index) {
                    var why = (shape && typeof shape === 'object') ? polygonProblem(shape.points) : 'SHAPE_FORMAT';
                    if (why) problems.push({ camera: cam, kind: kind, index: index, code: why });
                });
            });
            findOverlaps(c).forEach(function (pair) {
                problems.push({ camera: cam, kind: pair.a.kind, index: pair.a.index, code: 'OVERLAP', other: pair.b });
            });
        });
        return problems;
    }

    return {
        WIDTH: WIDTH, HEIGHT: HEIGHT, KINDS: KINDS, CAMERAS: CAMERAS,
        OVERLAP_TOLERANCE_PX: OVERLAP_TOLERANCE_PX,
        polygonProblem: polygonProblem, polygonsOverlap: polygonsOverlap,
        findOverlaps: findOverlaps, validateRois: validateRois,
        segmentsIntersect: segmentsIntersect,
        // 편집기(그리는 중 점 검사·점 삽입)용 보조 함수 — 검증 알고리즘 자체는 바뀌지 않는다
        properCrossing: properCrossing, strictlyInside: strictlyInside, distToBoundary: distToBoundary,
        pointSegmentDistance: pointSegmentDistance
    };
}));
