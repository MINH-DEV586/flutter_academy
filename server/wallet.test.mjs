import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';

test('Hệ thống Ví Coin: số dư ban đầu, nhận thưởng, chống nhận trùng', async (t) => {
  const server = taoMayChu().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');

  const base = `http://127.0.0.1:${server.address().port}/api`;
  const registerRes = await fetch(`${base}/account/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'wallet-test@example.com',
      hoTen: 'Test Wallet',
      matKhau: 'password123456',
    }),
  });
  assert.equal(registerRes.status, 201);
  const { token } = await registerRes.json();

  // 1. Kiểm tra ví ban đầu
  const walletRes = await fetch(`${base}/wallet`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.equal(walletRes.status, 200);
  const walletData = await walletRes.json();
  assert.equal(walletData.coinBalance, 0);
  assert.equal(walletData.metamaskAddress, null);

  // 2. Liên kết địa chỉ MetaMask
  const linkRes = await fetch(`${base}/wallet/metamask`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      address: '0x1234567890123456789012345678901234567890',
    }),
  });
  assert.equal(linkRes.status, 200);
  const linkData = await linkRes.json();
  assert.equal(linkData.ok, true);

  // 3. Nhận thưởng hoàn thành bài học (+5 Coin)
  const rewardRes = await fetch(`${base}/wallet/claim-reward`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'lesson_complete',
      referenceId: 'lesson_flutter_intro_01',
      description: 'Hoàn thành bài nhập môn Flutter',
    }),
  });
  assert.equal(rewardRes.status, 200);
  const rewardData = await rewardRes.json();
  assert.equal(rewardData.coinNhan, 5);
  assert.equal(rewardData.soDuMoi, 5);

  // 4. Chống nhận thưởng trùng cho cùng referenceId
  const rewardDupRes = await fetch(`${base}/wallet/claim-reward`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      type: 'lesson_complete',
      referenceId: 'lesson_flutter_intro_01',
    }),
  });
  assert.equal(rewardDupRes.status, 409);

  // 5. Kiểm tra lịch sử giao dịch
  const txRes = await fetch(`${base}/wallet/transactions`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.equal(txRes.status, 200);
  const txData = await txRes.json();
  assert.equal(txData.transactions.length, 1);
  assert.equal(txData.transactions[0].type, 'REWARD');
  assert.equal(txData.transactions[0].amount, 5);
  assert.equal(txData.transactions[0].balanceAfter, 5);

  // 6. Tạo đơn nạp Coin
  const depositOrderRes = await fetch(`${base}/wallet/deposits`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      packageId: 'pkg_50',
      walletAddress: '0x1234567890123456789012345678901234567890',
    }),
  });
  assert.equal(depositOrderRes.status, 201);
  const orderData = await depositOrderRes.json();
  assert.ok(orderData.orderId);
  assert.equal(orderData.coinAmount, 50);
  assert.equal(orderData.ethAmount, '0.005');
});
