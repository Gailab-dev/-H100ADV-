// Local Docker integration test. Requires Playwright and the running h100-local stack.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const output = path.join(root, 'tmp/vehicle-context');
const base = 'http://localhost:7810';
const tag = 'vehicle_test_' + Date.now();
const file = tag + '.png';
const credentials = fs.readFileSync(path.join(root, 'ops/local/first-login.txt'), 'utf8');
const plate = '987하' + String(Math.floor(Math.random() * 10000)).padStart(4, '0');
function sql(query) {
    return execFileSync('docker', ['exec', 'h100-local-db-1', 'sh', '-c',
        'MYSQL_PWD="$MARIADB_PASSWORD" exec mariadb --default-character-set=utf8mb4 -N -u h100 able_park -e "$1"', 'sh', query], {encoding: 'utf8'}).trim();
}
function insertEvent(device, car, date, deleted = 0, image2 = file) {
    return Number(sql(`INSERT INTO tbl_event_data
        (ev_dv_id,ev_dv_name,ev_dv_addr,ev_car_num,ev_cd,ev_action,ev_date,ev_img_path,ev_img_path2,ev_has_img,ev_is_deleted)
        VALUES (${device},'${tag}','Local test site','${car}',1,1,'${date}','${file}','${image2}',1,${deleted}); SELECT LAST_INSERT_ID();`));
}
(async () => {
    fs.mkdirSync(output, {recursive: true});
    const counts = sql('SELECT (SELECT COUNT(*) FROM tbl_event_data),(SELECT COUNT(*) FROM tbl_device)');
    let browser;
    try {
        assert.equal(sql(`SELECT COUNT(*) FROM tbl_event_data WHERE REPLACE(REPLACE(TRIM(ev_car_num),' ',''),'-','')='${plate}'`), '0');
        const device = Number(sql(`INSERT INTO tbl_device (dv_name,dv_serial_number,dv_lat,dv_lng,dv_addr)
            VALUES ('${tag}','${Date.now()}1',35.1595,126.8526,'Local test site'); SELECT LAST_INSERT_ID();`));
        const noLocation = Number(sql(`INSERT INTO tbl_device (dv_name,dv_serial_number) VALUES ('${tag}','${Date.now()}2'); SELECT LAST_INSERT_ID();`));
        let current;
        for (let i = 1; i <= 12; i++) {
            current = insertEvent(i % 2 ? noLocation : device, i % 2 ? plate.slice(0,3) + (i === 1 ? '-' : ' ') + plate.slice(3) : plate,
                '20261015' + String(i).padStart(2, '0') + '0000');
        }
        const deleted = insertEvent(device, plate, '20261016000000', 1);
        insertEvent(device, plate + '9', '20261016000000');
        const unknown = insertEvent(device, '', '20261015140000', 0, '');
        const missing = insertEvent(noLocation, '-', '20261015150000', 0, '');
        execFileSync('docker', ['exec', 'h100-local-web-1', 'mkdir', '-p', '/app/H100_system/output_images']);
        execFileSync('docker', ['cp', path.join(root, 'docs/screenshots/captured-rtsp.png'), 'h100-local-web-1:/app/H100_system/output_images/' + file]);
        browser = await chromium.launch({headless: process.env.H100_HEADED !== '1', channel: process.env.H100_BROWSER_CHANNEL || 'chrome'});
        const context = await browser.newContext({viewport: {width: 1600, height: 1100}});
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        const login = await context.request.post(base + '/user/login', {data: {
            id: credentials.match(/^User: (.+)$/m)[1].trim(), pwd: credentials.match(/^Password: (.+)$/m)[1].trim()
        }});
        assert.equal((await login.json()).ok, true);
        const detail = id => base + '/eventList/eventListDetail?evId=' + id;
        // Exercise the real SDK denial, then test the core view without a network dependency.
        assert.equal((await page.goto(detail(current))).status(), 200);
        const mapKey = await page.locator('#vehicleLocationMap').getAttribute('data-kakao-key');
        if (mapKey) {
            const sdk = await context.request.get('https://dapi.kakao.com/v2/maps/sdk.js?appkey=' + encodeURIComponent(mapKey) + '&autoload=false', {headers: {Referer: base + '/'}});
            console.log(JSON.stringify({kakaoSdkStatus: sdk.status(), kakaoSdkBody: sdk.status() >= 400 ? (await sdk.text()).slice(0, 180) : 'OK'}));
        }
        await page.route('https://dapi.kakao.com/**', route => route.abort());
        await page.reload();
        await page.locator('.detail-image').first().evaluate(image => image.decode());
        await page.locator('.detail-image').nth(1).evaluate(image => image.decode());
        assert.equal(await page.locator('.vehicle-identity strong').innerText(), plate);
        assert.equal(await page.locator('.vehicle-overview dl').nth(0).locator('dd').innerText(), '12건');
        assert.equal(await page.locator('.vehicle-overview dl').nth(1).locator('dd').innerText(), '2곳');
        assert.equal(await page.locator('.vehicle-timeline li').count(), 10);
        assert.equal(await page.locator('.vehicle-timeline time').first().innerText(), '2026-10-15 12:00:00');
        assert.equal(await page.locator('.vehicle-timeline time').last().innerText(), '2026-10-15 03:00:00');
        assert.equal(await page.locator('.vehicle-timeline [aria-current="page"]').count(), 1);
        assert.match(await page.getByRole('link', {name: '카카오맵', exact: true}).getAttribute('href'), /35\.1595,126\.8526/);
        await page.getByRole('button', {name: '겹쳐 보기', exact: true}).click();
        await page.locator('#evidenceCompare').fill('25');
        assert.equal(await page.locator('#vehicleEvidence').evaluate(el => el.style.getPropertyValue('--compare-position')), '25%');
        assert.equal(await page.getByRole('button', {name: '겹쳐 보기', exact: true}).getAttribute('aria-pressed'), 'true');
        await page.screenshot({path: path.join(output, 'comparison.png'), fullPage: true});
        await page.getByRole('button', {name: '나란히 보기', exact: true}).click();
        await page.getByRole('button', {name: '진입 시 사진 확대', exact: true}).click();
        assert.equal(await page.locator('#evidenceViewer').evaluate(el => el.open), true);
        await page.locator('#evidenceZoom').fill('250');
        assert.equal(await page.locator('#evidenceZoomValue').innerText(), '250%');
        await page.keyboard.press('Escape');
        assert.equal(await page.locator('#evidenceViewer').evaluate(el => el.open), false);
        await page.screenshot({path: path.join(output, 'desktop.png'), fullPage: true});
        const nextUrl = new URL(await page.locator('.vehicle-timeline a').nth(1).getAttribute('href'), base).href;
        const prepared = page.waitForResponse(r => r.url().includes('/eventList/detail/check?'));
        await Promise.all([page.waitForURL(nextUrl), page.locator('.vehicle-timeline a').nth(1).click()]);
        assert.equal((await prepared).status(), 200);
        assert.equal(await page.locator('.vehicle-timeline [aria-current="page"]').count(), 1);
        assert.equal(await page.locator('.vehicle-location').count(), 0);
        await page.goto(detail(unknown));
        assert.equal(await page.locator('.vehicle-history').count(), 0);
        assert.equal(await page.getByRole('button', {name: '겹쳐 보기', exact: true}).isDisabled(), true);
        await page.goto(detail(missing));
        assert.equal(await page.locator('.vehicle-history').count(), 0);
        assert.equal(await page.locator('.vehicle-location').count(), 0);
        await page.goto(detail(current));
        for (const width of [1024, 768, 390]) {
            await page.setViewportSize({width, height: 1000});
            assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false, 'Overflow at ' + width);
        }
        await page.screenshot({path: path.join(output, 'mobile.png'), fullPage: true});
        await page.setViewportSize({width:1600,height:1100});
        await page.getByRole('button', {name:'차량 모형',exact:true}).click();
        await page.waitForFunction(() => document.querySelector('#vehicleSceneCanvas').width > 0);
        await page.screenshot({path:path.join(output,'model.png'),fullPage:true});
        const beforeOrbit=await page.locator('#vehicleSceneCanvas').evaluate(el=>el.toDataURL());
        await page.getByRole('button',{name:'측면',exact:true}).click();
        await page.waitForFunction(previous=>document.querySelector('#vehicleSceneCanvas').toDataURL()!==previous,beforeOrbit);
        const beforeDrag=await page.locator('#vehicleSceneCanvas').evaluate(el=>el.toDataURL());
        const sceneBox=await page.locator('#vehicleSceneCanvas').boundingBox();
        await page.mouse.move(sceneBox.x+sceneBox.width/2,sceneBox.y+sceneBox.height/2);
        await page.mouse.down();await page.mouse.move(sceneBox.x+sceneBox.width/2+70,sceneBox.y+sceneBox.height/2+30,{steps:5});await page.mouse.up();
        await page.waitForFunction(previous=>document.querySelector('#vehicleSceneCanvas').toDataURL()!==previous,beforeDrag);
        const spatialUrl=base+'/eventList/spatialContext?evId='+current;
        const initial=await (await context.request.get(spatialUrl)).json();
        assert.deepEqual(initial.boundary,[]);
        const boundary=[{lat:35.15955,lng:126.85255},{lat:35.15955,lng:126.8527},{lat:35.1594,lng:126.8527},{lat:35.1594,lng:126.85255}];
        const payload={evId:current,boundary,pose:{lat:35.15948,lng:126.85262,heading:45}};
        assert.equal((await context.request.post(base+'/eventList/spatialContext',{data:payload})).status(),403);
        const headers={'X-H100-CSRF':initial.token};
        assert.equal((await context.request.post(base+'/eventList/spatialContext',{headers,data:{...payload,boundary:[boundary[0],boundary[2],boundary[1],boundary[3]]}})).status(),400);
        assert.equal((await context.request.post(base+'/eventList/spatialContext',{headers,data:{...payload,pose:{...payload.pose,lat:36}}})).status(),400);
        assert.equal((await context.request.post(base+'/eventList/spatialContext',{headers,data:{...payload,pose:{...payload.pose,heading:360}}})).status(),400);
        await page.getByRole('button',{name:'구역·배치 편집',exact:true}).click();
        await page.locator('#spatialBoundary').fill(boundary.map(p=>p.lng+', '+p.lat).join('\n'));
        await page.locator('#spatialVehicleLat').fill(String(payload.pose.lat));
        await page.locator('#spatialVehicleLng').fill(String(payload.pose.lng));
        await page.locator('#spatialVehicleHeading').fill('45');
        await page.getByRole('button',{name:'저장',exact:true}).click();
        await page.waitForFunction(()=>!document.querySelector('#spatialEditor').open);
        assert.equal(await page.getByRole('button',{name:'주차 공간',exact:true}).getAttribute('aria-pressed'),'true');
        assert.equal(await page.locator('#sceneManualLabel').isVisible(),true);
        const saved=await(await context.request.get(spatialUrl)).json();
        assert.deepEqual(saved.boundary,boundary);
        assert.equal(Number(saved.pose.heading),45);
        const shared=await(await context.request.get(base+'/eventList/spatialContext?evId='+unknown)).json();
        assert.deepEqual(shared.boundary,boundary);assert.equal(shared.pose,undefined);
        assert.equal((await context.request.get(base+'/eventList/spatialContext?evId='+deleted)).status(),404);
        await page.screenshot({path:path.join(output,'spatial.png'),fullPage:true});
        await page.reload();
        await page.getByRole('button',{name:'주차 공간',exact:true}).click();
        await page.getByRole('button',{name:'구역·배치 편집',exact:true}).click();
        assert.equal(await page.locator('#spatialVehicleHeading').inputValue(),'45');
        await page.getByRole('button',{name:'차량 배치 지우기',exact:true}).click();
        await page.getByRole('button',{name:'경계 지우기',exact:true}).click();
        await page.getByRole('button',{name:'저장',exact:true}).click();
        await page.waitForFunction(()=>!document.querySelector('#spatialEditor').open);
        const cleared=await(await context.request.get(spatialUrl)).json();
        assert.deepEqual(cleared.boundary,[]);assert.equal(cleared.pose,undefined);
        await page.getByRole('button',{name:'구역·배치 편집',exact:true}).click();
        const planBox=await page.locator('#spatialPlanCanvas').boundingBox();
        for(const p of [[.25,.25],[.75,.25],[.5,.75]]) await page.locator('#spatialPlanCanvas').click({position:{x:planBox.width*p[0],y:planBox.height*p[1]}});
        assert.equal((await page.locator('#spatialBoundary').inputValue()).split('\n').length,3);
        await page.getByRole('button',{name:'차량 배치',exact:true}).click();
        await page.locator('#spatialPlanCanvas').click({position:{x:planBox.width/2,y:planBox.height/2}});
        assert(Math.abs(Number(await page.locator('#spatialVehicleLat').inputValue())-35.1595)<.000001);
        assert(Math.abs(Number(await page.locator('#spatialVehicleLng').inputValue())-126.8526)<.000001);
        await page.screenshot({path:path.join(output,'editor.png'),fullPage:true});
        await page.setViewportSize({width:390,height:844});
        assert(await page.locator('#spatialEditor').evaluate(el=>el.scrollWidth<=el.clientWidth));
        await page.getByRole('button',{name:'주차 공간 편집 닫기',exact:true}).click();
        assert.deepEqual((await(await context.request.get(spatialUrl)).json()).boundary,[]);
        await page.getByRole('button',{name:'차량 모형',exact:true}).click();
        assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
        await page.screenshot({path:path.join(output,'mobile-3d.png'),fullPage:true});
        await page.setViewportSize({width:1600,height:1100});
        await page.getByRole('button',{name:'촬영 사진',exact:true}).click();
        if (mapKey) {
            // Verify satellite options with a SDK stub; this is not a live imagery check.
            await page.unroute('https://dapi.kakao.com/**');
            await page.route('https://dapi.kakao.com/**', route => route.fulfill({contentType: 'application/javascript', body: `
                window.kakao = {maps: {load: cb => cb(), LatLng: function(lat,lng){this.lat=lat;this.lng=lng;},
                    MapTypeId: {HYBRID: 'HYBRID'}, ControlPosition: {RIGHT: 'RIGHT'}, LatLngBounds: function(){this.extend=function(){};},
                    Map: function(el,options){window.testMapOptions=options;this.addControl=function(){};},
                    Marker: function(options){window.testMarkerOptions=options;}, ZoomControl: function(){}}};
            `}));
            await page.reload();
            await page.waitForFunction(() => !!window.testMapOptions);
            assert.equal(await page.locator('#vehicleLocationMap').isVisible(), true);
            assert.deepEqual(await page.evaluate(() => ({type: testMapOptions.mapTypeId, lat: testMapOptions.center.lat, lng: testMapOptions.center.lng})),
                {type: 'HYBRID', lat: 35.1595, lng: 126.8526});
        }
        const guest = await browser.newContext();
        const unauthorized = await guest.request.get(detail(current), {headers: {'X-Requested-With': 'XMLHttpRequest'}});
        assert.equal(unauthorized.status(), 401);
        assert.equal((await guest.request.get(spatialUrl,{headers:{'X-Requested-With':'XMLHttpRequest'}})).status(),401);
        await guest.close();
        assert.deepEqual(errors, []);
        console.log('PASS: vehicle history, deletion exclusion, photo comparison/zoom, 3D orbit, geofence/pose save-reload-clear, invalid geometry/CSRF rejection, missing data, map denial, responsive layout and session access.');
    } finally {
        if (browser) await browser.close();
        sql(`DELETE P FROM tbl_event_vehicle_pose P JOIN tbl_event_data E ON E.ev_id=P.ev_id WHERE E.ev_dv_name='${tag}'; DELETE G FROM tbl_device_geofence G JOIN tbl_device D ON D.dv_id=G.dv_id WHERE D.dv_name='${tag}'; DELETE FROM tbl_event_data WHERE ev_dv_name='${tag}'; DELETE FROM tbl_device WHERE dv_name='${tag}';`);
        execFileSync('docker', ['exec', 'h100-local-web-1', 'rm', '-f', '/app/H100_system/output_images/' + file]);
        assert.equal(sql('SELECT (SELECT COUNT(*) FROM tbl_event_data),(SELECT COUNT(*) FROM tbl_device)'), counts, 'Fixtures must be removed');
        if (process.env.H100_KEEP_TEST_ARTIFACTS !== '1') fs.rmSync(output, {recursive: true, force: true});
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
