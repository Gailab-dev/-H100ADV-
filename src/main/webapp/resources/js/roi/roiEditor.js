/*
 * ROI 편집 화면 (Konva) — 34번 작업계획서 §5.1.
 * 상태·검증·undo·임시본 로직은 roiEditorCore.js, 기하 검증은 roiGeometry.js(Java/Go 와 같은 알고리즘)에 있고,
 * 이 파일은 DOM·Konva·서버 통신만 맡는다. 좌표는 항상 1920x1080 원본 기준 정수 픽셀(원점 왼쪽 위).
 * 서버 호출은 모두 POST(JSON) + 세션 CSRF 헤더(X-H100-CSRF)이며 15초 안에 응답이 없으면 대기 팝업이 "결과 불명"으로 처리한다.
 */
(function () {
    'use strict';

    var C = window.RoiEditorCore;
    var page = document.getElementById('roiPage');
    if (!C || !page || typeof Konva === 'undefined') {
        if (page) page.insertAdjacentHTML('afterbegin', '<p class="roi-fatal">ROI 편집기 구성요소를 불러오지 못했습니다. 새로고침 후에도 같으면 관리자에게 알려 주세요.</p>');
        return;
    }

    var CFG = {
        ctx: page.getAttribute('data-ctx') || '',
        deviceId: parseInt(page.getAttribute('data-device-id'), 10),
        name: page.getAttribute('data-device-name') || '',
        serial: page.getAttribute('data-serial') || '',
        csrf: page.getAttribute('data-csrf') || '',
        uid: page.getAttribute('data-uid') || ''
    };
    var W = C.WIDTH, H = C.HEIGHT;
    var REQUEST_TIMEOUT_MS = 15000;      // 대기 팝업 제한(계획서 확정사항 18)
    var CLOSE_RADIUS_PX = 14;            // 첫 점 근처 클릭으로 닫기(12~15px)
    var EDGE_PICK_PX = 8;                // 변 위 클릭으로 점 삽입
    var DRAFT_DEBOUNCE_MS = 500;
    var COLORS = {
        parking: { stroke: '#2a7de1', fill: 'rgba(42,125,225,0.25)' },
        driveway: { stroke: '#1fa971', fill: 'rgba(31,169,113,0.25)' },
        ignore: { stroke: '#8b8b99', fill: 'rgba(139,139,153,0.30)' },
        bad: { stroke: '#e5322d', fill: 'rgba(229,50,45,0.38)' }
    };

    var S = {
        camera: 'Cam1',
        rois: C.emptyRois(),
        baseHash: '',
        exists: false,
        formatError: false,
        initial: C.serialize(C.emptyRois()),
        history: new C.History(),
        selected: null,          // 선택한 도형의 _k (현재 카메라 안)
        mode: 'idle',            // 'idle' | 'draw'
        draw: null,              // {kind, points:[[x,y]...]}
        problems: [],
        badKeys: {},
        busy: false,
        dirty: false,
        images: { Cam1: null, Cam2: null },
        snapshotState: 'none',   // none | loading | ok | failed
        draftTimer: null,
        lineNodes: {},
        dragOrig: null,
        lastDragToast: 0,
        pendingRhId: null
    };
    S.history.reset(S.rois);

    // ------------------------------------------------------------------ 작은 도구
    function $(sel, root) { return (root || document).querySelector(sel); }
    function $all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
    function h(tag, cls, text) {
        var e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined && text !== null) e.textContent = text;
        return e;
    }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    function dist(a, b) { return Math.hypot(a[0] - b[0], a[1] - b[1]); }
    function pad2(n) { return n < 10 ? '0' + n : '' + n; }
    function clockText(ts) { var d = new Date(ts); return pad2(d.getHours()) + ':' + pad2(d.getMinutes()) + ':' + pad2(d.getSeconds()); }

    var toastTimer = null;
    function toast(msg, level) {
        var t = $('#roiToast');
        t.textContent = msg;
        t.className = 'roi-toast show ' + (level || 'info');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { t.className = 'roi-toast'; }, level === 'error' ? 8000 : 4500);
    }

    function banner(msg, level) {
        var b = $('#roiBanner');
        if (!msg) { b.hidden = true; b.textContent = ''; return; }
        b.hidden = false;
        b.className = 'roi-banner ' + (level || 'warn');
        b.textContent = msg;
    }

    // 범용 확인 모달. buttons: [{id,label,primary}] → 누른 버튼 id 로 resolve (Esc/바깥 클릭 = 'cancel')
    function modal(title, lines, buttons) {
        return new Promise(function (resolve) {
            var root = $('#roiModal');
            $('#roiModalTitle').textContent = title;
            var body = $('#roiModalBody');
            body.textContent = '';
            (Array.isArray(lines) ? lines : [lines]).forEach(function (l) { body.appendChild(h('p', null, l)); });
            var foot = $('#roiModalFoot');
            foot.textContent = '';
            function done(id) { root.hidden = true; document.removeEventListener('keydown', onKey, true); resolve(id); }
            function onKey(e) { if (e.key === 'Escape') { e.stopPropagation(); done('cancel'); } }
            buttons.forEach(function (b) {
                var btn = h('button', 'roi-btn' + (b.primary ? ' primary' : ''), b.label);
                btn.type = 'button';
                btn.addEventListener('click', function () { done(b.id); });
                foot.appendChild(btn);
            });
            root.hidden = false;
            document.addEventListener('keydown', onKey, true);
            var first = foot.querySelector('.primary') || foot.querySelector('button');
            if (first) first.focus();
        });
    }

    // 대기 팝업: 남은 시간을 보여 주고 사용자가 다른 조작을 하지 못하게 막는다.
    var waitTimer = null;
    function showWait(text, seconds) {
        var root = $('#roiWait');
        $('#roiWaitText').textContent = text;
        var left = seconds || 15;
        $('#roiWaitLeft').textContent = left + '초';
        root.hidden = false;
        clearInterval(waitTimer);
        waitTimer = setInterval(function () {
            left = Math.max(0, left - 1);
            $('#roiWaitLeft').textContent = left + '초';
        }, 1000);
    }
    function hideWait() { clearInterval(waitTimer); $('#roiWait').hidden = true; }

    // ------------------------------------------------------------------ 서버 통신
    function sessionExpired() {
        location.href = CFG.ctx + '/user/login.do?errorMsg=' + encodeURIComponent('장기간 미사용으로 로그아웃되었습니다.');
    }

    // 항상 {status, data} 로 resolve. 시간 초과/네트워크 오류는 {status:0, aborted:true|false}.
    function api(name, body) {
        var ctrl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
        var timer = setTimeout(function () { if (ctrl) ctrl.abort(); }, REQUEST_TIMEOUT_MS);
        return fetch(CFG.ctx + '/deviceList/' + name + '.do', {
            method: 'POST',
            credentials: 'same-origin',
            cache: 'no-store',
            headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'X-H100-CSRF': CFG.csrf },
            body: JSON.stringify(body),
            signal: ctrl ? ctrl.signal : undefined
        }).then(function (r) {
            clearTimeout(timer);
            return r.json().then(function (d) { return { status: r.status, data: d || {} }; }, function () { return { status: r.status, data: {} }; });
        }).then(function (res) {
            if (res.status === 401 && res.data && res.data.error === 'SESSION_TIMEOUT') { sessionExpired(); }
            return res;
        }, function (err) {
            clearTimeout(timer);
            return { status: 0, aborted: !!(err && err.name === 'AbortError'), data: {} };
        });
    }

    function problemLines(problems) {
        return (problems || []).slice(0, 8).map(function (p) {
            var label = (p.kind !== undefined && p.index !== undefined && S.rois[p.camera]) ? C.shapeLabel(S.rois, p) : (p.camera || '');
            return (label ? label + ': ' : '') + C.problemText(p.code);
        });
    }

    function errorText(res) {
        if (res.status === 0) return res.aborted ? '15초 안에 응답이 없었습니다.' : '서버와 통신할 수 없습니다.';
        var d = res.data || {};
        return d.msg || ('요청 처리 중 오류가 발생했습니다 (' + res.status + ')');
    }

    // ------------------------------------------------------------------ 상태 갱신
    function selectedShape() {
        if (!S.selected) return null;
        return C.findShape(S.rois, S.camera, S.selected);
    }

    function recompute() {
        S.problems = C.documentProblems(S.rois);
        S.badKeys = C.problemKeyMap(S.rois, S.problems);
        S.dirty = C.serialize(S.rois) !== S.initial;
    }

    function onChanged() {
        recompute();
        scheduleDraft();
        redraw();
    }

    function commit() {
        if (S.history.commit(S.rois)) onChanged();
        else redraw();
    }

    function draftKey() { return C.draftKey(CFG.uid, CFG.deviceId); }

    function scheduleDraft() {
        clearTimeout(S.draftTimer);
        S.draftTimer = setTimeout(function () {
            var state = $('#roiDraftState');
            if (S.dirty) {
                if (C.saveDraft(window.localStorage, draftKey(), S.baseHash, S.rois, Date.now())) {
                    state.textContent = '임시저장됨 ' + clockText(Date.now());
                } else {
                    state.textContent = '임시저장 불가(브라우저 저장소 사용 불가)';
                }
            } else {
                C.clearDraft(window.localStorage, draftKey());
                state.textContent = '';
            }
        }, DRAFT_DEBOUNCE_MS);
    }

    function applyRois(rois, baseHash) {
        S.rois = C.normalizeLoaded(rois);
        S.baseHash = baseHash || '';
        S.initial = C.serialize(S.rois);
        S.history.reset(S.rois);
        S.selected = null;
        endDraw();
        recompute();
        redraw();
    }

    // ------------------------------------------------------------------ Konva 무대
    var stage, imageLayer, shapeLayer, drawLayer, scale = 0.5;

    function initStage() {
        stage = new Konva.Stage({ container: 'roiStage', width: 960, height: 540 });
        imageLayer = new Konva.Layer({ listening: false });
        shapeLayer = new Konva.Layer();
        drawLayer = new Konva.Layer({ listening: false });
        stage.add(imageLayer, shapeLayer, drawLayer);
        stage.on('click tap', onStageClick);
        stage.on('mousemove', function () { if (S.mode === 'draw') drawPreview(); });
        stage.on('contextmenu', function (e) { e.evt.preventDefault(); });
        window.addEventListener('resize', fit);
        fit();
    }

    function fit() {
        var wrap = $('.roi-stage-wrap');
        var avail = Math.max(320, wrap.clientWidth - 2);
        scale = clamp(avail / W, 0.2, 1.6);
        stage.size({ width: Math.round(W * scale), height: Math.round(H * scale) });
        stage.scale({ x: scale, y: scale });
        drawImage();
        redraw();
    }

    function pointerLogical() {
        var p = stage.getPointerPosition();
        if (!p) return null;
        return [p.x / scale, p.y / scale];
    }

    function drawImage() {
        imageLayer.destroyChildren();
        var img = S.images[S.camera];
        if (img) {
            imageLayer.add(new Konva.Image({ image: img, x: 0, y: 0, width: W, height: H }));
        } else {
            imageLayer.add(new Konva.Rect({ x: 0, y: 0, width: W, height: H, fill: '#2b2b33' }));
            var msg = S.snapshotState === 'loading' ? '스냅샷을 가져오는 중…' : (S.snapshotState === 'failed' ? '스냅샷을 가져오지 못했습니다 (아래 [스냅샷 다시 받기])' : '스냅샷 없음');
            imageLayer.add(new Konva.Text({ x: 0, y: H / 2 - 20, width: W, align: 'center', text: msg, fontSize: 40, fill: '#bbbbc4', listening: false }));
        }
        imageLayer.batchDraw();
    }

    function drawable(shape) {
        return shape.points.length >= 2 && shape.points.every(function (p) {
            return Array.isArray(p) && p.length === 2 && isFinite(p[0]) && isFinite(p[1]);
        });
    }

    function flat(points) {
        var out = [];
        points.forEach(function (p) { out.push(p[0], p[1]); });
        return out;
    }

    function centroid(points) {
        var x = 0, y = 0;
        points.forEach(function (p) { x += p[0]; y += p[1]; });
        return [x / points.length, y / points.length];
    }

    function shapeColors(cam, kind, shape) {
        return S.badKeys[cam + '|' + shape._k] ? COLORS.bad : COLORS[kind];
    }

    function redraw() {
        shapeLayer.destroyChildren();
        S.lineNodes = {};
        var cam = S.camera;
        var drawing = S.mode === 'draw';
        C.KINDS.forEach(function (kind) {
            S.rois[cam][kind].forEach(function (shape) {
                if (!drawable(shape)) return; // 장비 파일이 깨져 점 형식이 맞지 않는 도형은 목록·문제 패널에만 보인다
                var col = shapeColors(cam, kind, shape);
                var isSel = S.selected === shape._k;
                var line = new Konva.Line({
                    points: flat(shape.points), closed: true,
                    fill: col.fill, stroke: col.stroke,
                    strokeWidth: (isSel ? 3.5 : 2) / scale, hitStrokeWidth: 12 / scale,
                    listening: !drawing, lineJoin: 'round'
                });
                line.on('click tap', function (e) { e.cancelBubble = true; onShapeClick(shape, kind); });
                shapeLayer.add(line);
                S.lineNodes[shape._k] = line;
                var c = centroid(shape.points);
                shapeLayer.add(new Konva.Text({
                    x: c[0], y: c[1], text: shape.name || C.KIND_LABEL[kind], fontSize: 14 / scale,
                    fill: '#ffffff', stroke: '#000000', strokeWidth: 0.6 / scale, fillAfterStrokeEnabled: true,
                    offsetX: 0, listening: false
                }));
            });
        });
        var sel = selectedShape();
        if (sel && !drawing) drawHandles(sel);
        shapeLayer.batchDraw();
        drawPreview();
        renderList();
        renderProblems();
        updateButtons();
        stage.container().style.cursor = drawing ? 'crosshair' : 'default';
    }

    function drawHandles(sel) {
        var shape = sel.shape;
        shape.points.forEach(function (pt, i) {
            var circle = new Konva.Circle({
                x: pt[0], y: pt[1], radius: 6 / scale, fill: '#ffffff', stroke: '#222222', strokeWidth: 1.5 / scale,
                draggable: true, hitStrokeWidth: 8 / scale,
                dragBoundFunc: function (pos) {
                    return { x: clamp(pos.x, 0, (W - 1) * scale), y: clamp(pos.y, 0, (H - 1) * scale) };
                }
            });
            circle.on('dragstart', function () {
                S.dragOrig = shape.points.map(function (p) { return [p[0], p[1]]; });
            });
            circle.on('dragmove', function () {
                var np = C.clampPoint(circle.x(), circle.y());
                circle.position({ x: np[0], y: np[1] });
                shape.points[i] = np;
                var line = S.lineNodes[shape._k];
                var why = C.checkShape(S.rois, S.camera, shape._k, shape.points);
                if (line) {
                    var col = why ? COLORS.bad : COLORS[sel.kind];
                    line.points(flat(shape.points));
                    line.stroke(col.stroke);
                    line.fill(col.fill);
                }
                if (why && Date.now() - S.lastDragToast > 1500) {
                    S.lastDragToast = Date.now();
                    toast(C.problemText(why) + ' — 놓으면 원래 위치로 돌아갑니다', 'warn');
                }
                shapeLayer.batchDraw();
            });
            circle.on('dragend', function () {
                var why = C.checkShape(S.rois, S.camera, shape._k, shape.points);
                if (why) {
                    shape.points = S.dragOrig;
                    toast(C.problemText(why) + ' — 원래 위치로 되돌렸습니다', 'warn');
                    redraw();
                } else {
                    commit();
                }
                S.dragOrig = null;
            });
            // 점 삭제: 더블클릭(또는 더블탭) / 오른쪽 클릭
            function deletePoint(e) {
                e.cancelBubble = true;
                if (e.evt && e.evt.preventDefault) e.evt.preventDefault();
                var next = C.removePoint(shape.points, i);
                if (!next) { toast('도형은 점이 3개 이상이어야 합니다', 'warn'); return; }
                var why = C.checkShape(S.rois, S.camera, shape._k, next);
                if (why) { toast(C.problemText(why) + ' — 이 점은 지울 수 없습니다', 'warn'); return; }
                shape.points = next;
                commit();
            }
            circle.on('dblclick dbltap', deletePoint);
            circle.on('contextmenu', deletePoint);
            circle.on('mouseenter', function () { stage.container().style.cursor = 'move'; });
            circle.on('mouseleave', function () { stage.container().style.cursor = 'default'; });
            shapeLayer.add(circle);
        });
    }

    // ------------------------------------------------------------------ 선택·클릭
    function onShapeClick(shape, kind) {
        if (S.mode === 'draw' || S.busy) return;
        if (S.selected !== shape._k) {
            S.selected = shape._k;
            redraw();
            return;
        }
        // 이미 선택된 도형의 변을 클릭하면 그 자리에 점을 삽입한다
        var p = pointerLogical();
        if (!p) return;
        var ne = C.nearestEdge(shape.points, p, EDGE_PICK_PX / scale);
        if (!ne) return;
        var next = C.insertPoint(shape.points, ne.index, ne.point);
        var why = C.checkShape(S.rois, S.camera, shape._k, next);
        if (why) { toast(C.problemText(why), 'warn'); return; }
        shape.points = next;
        commit();
    }

    function onStageClick(e) {
        if (S.busy) return;
        if (S.mode === 'draw') {
            var p = pointerLogical();
            if (!p) return;
            handleDrawClick(C.clampPoint(p[0], p[1]), p);
            return;
        }
        if (e.target === stage || (e.target.getLayer && e.target.getLayer() === imageLayer) || e.target.getParent() === imageLayer) {
            if (S.selected) { S.selected = null; redraw(); }
        }
    }

    // ------------------------------------------------------------------ 그리기
    function startDraw(kind) {
        if (S.busy) return;
        S.mode = 'draw';
        S.draw = { kind: kind, points: [] };
        S.selected = null;
        hint('점을 차례로 클릭하세요. 첫 점 근처를 클릭(또는 Enter)하면 닫힙니다. Backspace: 마지막 점 취소, Esc: 그리기 취소');
        redraw();
    }

    function endDraw() {
        S.mode = 'idle';
        S.draw = null;
        drawLayer.destroyChildren();
        drawLayer.batchDraw();
        hint('');
    }

    function handleDrawClick(pt, raw) {
        var pts = S.draw.points;
        if (pts.length >= 3 && Math.hypot(raw[0] - pts[0][0], raw[1] - pts[0][1]) * scale <= CLOSE_RADIUS_PX) {
            closeDraw();
            return;
        }
        var why = C.checkDrawPoint(S.rois, S.camera, pts, pt);
        if (why) {
            toast(C.problemText(why) + ' — 이 위치에는 점을 놓을 수 없습니다', 'warn');
            return;
        }
        pts.push(pt);
        drawPreview();
    }

    function closeDraw() {
        var pts = S.draw.points;
        if (pts.length < 3) { toast('점이 3개 이상이어야 합니다', 'warn'); return; }
        var why = C.checkShape(S.rois, S.camera, null, pts);
        if (why) { toast(C.problemText(why) + ' — 점을 고치거나 Esc 로 취소하세요', 'warn'); return; }
        var kind = S.draw.kind;
        var shape = { _k: C.nextKey(), id: '', name: C.defaultName(S.rois, S.camera, kind), points: pts.map(function (p) { return [p[0], p[1]]; }) };
        S.rois[S.camera][kind].push(shape);
        S.selected = shape._k;
        endDraw();
        commit();
    }

    function drawPreview() {
        drawLayer.destroyChildren();
        if (S.mode === 'draw' && S.draw) {
            var pts = S.draw.points, kind = S.draw.kind, col = COLORS[kind];
            var cur = pointerLogical();
            if (pts.length) {
                var line = pts.slice();
                var nearFirst = cur && pts.length >= 3 && Math.hypot(cur[0] - pts[0][0], cur[1] - pts[0][1]) * scale <= CLOSE_RADIUS_PX;
                if (cur && !nearFirst) line.push(C.clampPoint(cur[0], cur[1]));
                drawLayer.add(new Konva.Line({ points: flat(line), stroke: col.stroke, strokeWidth: 2 / scale, dash: [8 / scale, 5 / scale], closed: nearFirst, fill: nearFirst ? col.fill : undefined }));
            }
            pts.forEach(function (p, i) {
                var first = i === 0;
                var big = first && pts.length >= 3 && cur && Math.hypot(cur[0] - p[0], cur[1] - p[1]) * scale <= CLOSE_RADIUS_PX;
                drawLayer.add(new Konva.Circle({ x: p[0], y: p[1], radius: (big ? 9 : 5) / scale, fill: first ? '#ffd33d' : '#ffffff', stroke: '#222222', strokeWidth: 1.5 / scale }));
            });
        }
        drawLayer.batchDraw();
    }

    function hint(text) { $('#roiHint').textContent = text || ''; }

    // ------------------------------------------------------------------ 목록·문제 패널
    function renderList() {
        var root = $('#roiList');
        root.textContent = '';
        C.KINDS.forEach(function (kind) {
            var list = S.rois[S.camera][kind];
            var group = h('section', 'roi-group kind-' + kind);
            var head = h('div', 'roi-group-head');
            head.appendChild(h('span', 'roi-swatch'));
            head.appendChild(h('strong', null, C.KIND_LABEL[kind]));
            head.appendChild(h('span', 'roi-count', list.length + '개'));
            var add = h('button', 'roi-btn small', '+ 새 도형');
            add.type = 'button';
            add.disabled = S.busy;
            add.addEventListener('click', function () { startDraw(kind); });
            head.appendChild(add);
            group.appendChild(head);
            list.forEach(function (shape, idx) {
                var bad = !!S.badKeys[S.camera + '|' + shape._k];
                var row = h('div', 'roi-row' + (S.selected === shape._k ? ' selected' : '') + (bad ? ' bad' : ''));
                row.addEventListener('click', function (e) {
                    if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT' || e.target.tagName === 'BUTTON') return;
                    if (S.mode === 'draw') return;
                    S.selected = shape._k;
                    redraw();
                });
                var name = h('input', 'roi-name');
                name.type = 'text';
                name.maxLength = 40;
                name.value = shape.name;
                name.setAttribute('aria-label', C.KIND_LABEL[kind] + ' ' + (idx + 1) + ' 이름');
                name.addEventListener('input', function () { shape.name = name.value; recompute(); scheduleDraft(); updateButtons(); });
                name.addEventListener('change', function () { commit(); });
                name.addEventListener('focus', function () { if (S.selected !== shape._k && S.mode !== 'draw') { S.selected = shape._k; redraw(); } });
                row.appendChild(name);
                row.appendChild(h('span', 'roi-pts', shape.points.length + '점'));
                var sel = h('select', 'roi-kind');
                sel.setAttribute('aria-label', '종류 변경');
                C.KINDS.forEach(function (k) {
                    var o = h('option', null, C.KIND_LABEL[k]);
                    o.value = k;
                    if (k === kind) o.selected = true;
                    sel.appendChild(o);
                });
                sel.addEventListener('change', function () {
                    var to = sel.value;
                    if (to === kind) return;
                    S.rois[S.camera][kind].splice(idx, 1);
                    S.rois[S.camera][to].push(shape);
                    commit();
                });
                row.appendChild(sel);
                var del = h('button', 'roi-btn small danger', '삭제');
                del.type = 'button';
                del.addEventListener('click', function () { removeShape(shape._k); });
                row.appendChild(del);
                if (bad) row.appendChild(h('div', 'roi-row-warn', '다른 영역과 겹치거나 모양에 문제가 있습니다'));
                group.appendChild(row);
            });
            root.appendChild(group);
        });
    }

    function removeShape(key) {
        var f = C.findShape(S.rois, S.camera, key);
        if (!f) return;
        S.rois[S.camera][f.kind].splice(f.index, 1);
        if (S.selected === key) S.selected = null;
        commit();
    }

    function renderProblems() {
        var root = $('#roiProblems');
        root.textContent = '';
        if (!S.problems.length) return;
        var box = h('div', 'roi-problems');
        box.appendChild(h('strong', null, '해결할 문제 ' + S.problems.length + '건 (해결 전에는 저장할 수 없습니다)'));
        var ul = h('ul');
        S.problems.slice(0, 12).forEach(function (p) {
            var li = h('li', null, ((p.kind !== undefined && p.index !== undefined) ? C.shapeLabel(S.rois, p) : (p.camera || '')) + ' — ' + C.problemText(p.code));
            ul.appendChild(li);
        });
        box.appendChild(ul);
        root.appendChild(box);
    }

    function updateButtons() {
        $('#btnUndo').disabled = S.busy || S.mode === 'draw' || !S.history.canUndo();
        $('#btnRedo').disabled = S.busy || S.mode === 'draw' || !S.history.canRedo();
        $('#btnSave').disabled = S.busy || S.mode === 'draw' || S.problems.length > 0 || !S.dirty;
        $('#btnSave').title = S.problems.length ? '문제를 해결해야 저장할 수 있습니다' : (!S.dirty ? '변경된 내용이 없습니다' : '장비에 적용');
        $('#btnReload').disabled = S.busy;
        $('#btnResnap').disabled = S.busy;
        $('#btnHistory').disabled = S.busy;
        $('#btnClearCam').disabled = S.busy || S.mode === 'draw';
        $all('.roi-tabs button').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-cam') === S.camera); });
        $all('.roi-newshape button').forEach(function (b) { b.disabled = S.busy; });
    }

    // ------------------------------------------------------------------ 불러오기
    function setBusy(b) { S.busy = b; updateButtons(); renderList(); }

    function describeDrift(d) {
        return d && d.detected ? '현장에서 장비의 ROI 가 직접 바뀐 것을 감지해 이력(SYNC)에 기록했습니다. 장비 값을 기준으로 편집합니다.' : '';
    }

    function loadDevice(options) {
        options = options || {};
        setBusy(true);
        showWait('장비에서 ROI 를 불러오는 중입니다…', 15);
        return api('roiLoad', { deviceId: CFG.deviceId }).then(function (res) {
            hideWait();
            setBusy(false);
            if (res.status !== 200 || !res.data.ok) {
                banner('장비의 ROI 를 불러오지 못했습니다: ' + errorText(res), 'error');
                toast(errorText(res), 'error');
                return false;
            }
            var d = res.data;
            S.exists = !!d.exists;
            S.formatError = !!d.formatError;
            applyRois(d.rois, d.hash);
            var notes = [];
            if (S.formatError) notes.push('장비의 ROI 파일을 해석할 수 없어 비어 있는 상태로 시작합니다. 저장하면 그 파일을 덮어씁니다.');
            if (!S.exists) notes.push('장비에 ROI 파일이 아직 없습니다. 새로 만들어 저장합니다.');
            var drift = describeDrift(d.drift);
            if (drift) notes.push(drift);
            if (S.problems.length) notes.push('장비에 이미 겹치거나 잘못된 영역이 있습니다(빨간색). 해결하기 전에는 저장할 수 없습니다.');
            banner(notes.join(' '), S.formatError || S.problems.length ? 'warn' : 'info');
            return options.skipDraft ? true : maybeRestoreDraft().then(function () { return true; });
        });
    }

    function maybeRestoreDraft() {
        var d = C.loadDraft(window.localStorage, draftKey(), Date.now());
        if (!d) return Promise.resolve();
        var draftRois = C.normalizeLoaded(d.rois);
        if (C.serialize(draftRois) === S.initial) { C.clearDraft(window.localStorage, draftKey()); return Promise.resolve(); }
        var when = new Date(d.savedAt);
        var whenText = when.getFullYear() + '-' + pad2(when.getMonth() + 1) + '-' + pad2(when.getDate()) + ' ' + clockText(d.savedAt);
        var same = d.baseHash === S.baseHash;
        var lines = ['임시저장된 편집 내용이 있습니다 (' + whenText + ').'];
        var buttons;
        if (same) {
            lines.push('복원하시겠습니까?');
            buttons = [{ id: 'restore', label: '복원', primary: true }, { id: 'discard', label: '버리기' }, { id: 'cancel', label: '나중에' }];
        } else {
            lines.push('그 사이 장비의 ROI 가 바뀌었습니다. 복원하면 저장할 때 장비의 현재 값을 임시본 내용으로 덮어씁니다.');
            buttons = [{ id: 'restore', label: '복원(덮어쓰기)', primary: false }, { id: 'discard', label: '장비 값 사용(임시본 버림)', primary: true }, { id: 'cancel', label: '나중에' }];
        }
        return modal('임시본 복원', lines, buttons).then(function (id) {
            if (id === 'restore') {
                S.rois = draftRois;           // baseHash 는 장비의 현재 값을 쓴다(같으면 그대로, 다르면 덮어쓰기 선택)
                S.selected = null;
                S.history.commit(S.rois);     // reset 된 장비 상태 위에 한 단계로 쌓아 되돌리기로 장비 값에 돌아갈 수 있다
                onChanged();
                toast('임시본을 복원했습니다', 'info');
            } else if (id === 'discard') {
                C.clearDraft(window.localStorage, draftKey());
                $('#roiDraftState').textContent = '';
            }
        });
    }

    // ------------------------------------------------------------------ 스냅샷
    function loadImage(url) {
        return new Promise(function (resolve) {
            var img = new Image();
            img.onload = function () { resolve(img); };
            img.onerror = function () { resolve(null); };
            img.src = url;
        });
    }

    function loadSnapshot() {
        S.snapshotState = 'loading';
        drawImage();
        setBusy(true);
        showWait('장비에서 카메라 스냅샷을 가져오는 중입니다…', 15);
        return api('roiSnapshot', { deviceId: CFG.deviceId }).then(function (res) {
            if (res.status !== 200 || !res.data.ok) {
                hideWait();
                setBusy(false);
                S.snapshotState = 'failed';
                S.images = { Cam1: null, Cam2: null };
                drawImage();
                toast('스냅샷을 가져오지 못했습니다: ' + errorText(res), 'error');
                return false;
            }
            var ts = res.data.ts || Date.now();
            var base = CFG.ctx + '/deviceList/roiImage.do?deviceId=' + CFG.deviceId + '&camera=';
            return Promise.all([loadImage(base + 'Cam1&t=' + ts), loadImage(base + 'Cam2&t=' + ts)]).then(function (imgs) {
                hideWait();
                setBusy(false);
                S.images = { Cam1: imgs[0], Cam2: imgs[1] };
                S.snapshotState = (imgs[0] && imgs[1]) ? 'ok' : 'failed';
                if (S.snapshotState === 'failed') toast('스냅샷 이미지를 불러오지 못했습니다', 'error');
                drawImage();
                return true;
            });
        });
    }

    // ------------------------------------------------------------------ 저장
    // 저장/되돌리기 공통. payload: {deviceId, rois, baseHash} 또는 {deviceId, rollbackRhId, baseHash}
    function performSave(payload) {
        setBusy(true);
        showWait('장비에 ROI 를 적용하는 중입니다…', 15);
        return api('roiSave', payload).then(function (res) {
            hideWait();
            var d = res.data || {};
            if (res.status === 200 && d.ok) {
                setBusy(false);
                onSaved(d);
                return true;
            }
            setBusy(false);
            if (res.status === 409 && (d.code === 'CONFLICT' || !d.code)) {
                return modal('다른 곳에서 먼저 수정되었습니다', [
                    '다른 사용자(또는 현장)가 이 장비의 ROI 를 먼저 바꿨습니다. 지금 편집 내용은 임시본으로 남아 있습니다.',
                    '[장비 값 다시 불러오기]를 누르면 최신 값을 불러오고, 임시본을 복원할지 물어봅니다.'
                ], [{ id: 'reload', label: '장비 값 다시 불러오기', primary: true }, { id: 'cancel', label: '닫기' }]).then(function (id) {
                    if (id === 'reload') return loadDevice();
                    return false;
                });
            }
            if ((res.status === 504 && d.rhId) || (res.status === 0 && res.aborted)) {
                return d.rhId ? resolvePending(d.rhId) : modal('결과를 확인하지 못했습니다', [
                    '장비의 응답을 받지 못했습니다. 적용되었을 수도 있습니다.',
                    '[이력]에서 결과를 확인하거나 [장비 값 다시 불러오기]로 현재 상태를 확인하세요.'
                ], [{ id: 'ok', label: '확인', primary: true }]).then(function () { return false; });
            }
            if (res.status === 400 && d.problems && d.problems.length) {
                return modal('ROI 검증에 실패했습니다', problemLines(d.problems).concat(['편집을 계속해 문제를 고친 뒤 다시 저장하세요.']), [{ id: 'ok', label: '확인', primary: true }]).then(function () { return false; });
            }
            if (res.status === 503 || res.status === 0) {
                return modal('장비와 통신할 수 없습니다', [errorText(res), '네트워크와 장비 상태를 확인한 뒤 다시 시도하세요.'], [
                    { id: 'retry', label: '다시 시도', primary: true }, { id: 'cancel', label: '닫기' }
                ]).then(function (id) { return id === 'retry' ? performSave(payload) : false; });
            }
            return modal('저장하지 못했습니다', [errorText(res)], [{ id: 'ok', label: '확인', primary: true }]).then(function () { return false; });
        });
    }

    function onSaved(d) {
        applyRois(d.rois || C.stripForSave(S.rois), d.hash);
        S.exists = true;
        S.formatError = false;
        C.clearDraft(window.localStorage, draftKey());
        $('#roiDraftState').textContent = '';
        banner(d.snapshotSaved === false ? '장비 적용은 완료되었습니다. 다만 기준 스냅샷을 저장하지 못해 이력 미리보기에는 이미지가 없습니다.' : '', 'warn');
        toast('장비에 적용되었습니다' + (d.action === 'ROLLBACK' ? ' (되돌리기)' : ''), 'ok');
    }

    // 시간 초과(PENDING) 건을 장비 해시 비교로 확정한다. 서버가 장비에서 ROI 를 다시 읽어 비교한다.
    function resolvePending(rhId) {
        S.pendingRhId = rhId;
        var tries = 0;
        function attempt() {
            tries += 1;
            showWait('응답을 받지 못해 적용 여부를 확인하는 중입니다… (' + tries + '/3)', 15);
            return api('roiCheck', { rhId: rhId }).then(function (res) {
                hideWait();
                var d = res.data || {};
                if (res.status === 200 && d.ok && d.status === 'SUCCESS') {
                    S.pendingRhId = null;
                    toast('확인 결과 장비에 적용되었습니다', 'ok');
                    return loadDevice({ skipDraft: true }).then(function () { C.clearDraft(window.localStorage, draftKey()); return true; });
                }
                if (res.status === 200 && d.ok && d.status === 'FAIL') {
                    S.pendingRhId = null;
                    return modal('적용되지 않았습니다', [d.failMsg || '시간 초과 후 확인한 결과 장비에 적용되지 않았습니다.', '편집 내용은 그대로 남아 있습니다. 다시 저장해 보세요.'], [{ id: 'ok', label: '확인', primary: true }]).then(function () { return false; });
                }
                if (tries < 3) return attempt();
                return modal('결과를 확인하지 못했습니다', [
                    '장비와 통신이 되지 않아 적용 여부를 확인하지 못했습니다.',
                    '[다시 확인]을 누르거나, 나중에 이 장비의 ROI 화면을 다시 열면 자동으로 정리됩니다.'
                ], [{ id: 'again', label: '다시 확인', primary: true }, { id: 'cancel', label: '닫기' }]).then(function (id) {
                    if (id === 'again') { tries = 0; return attempt(); }
                    return false;
                });
            });
        }
        setBusy(true);
        return attempt().then(function (r) { setBusy(false); return r; });
    }

    function save() {
        if (S.busy || S.mode === 'draw') return;
        recompute();
        if (S.problems.length) { toast('문제를 해결해야 저장할 수 있습니다', 'warn'); renderProblems(); return; }
        var warn = C.emptyKindWarning(S.rois);
        var go = warn ? modal('저장 확인', [warn], [{ id: 'yes', label: '그래도 저장', primary: false }, { id: 'no', label: '취소', primary: true }]).then(function (id) { return id === 'yes'; }) : Promise.resolve(true);
        go.then(function (yes) {
            if (!yes) return;
            performSave({ deviceId: CFG.deviceId, rois: C.stripForSave(S.rois), baseHash: S.baseHash });
        });
    }

    // ------------------------------------------------------------------ 이력·되돌리기
    function openHistory() {
        if (S.busy) return;
        var root = $('#roiHistoryModal');
        var list = $('#roiHistoryList');
        var detail = $('#roiHistoryDetail');
        list.textContent = '이력을 불러오는 중…';
        detail.textContent = '왼쪽에서 이력을 선택하세요.';
        root.hidden = false;
        api('roiHistory', { deviceId: CFG.deviceId, limit: 50 }).then(function (res) {
            list.textContent = '';
            if (res.status !== 200 || !res.data.ok) { list.textContent = '이력을 불러오지 못했습니다: ' + errorText(res); return; }
            var items = res.data.items || [];
            if (!items.length) { list.textContent = '아직 이력이 없습니다.'; return; }
            var table = h('table', 'roi-history-table');
            var thead = h('tr');
            ['시각', '구분', '결과', '요청자'].forEach(function (t) { thead.appendChild(h('th', null, t)); });
            table.appendChild(thead);
            items.forEach(function (it) {
                var tr = h('tr', 'status-' + it.rh_status);
                tr.tabIndex = 0;
                tr.appendChild(h('td', null, it.req_date || ''));
                tr.appendChild(h('td', null, it.rh_action + (res.data.currentRhId === it.rh_id ? ' ★' : '')));
                var st = it.rh_status === 'SUCCESS' ? '성공' : (it.rh_status === 'FAIL' ? '실패' : '확인 중');
                var stCell = h('td', null, st + (it.rh_fail_msg ? ' — ' + it.rh_fail_msg : ''));
                tr.appendChild(stCell);
                tr.appendChild(h('td', null, it.rh_u_name || ''));
                function open() { $all('tr.active', table).forEach(function (r) { r.classList.remove('active'); }); tr.classList.add('active'); showHistoryDetail(it.rh_id, res.data.currentRhId); }
                tr.addEventListener('click', open);
                tr.addEventListener('keydown', function (e) { if (e.key === 'Enter') open(); });
                table.appendChild(tr);
            });
            list.appendChild(table);
            list.appendChild(h('p', 'roi-history-note', '★ = 현재 적용 중. 이력은 6개월 보관되며, 장비별 마지막 성공 이력은 계속 보존됩니다.'));
        });
    }

    function showHistoryDetail(rhId, currentRhId) {
        var detail = $('#roiHistoryDetail');
        detail.textContent = '불러오는 중…';
        api('roiHistoryDetail', { rhId: rhId }).then(function (res) {
            detail.textContent = '';
            if (res.status !== 200 || !res.data.ok) { detail.textContent = '상세를 불러오지 못했습니다: ' + errorText(res); return; }
            var d = res.data, hist = d.history, rois = C.normalizeLoaded(d.rois);
            var snaps = {};
            (d.snapshots || []).forEach(function (s) { snaps[s.camera] = s; });
            detail.appendChild(h('p', 'roi-history-meta', hist.req_date + ' · ' + hist.rh_action + ' · ' + hist.rh_u_name + ' · ' + hist.rh_status + (hist.rh_fail_msg ? ' (' + hist.rh_fail_msg + ')' : '')));
            var tabs = h('div', 'roi-tabs small');
            var canvas = h('canvas', 'roi-preview');
            canvas.width = 640; canvas.height = 360;
            var note = h('p', 'roi-history-note');
            var current = 'Cam1';
            function paint() {
                $all('button', tabs).forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-cam') === current); });
                var ctx = canvas.getContext('2d');
                function drawShapes() {
                    var k = canvas.width / W;
                    C.KINDS.forEach(function (kind) {
                        rois[current][kind].forEach(function (s) {
                            if (s.points.length < 3) return;
                            ctx.beginPath();
                            s.points.forEach(function (p, i) { if (i) ctx.lineTo(p[0] * k, p[1] * k); else ctx.moveTo(p[0] * k, p[1] * k); });
                            ctx.closePath();
                            ctx.fillStyle = COLORS[kind].fill; ctx.fill();
                            ctx.strokeStyle = COLORS[kind].stroke; ctx.lineWidth = 2; ctx.stroke();
                        });
                    });
                }
                ctx.fillStyle = '#2b2b33'; ctx.fillRect(0, 0, canvas.width, canvas.height);
                var snap = snaps[current];
                if (snap) {
                    note.textContent = '이 이력이 적용될 당시의 기준 스냅샷 위에 표시했습니다.';
                    loadImage(CFG.ctx + '/deviceList/roiImage.do?rsId=' + snap.rsId).then(function (img) {
                        ctx.fillStyle = '#2b2b33'; ctx.fillRect(0, 0, canvas.width, canvas.height);
                        if (img) ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                        drawShapes();
                    });
                } else {
                    note.textContent = '저장된 기준 스냅샷이 없어 빈 화면 위에 도형만 표시합니다.';
                    drawShapes();
                }
            }
            C.CAMERAS.forEach(function (cam) {
                var b = h('button', 'roi-btn small', cam);
                b.type = 'button';
                b.setAttribute('data-cam', cam);
                b.addEventListener('click', function () { current = cam; paint(); });
                tabs.appendChild(b);
            });
            detail.appendChild(tabs);
            detail.appendChild(canvas);
            detail.appendChild(note);
            var counts = C.CAMERAS.map(function (cam) { return cam + ': ' + C.KINDS.map(function (k) { return C.KIND_LABEL[k] + ' ' + rois[cam][k].length; }).join(', '); });
            detail.appendChild(h('p', 'roi-history-note', counts.join(' / ')));
            if (hist.rh_status === 'SUCCESS' && rhId !== currentRhId) {
                var rb = h('button', 'roi-btn primary', '이 이력으로 되돌리기');
                rb.type = 'button';
                rb.addEventListener('click', function () { rollbackTo(rhId, hist); });
                detail.appendChild(rb);
            }
            paint();
        });
    }

    function rollbackTo(rhId, hist) {
        var lines = [hist.req_date + ' 에 적용된 ROI 로 되돌립니다. 되돌린 결과도 새 이력으로 남습니다.'];
        if (S.dirty) lines.push('저장하지 않은 현재 편집 내용은 사라집니다.');
        modal('되돌리기 확인', lines, [{ id: 'yes', label: '되돌리기', primary: true }, { id: 'no', label: '취소' }]).then(function (id) {
            if (id !== 'yes') return;
            $('#roiHistoryModal').hidden = true;
            performSave({ deviceId: CFG.deviceId, rollbackRhId: rhId, baseHash: S.baseHash });
        });
    }

    // ------------------------------------------------------------------ 입력 연결
    function undo() {
        if (S.busy || S.mode === 'draw') return;
        var r = S.history.undo();
        if (r) { S.rois = r; S.selected = null; onChanged(); }
    }
    function redo() {
        if (S.busy || S.mode === 'draw') return;
        var r = S.history.redo();
        if (r) { S.rois = r; S.selected = null; onChanged(); }
    }

    function isTyping(e) { var t = e.target && e.target.tagName; return t === 'INPUT' || t === 'SELECT' || t === 'TEXTAREA'; }

    document.addEventListener('keydown', function (e) {
        if (!$('#roiModal').hidden || !$('#roiHistoryModal').hidden || !$('#roiWait').hidden) return;
        var mod = e.ctrlKey || e.metaKey;
        if (mod && !e.shiftKey && (e.key === 'z' || e.key === 'Z')) { if (!isTyping(e)) { e.preventDefault(); undo(); } return; }
        if (mod && (e.key === 'y' || e.key === 'Y' || (e.shiftKey && (e.key === 'z' || e.key === 'Z')))) { if (!isTyping(e)) { e.preventDefault(); redo(); } return; }
        if (isTyping(e)) return;
        if (S.mode === 'draw') {
            if (e.key === 'Escape') { endDraw(); redraw(); }
            else if (e.key === 'Enter') { closeDraw(); }
            else if (e.key === 'Backspace') { e.preventDefault(); S.draw.points.pop(); drawPreview(); }
            return;
        }
        if (e.key === 'Escape' && S.selected) { S.selected = null; redraw(); }
        else if ((e.key === 'Delete') && S.selected) { removeShape(S.selected); }
    });

    window.addEventListener('beforeunload', function (e) {
        if (S.dirty) { e.preventDefault(); e.returnValue = ''; }
    });

    function bind() {
        $all('.roi-tabs button').forEach(function (b) {
            b.addEventListener('click', function () {
                if (S.mode === 'draw') { toast('그리기를 끝내거나(Esc) 취소한 뒤 카메라를 바꾸세요', 'warn'); return; }
                S.camera = b.getAttribute('data-cam');
                S.selected = null;
                drawImage();
                redraw();
            });
        });
        $all('.roi-newshape button').forEach(function (b) {
            b.addEventListener('click', function () { startDraw(b.getAttribute('data-kind')); });
        });
        $('#btnUndo').addEventListener('click', undo);
        $('#btnRedo').addEventListener('click', redo);
        $('#btnSave').addEventListener('click', save);
        $('#btnReload').addEventListener('click', function () {
            var go = S.dirty ? modal('다시 불러오기', ['저장하지 않은 편집 내용은 임시본으로 남고, 장비의 현재 값을 불러옵니다.'], [{ id: 'yes', label: '불러오기', primary: true }, { id: 'no', label: '취소' }]).then(function (id) { return id === 'yes'; }) : Promise.resolve(true);
            go.then(function (yes) { if (yes) { scheduleDraftNow(); loadDevice(); } });
        });
        $('#btnResnap').addEventListener('click', function () { loadSnapshot(); });
        $('#btnHistory').addEventListener('click', openHistory);
        $('#btnClearCam').addEventListener('click', function () {
            var n = C.KINDS.reduce(function (a, k) { return a + S.rois[S.camera][k].length; }, 0);
            if (!n) return;
            modal('전체 삭제', [S.camera + ' 의 도형 ' + n + '개를 모두 지웁니다. (되돌리기로 복구할 수 있습니다)'], [{ id: 'yes', label: '모두 삭제', primary: false }, { id: 'no', label: '취소', primary: true }]).then(function (id) {
                if (id !== 'yes') return;
                C.KINDS.forEach(function (k) { S.rois[S.camera][k] = []; });
                S.selected = null;
                commit();
            });
        });
        $('#roiHistoryClose').addEventListener('click', function () { $('#roiHistoryModal').hidden = true; });
        $('#roiHistoryModal').addEventListener('click', function (e) { if (e.target === $('#roiHistoryModal')) $('#roiHistoryModal').hidden = true; });
    }

    function scheduleDraftNow() {
        clearTimeout(S.draftTimer);
        if (S.dirty) C.saveDraft(window.localStorage, draftKey(), S.baseHash, S.rois, Date.now());
    }

    // ------------------------------------------------------------------ 시작
    bind();
    initStage();
    recompute();
    redraw();
    // 장비 값을 먼저 불러온 뒤(빠름) 스냅샷(최대 15초)을 받는다.
    loadDevice().then(function (ok) { if (ok) return loadSnapshot(); return false; });
})();
