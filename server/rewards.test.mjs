import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';

test('tính ngày Việt Nam, thưởng đúng mốc, xác minh Hardhat và áp dụng hạn mức Pro', async (t) => {
  let now = Date.parse('2026-11-16T16:59:00Z');
  let tx;
  let receipt;
  const hash = '0x' + '1'.repeat(64);
  const wallet = '0x' + '2'.repeat(40);
  const server = taoMayChu({
    apiKey: 'test',
    goiApi: async () => Response.json({
      output: [{ type: 'message', content: [{ type: 'output_text', text: 'Đáp án' }] }],
    }),
    rewardsOptions: {
      gio: () => now,
      rpc: async (method) => ({
        eth_chainId: '0x7a69',
        eth_getTransactionByHash: tx,
        eth_getTransactionReceipt: receipt,
      })[method],
    },
  }).listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}/api`;
  const post = (path, body, token) => fetch(base + path, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
  const registered = await post('/account/register', {
    email: 'reward@example.test', hoTen: 'Người học', matKhau: 'mat-khau-kiem-thu',
  });
  assert.equal(registered.status, 201);
  const { token } = await registered.json();
  const baiHoc = 'python-co-ban/b1';
  const hoanThanh = async () => {
    const response = await post('/account/rewards/complete', { baiHoc }, token);
    assert.equal(response.status, 200);
    return response.json();
  };
  assert.equal((await post('/account/rewards/complete', { baiHoc })).status, 401);
  assert.equal((await hoanThanh()).chuoi, 1);
  assert.equal((await hoanThanh()).chuoi, 1);
  now += 60_000;
  assert.equal((await hoanThanh()).chuoi, 2);
  for (let ngay = 3; ngay <= 7; ngay++) {
    now += 86_400_000;
    const data = await hoanThanh();
    assert.equal(data.chuoi, ngay);
    assert.equal(data.thuong, ngay === 3 ? 10 : ngay === 7 ? 20 : 0);
  }
  assert.equal((await hoanThanh()).xu, 30);
  now += 2 * 86_400_000;
  assert.equal((await hoanThanh()).chuoi, 1);

  const hoi = { baiHoc, mucDo: 'coBan', cauHoi: 'Biến là gì?' };
  for (let i = 0; i < 10; i++) assert.equal((await post('/ai-tutor', hoi, token)).status, 200);
  assert.equal((await post('/ai-tutor', hoi, token)).status, 429);

  const { payload } = await (await post('/account/rewards/redeem', { vi: wallet }, token)).json();
  const confirm = () => post('/account/rewards/confirm', { hash }, token);
  assert.equal((await confirm()).status, 409);
  tx = { hash, input: payload, from: wallet, to: wallet, value: '0x1' };
  receipt = { status: '0x1', transactionHash: hash };
  assert.equal((await confirm()).status, 400);
  tx.value = '0x0';
  const pro = await (await confirm()).json();
  assert.equal(pro.xu, 0);
  assert.equal(pro.pro, true);
  assert.equal(pro.proDen, now + 7 * 86_400_000);
  assert.equal(pro.gioiHanAi, 50);
  assert.equal((await post('/ai-tutor', hoi, token)).status, 200);
  assert.equal((await (await confirm()).json()).proDen, pro.proDen);
  now = pro.proDen;
  const hetHan = await (await confirm()).json();
  assert.equal(hetHan.pro, false);
  assert.equal(hetHan.gioiHanAi, 10);
});
