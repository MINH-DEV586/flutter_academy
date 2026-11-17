import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';

test('đăng ký, đăng nhập, đọc phiên và thu hồi token', async (t) => {
  const server = taoMayChu().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');

  const base = `http://127.0.0.1:${server.address().port}/api/account`;
  const post = (path, body) => fetch(`${base}/${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const session = (token, method = 'GET') => fetch(`${base}/session`, {
    method,
    headers: { Authorization: `Bearer ${token}` },
  });
  const taiKhoan = {
    email: 'Hoc@Example.test', hoTen: 'Người học', matKhau: 'mat-khau-kiem-thu',
  };

  const preflight = await fetch(`${base}/session`, {
    method: 'OPTIONS',
    headers: { Origin: 'http://localhost:8082' },
  });
  assert.equal(preflight.status, 204);
  assert.match(preflight.headers.get('access-control-allow-headers'), /Authorization/);
  assert.equal((await post('register', { ...taiKhoan, matKhau: 'ngan' })).status, 400);

  const registered = await post('register', taiKhoan);
  assert.equal(registered.status, 201);
  const { token, nguoiDung } = await registered.json();
  assert.match(token, /^[a-f0-9]{64}$/);
  assert.deepEqual(nguoiDung, { email: 'hoc@example.test', hoTen: 'Người học' });
  assert.deepEqual(await (await session(token)).json(), { nguoiDung });
  assert.equal((await post('register', taiKhoan)).status, 409);
  assert.equal((await post('login', { ...taiKhoan, matKhau: 'mat-khau-sai' })).status, 401);

  const loggedIn = await post('login', taiKhoan);
  assert.equal(loggedIn.status, 200);
  const phienMoi = await loggedIn.json();
  assert.notEqual(phienMoi.token, token);
  assert.equal((await session(token, 'DELETE')).status, 200);
  assert.equal((await session(token)).status, 401);
  assert.equal((await session(phienMoi.token)).status, 200);
});
