import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { setImmediate } from 'node:timers/promises';
import { test } from 'node:test';
import { runInNewContext } from 'node:vm';

const script = readFileSync(new URL('./meta-vi.js', import.meta.url), 'utf8');

test('trang ký giữ thử thách khi MetaMask tải lại và xóa sau khi hết hạn', async () => {
  const cacLanMo = [];

  async function taiTrang(hash, httpStatus = 200) {
    const location = { hash, pathname: '/meta/vi', reload() {} };
    const confirm = { disabled: true, addEventListener() {} };
    const status = { textContent: '' };
    runInNewContext(script, {
      location, AbortSignal,
      history: { replaceState() { location.hash = ''; } },
      window: { ethereum: { isMetaMask: true }, addEventListener() {} },
      document: { getElementById: (id) => ({ confirm, status })[id] ?? {} },
      fetch: async (_, request) => {
        cacLanMo.push(JSON.parse(request.body));
        return new Response(JSON.stringify({ operation: 'link', loi: 'Phiên hết hạn' }), {
          status: httpStatus,
        });
      },
    });
    await setImmediate();
    return { location, confirm, status };
  }

  const dau = await taiTrang('#ma-thu-nghiem');
  assert.equal(dau.location.hash, '#ma-thu-nghiem');
  assert.equal(dau.confirm.disabled, false);
  assert.equal((await taiTrang(dau.location.hash)).confirm.disabled, false);
  const hetHan = await taiTrang(dau.location.hash, 410);
  assert.equal(hetHan.confirm.disabled, true);
  assert.equal(hetHan.location.hash, '');
  assert.equal(hetHan.status.textContent, 'Phiên hết hạn');
  assert.deepEqual(cacLanMo, Array(3).fill({ token: 'ma-thu-nghiem', action: 'open' }));
});
