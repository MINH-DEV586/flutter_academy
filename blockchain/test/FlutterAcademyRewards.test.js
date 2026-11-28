const assert = require('node:assert/strict');
const { once } = require('node:events');
const { mkdtempSync, rmSync } = require('node:fs');
const { createServer } = require('node:http');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { expect } = require('chai');
const { ethers, network } = require('hardhat');

describe('FlutterAcademyRewards', function () {
  it('chỉ chủ hợp đồng cấp, ví tự tiêu và mỗi mã chỉ dùng một lần', async () => {
    const [, user, other] = await ethers.getSigners();
    const rewards = await ethers.deployContract('FlutterAcademyRewards');
    const id = ethers.id('day-3');
    await expect(rewards.connect(user).issue(id, user.address, 10)).to.be.revertedWith('Issuer only');
    await rewards.issue(id, user.address, 10);
    await expect(rewards.issue(id, user.address, 10)).to.be.revertedWith('Reward already issued');
    await expect(rewards.connect(user).redeem(id)).to.be.revertedWith('Insufficient reward balance');
    await rewards.issue(ethers.id('day-7'), user.address, 20);
    await expect(rewards.connect(other).redeem(id)).to.be.revertedWith('Insufficient reward balance');
    const requestId = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(['address', 'bytes32'], [user.address, id]));
    await expect(rewards.connect(user).redeem(id)).to.emit(rewards, 'ProRedeemed')
      .withArgs(requestId, user.address, ethers.id('pro_7'), 30);
    await expect(rewards.connect(user).redeem(id)).to.be.revertedWith('Request already redeemed');
    expect(await rewards.balanceOf(user.address)).to.equal(0);
  });

  it('đối soát ngày 7 và cấp đúng một lần sau khi mất hash và khởi động lại', async function () {
    this.timeout(35_000);
    const { taoMayChu } = await import('../../server/ai-tutor.mjs');
    const [, user, other] = await ethers.getSigners();
    const contract = await ethers.deployContract('FlutterAcademyRewards');
    const rpc = createServer(async (request, response) => {
      const chunks = [];
      for await (const chunk of request) chunks.push(chunk);
      const { id, method, params } = JSON.parse(Buffer.concat(chunks));
      try {
        const result = await network.provider.send(method, params);
        response.end(JSON.stringify({ jsonrpc: '2.0', id, result }));
      } catch (error) {
        response.end(JSON.stringify({ jsonrpc: '2.0', id, error: { code: -32000, message: error.message } }));
      }
    }).listen(0, '127.0.0.1');
    await once(rpc, 'listening');
    const temp = mkdtempSync(join(tmpdir(), 'flutter-academy-rewards-'));
    let now = new Date('2026-11-01T02:00:00Z');
    let backend;
    let goc;
    let token;
    async function start() {
      backend = taoMayChu({
        accountDb: join(temp, 'test.sqlite'),
        dongHo: () => now,
        tutorFree: 1,
        tutorPro: 3,
        thuongBlockchain: { address: await contract.getAddress(), rpcUrl: `http://127.0.0.1:${rpc.address().port}` },
      }).listen(0, '127.0.0.1');
      await once(backend, 'listening');
      goc = `http://127.0.0.1:${backend.address().port}`;
    }
    async function goi(path, body, expected = 200) {
      const response = await fetch(goc + path, {
        method: body ? 'POST' : 'GET',
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body ? JSON.stringify(body) : undefined,
      });
      const ketQua = await response.json();
      assert.equal(response.status, expected, JSON.stringify(ketQua));
      return ketQua;
    }
    const duaNgay = (ngay) => {
      now = new Date(Date.UTC(2026, 10, ngay, 2));
      return goi('/api/rewards/complete', {
        email: 'demo@example.test', eventId: 'demo-streak-event-000' + ngay,
        lesson: 'flutter-nhap-mon/b1', from: false, to: true,
      });
    };
    const phien = (path, action, body = {}, status = 200) =>
      goi('/meta/vi/session', { token: path.split('#')[1], action, ...body }, status);
    try {
      await start();
      token = (await goi('/api/account/register', {
        email: 'demo@example.test', hoTen: 'Demo', matKhau: 'mat-khau-kiem-thu',
      }, 201)).token;
      for (let ngay = 1; ngay <= 6; ngay++) await duaNgay(ngay);
      const mocBa = (await goi('/api/rewards')).awards[0];
      assert.equal(mocBa.status, 'pending');
      await goi('/api/rewards/claim', { awardId: mocBa.id }, 409);
      const expired = (await goi('/api/rewards/link', {}, 201)).path;
      now = new Date(now.getTime() + 10 * 60_000);
      await phien(expired, 'open', {}, 410);
      const link = (await goi('/api/rewards/link', {}, 201)).path;
      const { message } = await phien(link, 'open');
      await phien(link, 'signed', { address: user.address, signature: await other.signMessage(message) }, 400);
      await phien(link, 'signed', { address: user.address, signature: await user.signMessage(message) });
      await phien(link, 'open', {}, 410);
      const walletState = (await goi('/api/rewards')).onChain;
      assert.equal(walletState.balance, 0);
      assert.equal(walletState.chainId, 31337);
      const daNhanMocBa = await goi('/api/rewards/claim', { awardId: mocBa.id });
      assert.equal(daNhanMocBa.onChain.balance, 10);
      assert.equal(daNhanMocBa.awards[0].status, 'issued');
      const truocKhiNgat = (await goi('/api/rewards/link', {}, 409)).loi;
      assert.match(truocKhiNgat, /đã kết nối/);
      await goi('/api/rewards/disconnect', {});
      const daNgat = (await goi('/api/rewards')).onChain;
      assert.equal(daNgat.connected, false);
      assert.equal(daNgat.balance, 10);
      await goi('/api/rewards/redeem', {}, 409);
      const ketNoiLai = (await goi('/api/rewards/link', {}, 201)).path;
      const thuThachMoi = (await phien(ketNoiLai, 'open')).message;
      await phien(ketNoiLai, 'signed',
        { address: other.address, signature: await other.signMessage(thuThachMoi) }, 409);
      await phien(ketNoiLai, 'signed',
        { address: user.address, signature: await user.signMessage(thuThachMoi) });
      assert.equal((await goi('/api/rewards')).onChain.connected, true);
      await duaNgay(7);
      const chuaNhan = await goi('/api/rewards');
      assert.equal(chuaNhan.onChain.balance, 10);
      const mocBay = chuaNhan.awards.find((muc) => muc.milestone === 7);
      assert.equal(mocBay.status, 'pending');
      await Promise.all([
        goi('/api/rewards/claim', { awardId: mocBay.id }),
        goi('/api/rewards/claim', { awardId: mocBay.id }),
      ]);
      assert.equal((await goi('/api/rewards')).onChain.balance, 30);
      const soMint = await contract.queryFilter(contract.filters.RewardIssued(null, user.address));
      assert.equal(soMint.length, 2);
      const first = (await goi('/api/rewards/redeem', {}, 201)).path;
      await phien(first, 'result', { status: 'rejected' });
      assert.equal((await goi('/api/rewards')).onChain.redemption.status, 'rejected');
      const retry = (await goi('/api/rewards/redeem', {}, 201)).path;
      const { to, data } = await phien(retry, 'open');
      await phien(retry, 'signed', { txHash: ethers.id('hash-khong-con-tren-rpc') });
      assert.equal((await goi('/api/rewards')).onChain.redemption.status, 'failed');
      const recovered = (await goi('/api/rewards/redeem', {}, 201)).path;
      assert.equal((await phien(recovered, 'open')).data, data);
      const tx = await user.sendTransaction({ to, data });
      await tx.wait();
      await new Promise((resolve) => backend.close(resolve));
      await start();
      const ketQua = await Promise.all([goi('/api/rewards'), goi('/api/rewards')]);
      const [a, b] = ketQua.map((kq) => kq.onChain);
      assert.equal(a.balance, 0);
      assert.equal(a.redemption.status, 'completed');
      assert.equal(a.redemption.txHash, tx.hash);
      assert.deepEqual(a.redemption, b.redemption);
      assert.equal(a.redemption.expiresAt, '2026-11-14T02:00:00.000Z');
      assert.equal((await goi('/api/subscriptions/check-pro')).isPro, true);
      const hoi = { baiHoc: 'flutter-nhap-mon/b1', mucDo: 'coBan', cauHoi: 'Giải thích code' };
      for (let i = 0; i < 3; i++) await goi('/api/ai-tutor', hoi);
      await goi('/api/ai-tutor', hoi, 429);
      now = new Date('2026-11-14T02:00:00.000Z');
      assert.equal((await goi('/api/subscriptions/check-pro')).isPro, false);
      await goi('/api/ai-tutor', hoi);
      await goi('/api/ai-tutor', hoi, 429);
    } finally {
      if (backend?.listening) await new Promise((resolve) => backend.close(resolve));
      await new Promise((resolve) => rpc.close(resolve));
      rmSync(temp, { recursive: true, force: true });
    }
  });
});
