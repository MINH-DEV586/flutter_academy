import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';

test('Hệ thống Pro: xem gói, mua gói bằng Coin, gia hạn, kiểm tra quyền', async (t) => {
  const server = taoMayChu().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');

  const base = `http://127.0.0.1:${server.address().port}/api`;
  const registerRes = await fetch(`${base}/account/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'pro-test@example.com',
      hoTen: 'Test Pro User',
      matKhau: 'password123456',
    }),
  });
  const { token } = await registerRes.json();

  // 1. Xem danh sách gói Pro
  const pkgRes = await fetch(`${base}/subscriptions/packages`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.equal(pkgRes.status, 200);
  const pkgData = await pkgRes.json();
  assert.equal(pkgData.packages.length, 3);
  assert.equal(pkgData.packages[0].id, 'pro_30');
  assert.equal(pkgData.packages[0].coinPrice, 100);

  // 2. Mua khi chưa đủ Coin -> Lỗi 400
  const buyFailRes = await fetch(`${base}/subscriptions/purchase`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ packageId: 'pro_30' }),
  });
  assert.equal(buyFailRes.status, 400);

  // 3. Nhận đủ Coin để mua (gọi claim-reward nhiều lần để tích lũy Coin test)
  for (let i = 1; i <= 10; i++) {
    await fetch(`${base}/wallet/claim-reward`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: 'quiz_complete',
        referenceId: `quiz_batch_${i}`,
      }),
    });
  }
  // 10 * 10 = 100 Coin
  const walletCheck = await (await fetch(`${base}/wallet`, {
    headers: { Authorization: `Bearer ${token}` },
  })).json();
  assert.equal(walletCheck.coinBalance, 100);

  // 4. Mua gói Pro 30 ngày thành công
  const buySuccessRes = await fetch(`${base}/subscriptions/purchase`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ packageId: 'pro_30' }),
  });
  assert.equal(buySuccessRes.status, 200);
  const buyData = await buySuccessRes.json();
  assert.equal(buyData.ok, true);
  assert.equal(buyData.coinDeducted, 100);
  assert.equal(buyData.newBalance, 0);

  // 5. Kiểm tra trạng thái Pro
  const meRes = await fetch(`${base}/subscriptions/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.equal(meRes.status, 200);
  const meData = await meRes.json();
  assert.equal(meData.isPro, true);
  assert.equal(meData.packageId, 'pro_30');
  assert.ok(new Date(meData.expiresAt) > new Date());

  // 6. Tài khoản PRO đăng ký khóa học PRO thành công (200)
  const enrollProRes = await fetch(`${base}/account/enrollments`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ maKhoaHoc: 'flutter-web3-blockchain' }),
  });
  assert.equal(enrollProRes.status, 200);

  // 7. Tạo tài khoản thường (FREE) -> đăng ký khóa học PRO bị từ chối 403
  const freeUserRes = await fetch(`${base}/account/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'free-user@example.com',
      hoTen: 'Free User',
      matKhau: 'password123456',
    }),
  });
  const { token: freeToken } = await freeUserRes.json();
  const enrollFreeFailRes = await fetch(`${base}/account/enrollments`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${freeToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ maKhoaHoc: 'flutter-web3-blockchain' }),
  });
  assert.equal(enrollFreeFailRes.status, 403);
  const failData = await enrollFreeFailRes.json();
  assert.match(failData.loi, /PRO/);

  // Tài khoản FREE đăng ký khóa học FREE vẫn thành công 200
  const enrollFreeOkRes = await fetch(`${base}/account/enrollments`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${freeToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ maKhoaHoc: 'python-co-ban' }),
  });
  assert.equal(enrollFreeOkRes.status, 200);
});
