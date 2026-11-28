import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';
import { ngayVietNam } from './ngay-viet-nam.mjs';

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

test('chỉ lưu một đăng ký cho mỗi khóa và từng tài khoản', async (t) => {
  const server = taoMayChu().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}/api/account`;
  const dangKy = async (email) => {
    const response = await fetch(`${base}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, hoTen: 'Người học', matKhau: 'mat-khau-kiem-thu' }),
    });
    assert.equal(response.status, 201);
    return (await response.json()).token;
  };
  const danhSach = (token) => fetch(`${base}/enrollments`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const ghiDanh = (token, maKhoaHoc) => fetch(`${base}/enrollments`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ maKhoaHoc }),
  });

  assert.equal((await ghiDanh('', 'python-co-ban')).status, 401);
  const a = await dangKy('a@example.test');
  const b = await dangKy('b@example.test');
  assert.deepEqual(await (await danhSach(a)).json(), { maKhoaHoc: [] });
  assert.equal((await ghiDanh(a, 'khoa-khong-ton-tai')).status, 404);
  assert.equal((await ghiDanh(a, 'python-co-ban')).status, 200);
  assert.equal((await ghiDanh(a, 'python-co-ban')).status, 200);
  assert.deepEqual(await (await danhSach(a)).json(), { maKhoaHoc: ['python-co-ban'] });
  assert.deepEqual(await (await danhSach(b)).json(), { maKhoaHoc: [] });
});

test('nhật ký demo đọc theo tài khoản, mỗi ngày và mỗi mốc chỉ có một bản', async (t) => {
  let bayGio = new Date('2026-11-20T17:05:00Z');
  const mayChu = taoMayChu({ dongHo: () => bayGio }).listen(0, '127.0.0.1');
  t.after(() => mayChu.close());
  await once(mayChu, 'listening');
  const goc = `http://127.0.0.1:${mayChu.address().port}/api`;
  async function gui(path, token, data) {
    return fetch(goc + path, {
      method: data ? 'POST' : 'GET',
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Type': 'application/json' } : {}),
      },
      body: data ? JSON.stringify(data) : undefined,
    });
  }
  async function dangKy(email) {
    const res = await gui('/account/register', null, {
      email, hoTen: 'Học viên thử', matKhau: 'mat-khau-kiem-thu',
    });
    assert.equal(res.status, 201);
    return (await res.json()).token;
  }
  const email = 'demo@example.com';
  const token = await dangKy(email);
  const tokenKhac = await dangKy('khac@example.test');
  const cacNgay = [];
  for (let i = 0; i < 6; i++) {
    const { ngay } = ngayVietNam(bayGio);
    cacNgay.push(ngay);
    const payload = {
      email, eventId: `video-demo-${ngay}-hoan-thanh`,
      lesson: 'flutter-nhap-mon/b1', from: false, to: true,
    };
    assert.equal((await gui('/rewards/complete', token, payload)).status, 200);
    assert.equal((await gui('/rewards/complete', token, payload)).status, 200);
    bayGio = new Date(bayGio.getTime() + 86_400_000);
  }
  assert.equal((await gui('/account/demo-learning')).status, 401);
  assert.deepEqual(await (await gui('/account/demo-learning', tokenKhac)).json(), { nhatKy: [] });
  const { nhatKy } = await (await gui('/account/demo-learning', token)).json();
  assert.deepEqual(nhatKy.map((nk) => nk.ngay), cacNgay);
  assert.equal(nhatKy.reduce((tong, nk) => tong + nk.xpNhanDuoc, 0), 120);
  assert.ok(nhatKy.every((nk) => nk.baiDaHoanThanh.length === 1));
  assert.deepEqual((await (await gui('/account/demo-learning', token)).json()).nhatKy, nhatKy);
  const { days, awards } = await (await gui('/rewards', token)).json();
  assert.equal(days, 6);
  assert.deepEqual(awards.map(({ milestone, amount }) => [milestone, amount]), [[3, 10]]);
});

test('lưu streak riêng theo từng tài khoản', async (t) => {
  const server = taoMayChu().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}/api/account`;
  const dangKy = async (email) => {
    const response = await fetch(`${base}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        hoTen: 'Người học',
        matKhau: 'mat-khau-kiem-thu',
      }),
    });
    assert.equal(response.status, 201);
    return (await response.json()).token;
  };
  const streak = (token, method = 'GET', body) => fetch(`${base}/streak`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });

  const tokenA = await dangKy(`streak-a-${Date.now()}@example.test`);
  const tokenB = await dangKy(`streak-b-${Date.now()}@example.test`);
  assert.equal((await streak('')).status, 401);
  assert.equal((await (await streak(tokenA)).json()).tonTai, false);

  const saved = await streak(tokenA, 'POST', {
    chuoiHienTai: 8,
    chuoiDaiNhat: 12,
    soKhiensFreeze: 2,
    tongXp: 480,
    ngayHocGanNhat: '2026-11-20',
    capHienTai: 4,
    mucTieuPhutMoiNgay: 20,
    danhSachHuyHieu: ['streak_7'],
    cacNgayFreezeDaDung: ['2026-11-19'],
  });
  assert.equal(saved.status, 200);
  assert.deepEqual(await (await streak(tokenA)).json(), {
    tonTai: true,
    chuoiHienTai: 8,
    chuoiDaiNhat: 12,
    soKhiensFreeze: 2,
    tongXp: 480,
    ngayHocGanNhat: '2026-11-20',
    capHienTai: 4,
    mucTieuPhutMoiNgay: 20,
    danhSachHuyHieu: ['streak_7'],
    cacNgayFreezeDaDung: ['2026-11-19'],
  });
  assert.equal((await (await streak(tokenB)).json()).tonTai, false);
});
