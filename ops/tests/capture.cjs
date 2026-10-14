const { chromium } = require('@playwright/test');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const output = path.join(root, 'tmp/docker-setup');
const base = 'http://localhost:7810';
const credentials = fs.readFileSync(path.join(root, 'ops/local/first-login.txt'), 'utf8');
const password = credentials.match(/^Password: (.+)$/m)[1].trim();
const env = Object.fromEntries(fs.readFileSync(path.join(root,'ops/local/pc.env'),'utf8').trim().split(/\r?\n/).map(line => {const i=line.indexOf('='); return [line.slice(0,i), line.slice(i+1)];}));
function sql(query) {
  return execFileSync('docker', ['exec','h100-local-db-1','sh','-c','MYSQL_PWD="$MARIADB_PASSWORD" exec mariadb -N -u h100 able_park -e "$1"','sh',query], {encoding:'utf8'}).trim();
}
const result = {};
(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    const context = await browser.newContext({viewport:{width:1600,height:1000},ignoreHTTPSErrors:true});
    const login = await context.request.post(base+'/user/login',{data:{id:'local_admin',pwd:password}});
    assert.equal((await login.json()).ok,true);
    const forbidden = await context.request.post(base+'/deviceList/detection/1',{data:{request_id:crypto.randomUUID()}});
    assert.equal(forbidden.status(),403);
    result.csrfRejected=403;
    const unauthenticated = await context.request.post('https://localhost:7812/detection/trigger',{data:{}});
    assert.equal(unauthenticated.status(),401);
    result.edgeUnauthorized=401;
    const badUpload = await context.request.post('https://localhost:7811/detectionCapture',{data:{}});
    assert.equal(badUpload.status(),401);
    result.cloudUnsignedRejected=401;
    const page = await context.newPage();
    await page.goto(base+'/deviceList/viewDeviceList.do',{waitUntil:'networkidle'});
    assert(await page.locator('#deviceTable .err-log-btn').evaluateAll(buttons => buttons.length > 0 && buttons.every(button => {
      const b=button.getBoundingClientRect(), cell=button.closest('td').getBoundingClientRect();
      return b.right<=cell.right+1 && b.bottom<=cell.bottom+1;
    })), 'Existing log buttons must remain inside their cells');
    const responseWait=page.waitForResponse(r=>r.url()===base+'/deviceList/detection/1' && r.request().method()==='POST',{timeout:60000});
    let dialogText='';
    page.on('dialog',async dialog=>{dialogText=dialog.message();await dialog.accept();});
    await page.locator('.detection-btn[data-device-id="1"]').click();
    const response=await responseWait;
    const receipt=await response.json();
    assert.equal(response.status(),200,JSON.stringify(receipt));
    assert.equal(receipt.ok,true);
    assert.match(receipt.request_id,/^[a-f0-9-]{36}$/);
    assert.match(receipt.file,/^[a-zA-Z0-9_.-]+\.png\.enc$/);
    result.receipt=receipt;
    await page.waitForFunction(()=>!document.querySelector('.detection-btn[data-device-id="1"]').disabled);
    assert.match(dialogText,/저장 완료/);
    await page.screenshot({path:path.join(output,'screenshots/detection-button.png'),fullPage:true});
    const token=(await (await context.request.get(base+'/deviceList/detection/token')).json()).token;
    const retry=await context.request.post(base+'/deviceList/detection/1',{headers:{'X-H100-CSRF':token},data:{request_id:receipt.request_id}});
    assert.equal(retry.status(),200);
    assert.equal((await retry.json()).event_id,receipt.event_id);
    const count=sql(`SELECT COUNT(*) FROM tbl_detection_capture WHERE request_id='${receipt.request_id}'`);
    assert.equal(count,'1');
    result.retrySingleEvent=true;
    const stored=sql(`SELECT ev_has_img,ev_cd FROM tbl_event_data WHERE ev_id=${Number(receipt.event_id)}`);
    assert.equal(stored,'1\t4');
    assert.equal(sql(`SELECT COUNT(*) FROM tbl_notification_log WHERE noti_target_id=${Number(receipt.event_id)} AND noti_type='event'`),'1');
    result.databaseAndNotification=true;
    const encryptedFile=path.join(output,'capture.enc');
    execFileSync('docker',['cp',`h100-local-module-c-1:/app/H100_system/output_images_enc/${receipt.file}`,encryptedFile]);
    const encrypted=fs.readFileSync(encryptedFile);
    assert.equal(encrypted.length,receipt.bytes);
    assert.equal(crypto.createHash('sha256').update(encrypted).digest('hex'),receipt.sha256);
    const decipher=crypto.createDecipheriv('aes-256-cbc',Buffer.from(env.H100_AES_KEY,'hex'),encrypted.subarray(0,16));
    const png=Buffer.concat([decipher.update(encrypted.subarray(16)),decipher.final()]);
    assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
    fs.writeFileSync(path.join(output,'screenshots/captured-rtsp.png'),png);
    result.image={width:png.readUInt32BE(16),height:png.readUInt32BE(20),encryptedBytes:encrypted.length,sha256Verified:true};
    const concurrentId=crypto.randomUUID();
    const upload=Buffer.from(JSON.stringify({request_id:concurrentId,serial:'2026101400001',captured_at:new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),image:encrypted.toString('base64')}));
    const signature=crypto.createHmac('sha256',Buffer.from(env.H100_DEVICE_HMAC_KEY,'hex')).update('2026101400001').update(upload).digest('hex');
    const headers={'Content-Type':'application/json','X-Device-Serial':'2026101400001','X-Device-HMAC':signature};
    const concurrent=await Promise.all([1,2].map(()=>context.request.post('https://localhost:7811/detectionCapture',{headers,data:upload})));
    assert(concurrent.every(r=>r.status()===200));
    const receipts=await Promise.all(concurrent.map(r=>r.json()));
    assert.equal(receipts[0].event_id,receipts[1].event_id);
    assert.equal(sql(`SELECT COUNT(*) FROM tbl_detection_capture WHERE request_id='${concurrentId}'`),'1');
    result.concurrentRetrySingleEvent=true;
    const tampered=await context.request.post('https://localhost:7811/detectionCapture',{headers,data:Buffer.concat([upload,Buffer.from(' ')])});
    assert.equal(tampered.status(),401);
    result.tamperedBodyRejected=401;
    const ready=await context.request.get(base+`/eventList/detail/check?evId=${receipt.event_id}&dvId=1`);
    result.detailCheck={status:ready.status(),body:await ready.text()};
    assert.equal(ready.status(),200);
    await page.goto(base+`/eventList/eventListDetail?evId=${receipt.event_id}&dvId=1&dvAddr=`,{waitUntil:'networkidle'});
    await page.screenshot({path:path.join(output,'screenshots/capture-detail.png'),fullPage:true});
    result.detailImages=await page.locator('img').evaluateAll(imgs=>imgs.filter(i=>i.currentSrc.includes('/imgFile/')).map(i=>({loaded:i.complete&&i.naturalWidth>0,width:i.naturalWidth})));
    assert(result.detailImages.some(i=>i.loaded),'Saved capture must render through the Java detail view');
    const before=sql('SELECT COUNT(*) FROM tbl_detection_capture');
    const eventCount=sql('SELECT COUNT(*) FROM tbl_event_data');
    try {
      sql("CREATE TRIGGER h100_capture_test_reject BEFORE INSERT ON tbl_notification_log FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Local storage rollback test'");
      const rejected=await context.request.post(base+'/deviceList/detection/1',{headers:{'X-H100-CSRF':token},data:{request_id:crypto.randomUUID()},timeout:50000});
      assert.equal(rejected.status(),502);
      assert.equal(sql('SELECT COUNT(*) FROM tbl_detection_capture'),before);
      assert.equal(sql('SELECT COUNT(*) FROM tbl_event_data'),eventCount);
      result.databaseFailure={status:502,rolledBack:true};
    } finally {
      sql('DROP TRIGGER IF EXISTS h100_capture_test_reject');
    }
    try {
      execFileSync('docker',['stop','h100-local-camera-publisher-1','h100-local-rtsp-source-1']);
      const failed=await context.request.post(base+'/deviceList/detection/1',{headers:{'X-H100-CSRF':token},data:{request_id:crypto.randomUUID()},timeout:50000});
      assert.equal(failed.status(),502);
      assert.equal(sql('SELECT COUNT(*) FROM tbl_detection_capture'),before);
      result.cameraFailure={status:502,noSavedEvent:true};
    } finally {
      execFileSync('docker',['start','h100-local-rtsp-source-1','h100-local-camera-publisher-1']);
    }
  } catch(error) {
    result.fatal=error.message; process.exitCode=1;
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(output,'capture-result.json'),JSON.stringify(result,null,2));
    console.log(JSON.stringify(result,null,2));
  }
})();
