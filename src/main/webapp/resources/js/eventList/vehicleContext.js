(function () {
    'use strict';

    var evidence = document.getElementById('vehicleEvidence');
    if (!evidence) return;
    var images = Array.from(evidence.querySelectorAll('.detail-image'));
    var overlayButton = document.querySelector('[data-evidence-mode="overlay"]');
    var compare = document.getElementById('evidenceCompare');
    var viewer = document.getElementById('evidenceViewer');
    var viewerImage = document.getElementById('evidenceViewerImage');
    var zoom = document.getElementById('evidenceZoom');

    function ready(image) {
        return image.complete && image.naturalWidth > 0 && image.currentSrc.indexOf('/imgFile/') !== -1;
    }

    function setMode(mode) {
        var overlay = mode === 'overlay' && images.every(ready);
        evidence.classList.toggle('is-overlay', overlay);
        compare.hidden = !overlay;
        document.querySelectorAll('[data-evidence-mode]').forEach(function (button) {
            button.setAttribute('aria-pressed', String(button.dataset.evidenceMode === (overlay ? 'overlay' : 'side')));
        });
    }

    function updateAvailability() {
        images.forEach(function (image, index) {
            evidence.querySelector('[data-expand-evidence="' + index + '"]').disabled = !ready(image);
        });
        overlayButton.disabled = !images.every(ready);
        if (overlayButton.disabled) setMode('side');
    }

    images.forEach(function (image) {
        image.addEventListener('load', updateAvailability);
        image.addEventListener('error', updateAvailability);
    });
    updateAvailability();
    document.querySelectorAll('[data-evidence-mode]').forEach(function (button) {
        button.addEventListener('click', function () { setMode(button.dataset.evidenceMode); });
    });
    function updateCompare() {
        evidence.style.setProperty('--compare-position', compare.value + '%');
    }
    compare.addEventListener('input', updateCompare);
    updateCompare();

    function updateZoom() {
        viewerImage.style.width = zoom.value + '%';
        document.getElementById('evidenceZoomValue').value = zoom.value + '%';
    }
    zoom.addEventListener('input', updateZoom);
    evidence.querySelectorAll('[data-expand-evidence]').forEach(function (button) {
        button.addEventListener('click', function () {
            var image = images[Number(button.dataset.expandEvidence)];
            if (!ready(image)) return;
            viewerImage.src = image.currentSrc;
            viewerImage.alt = button.getAttribute('aria-label');
            document.getElementById('evidenceViewerTitle').textContent = button.closest('.img-box').querySelector('.imgeTitle').textContent;
            zoom.value = '100';
            updateZoom();
            viewer.showModal();
            viewer.querySelector('.evidence-viewer-scroll').scrollTo(0, 0);
        });
    });
    document.getElementById('closeEvidenceViewer').addEventListener('click', function () { viewer.close(); });
    viewer.addEventListener('close', function () { viewerImage.removeAttribute('src'); });

    document.querySelectorAll('.vehicle-timeline a').forEach(function (link) {
        link.addEventListener('click', function (event) {
            if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
            event.preventDefault();
            if (link.getAttribute('aria-busy') === 'true') return;
            link.setAttribute('aria-busy', 'true');
            var detailUrl = new URL(link.href);
            var checkUrl = new URL(detailUrl.href);
            checkUrl.pathname = checkUrl.pathname.replace(/\/eventListDetail$/, '/detail/check');
            var controller = new AbortController();
            var timeout = setTimeout(function () { controller.abort(); }, 32000);
            // 기존 파일 준비 경로를 재사용한다. 영상·사진이 없어도 이력 정보는 열 수 있다.
            fetch(checkUrl.href, {headers: {'X-Requested-With': 'XMLHttpRequest'}, signal: controller.signal})
                .catch(function () {})
                .finally(function () {
                    clearTimeout(timeout);
                    window.location.assign(detailUrl.href);
                });
        });
    });

    var mapElement = document.getElementById('vehicleLocationMap');
    var spatialContext = null, locationMap = null, spatialOverlays = [];
    function drawSpatial() {
        if (!locationMap || !spatialContext) return;
        spatialOverlays.forEach(function (overlay) { overlay.setMap(null); });
        spatialOverlays = [];
        var bounds = new window.kakao.maps.LatLngBounds();
        bounds.extend(new window.kakao.maps.LatLng(Number(mapElement.dataset.lat), Number(mapElement.dataset.lng)));
        if (spatialContext.boundary.length >= 3) {
            var points = spatialContext.boundary.map(function (point) { var p = new window.kakao.maps.LatLng(point.lat, point.lng); bounds.extend(p); return p; });
            spatialOverlays.push(new window.kakao.maps.Polygon({map: locationMap, path: points, strokeWeight: 2, strokeColor: '#35a88d', fillColor: '#35a88d', fillOpacity: .18}));
        }
        if (spatialContext.pose) {
            var pose = new window.kakao.maps.LatLng(spatialContext.pose.lat, spatialContext.pose.lng);
            bounds.extend(pose);
            spatialOverlays.push(new window.kakao.maps.Marker({map: locationMap, position: pose, title: '차량 수동 배치'}));
        }
        if (spatialOverlays.length) locationMap.setBounds(bounds);
    }
    document.addEventListener('spatialcontextchange', function (event) { spatialContext = event.detail; drawSpatial(); });
    if (!mapElement || !mapElement.dataset.kakaoKey) return;
    function drawLocation() {
        if (!window.kakao || !window.kakao.maps || !window.kakao.maps.load) return;
        window.kakao.maps.load(function () {
            try {
                var point = new window.kakao.maps.LatLng(Number(mapElement.dataset.lat), Number(mapElement.dataset.lng));
                mapElement.hidden = false;
                var map = new window.kakao.maps.Map(mapElement, {
                    center: point, level: 2, mapTypeId: window.kakao.maps.MapTypeId.HYBRID
                });
                new window.kakao.maps.Marker({position: point, map: map});
                map.addControl(new window.kakao.maps.ZoomControl(), window.kakao.maps.ControlPosition.RIGHT);
                locationMap = map;
                drawSpatial();
            } catch (error) {
                mapElement.hidden = true;
            }
        });
    }
    if (window.kakao && window.kakao.maps) {
        drawLocation();
    } else {
        var sdk = document.createElement('script');
        sdk.src = 'https://dapi.kakao.com/v2/maps/sdk.js?appkey=' + encodeURIComponent(mapElement.dataset.kakaoKey) + '&autoload=false';
        sdk.onload = drawLocation;
        document.head.appendChild(sdk);
    }
}());
