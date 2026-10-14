// Run with Node and @playwright/test available (NODE_PATH may point at global npm modules).
const { chromium } = require('@playwright/test');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const output = path.join(root, 'tmp/docker-setup/screenshots');
fs.mkdirSync(output, { recursive: true });
const base = process.env.H100_TEST_URL || 'http://localhost:7810';
const credentials = fs.readFileSync(path.join(root, 'ops/local/first-login.txt'), 'utf8');
const username = credentials.match(/^User: (.+)$/m)[1].trim();
const password = credentials.match(/^Password: (.+)$/m)[1].trim();
const result = { base, pages: [], api: [], errors: [], failures: [], map: null };
const routes = [
  ['dashboard', '/dashboard'],
  ['events', '/eventList/viewEventList.do'],
  ['statistics', '/stats/viewStat.do'],
  ['devices', '/deviceList/viewDeviceList.do'],
  ['sip', '/sipcall/sipCallLog'],
];
function safeUrl(url) { return url.split('?')[0]; }
(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const context = await browser.newContext({ viewport: { width: 1600, height: 1000 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    page.on('pageerror', e => result.errors.push(e.message));
    page.on('requestfailed', r => result.failures.push({ url: safeUrl(r.url()), error: r.failure()?.errorText }));
    page.on('response', r => { if (r.status() >= 400) result.failures.push({url: safeUrl(r.url()), status: r.status()}); });
    await page.goto(base + '/user/login.do');
    await page.screenshot({ path: path.join(output, 'login.png'), fullPage: true });
    const login = await context.request.post(base + '/user/login', { data: { id: username, pwd: password } });
    const loginBody = await login.json();
    assert.equal(loginBody.ok, true, 'Local login must succeed');
    result.login = { status: login.status(), ok: loginBody.ok };
    for (const [name, route] of routes) {
      const response = await page.goto(base + route, { waitUntil: 'networkidle', timeout: 60000 });
      await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
      result.pages.push({ name, route, status: response.status(), title: await page.title(), url: safeUrl(page.url()), overflow: await page.evaluate(() => document.documentElement.scrollWidth > innerWidth) });
      assert.equal(response.status(), 200, route);
      assert(!page.url().includes('/user/login'), route + ' redirected to login');
      if (name === 'dashboard') {
        result.map = await page.evaluate(() => ({ sdk: !!window.kakao?.maps?.Map, tiles: document.querySelectorAll('#map img').length, width: document.querySelector('#map')?.clientWidth }));
      }
    }
    for (const route of ['/dashboard/deviceMapList','/dashboard/todaySummary','/dashboard/deviceStatusSummary','/dashboard/recentEvents','/dashboard/recentSipCalls']) {
      const response = await context.request.get(base + route, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
      assert.equal(response.status(), 200, route);
      result.api.push({ route, status: response.status(), data: await response.json() });
    }
    const guest = await browser.newContext();
    const unauthorized = await guest.request.get(base + '/dashboard/deviceMapList', { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
    assert.equal(unauthorized.status(), 401);
    result.unauthenticatedStatus = unauthorized.status();
    await guest.close();
    await page.setViewportSize({width: 390, height: 844});
    await page.goto(base + '/dashboard', {waitUntil: 'networkidle'});
    await page.screenshot({path: path.join(output, 'dashboard-mobile.png'), fullPage: true});
    result.mobileOverflow = await page.evaluate(() => ({viewport:innerWidth, document:document.documentElement.scrollWidth}));
  } catch (error) {
    result.fatal = error.message;
    process.exitCode = 1;
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(root, 'tmp/docker-setup/browser-result.json'), JSON.stringify(result, null, 2));
    console.log(JSON.stringify(result, null, 2));
  }
})();
