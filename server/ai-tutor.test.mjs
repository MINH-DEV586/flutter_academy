import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';

async function khoiDong(t, tuyChon) {
  const server = taoMayChu(tuyChon).listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  return `http://127.0.0.1:${server.address().port}/api/ai-tutor`;
}

function gui(url, duLieu, origin = 'http://localhost:8080') {
  return fetch(url, {
    method: 'POST',
    headers: { Origin: origin, 'Content-Type': 'application/json' },
    body: JSON.stringify(duLieu),
  });
}

const cauHoi = {
  baiHoc: 'dieu-huong-url/b2',
  cauHoi: 'Giải thích đoạn code trong bài.',
  mucDo: 'trungCap',
};

test('dùng đúng nội dung và mức giải thích trên máy chủ', async (t) => {
  const url = await khoiDong(t, {
    apiKey: 'test-key',
    goiApi: async (_, options) => {
      const payload = JSON.parse(options.body);
      assert.equal(payload.input, cauHoi.cauHoi);
      assert.equal(payload.store, false);
      assert.match(payload.instructions, /queryParameters/);
      assert.match(payload.instructions, /Giải thích từng bước/);
      assert.doesNotMatch(payload.instructions, /ShellRoute/);
      return Response.json({
        output: [
          { type: 'reasoning' },
          {
            type: 'message',
            content: [{ type: 'output_text', text: 'Tham số truy vấn nằm sau dấu ?.' }],
          },
        ],
      });
    },
  });
  const preflight = await fetch(url, {
    method: 'OPTIONS',
    headers: { Origin: 'http://localhost:8080' },
  });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('access-control-allow-origin'), 'http://localhost:8080');

  const response = await gui(url, cauHoi);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { cauTraLoi: 'Tham số truy vấn nằm sau dấu ?.' });
});

test('từ chối yêu cầu không hợp lệ trước khi gọi AI', async (t) => {
  let soLanGoi = 0;
  const url = await khoiDong(t, { apiKey: 'test-key', goiApi: () => soLanGoi++ });
  assert.equal((await gui(url, { ...cauHoi, cauHoi: ' '.repeat(10) })).status, 400);
  assert.equal((await gui(url, { ...cauHoi, mucDo: 'khong-hop-le' })).status, 400);
  assert.equal((await gui(url, { ...cauHoi, baiHoc: 'dieu-huong-url/b99' })).status, 404);
  assert.equal((await gui(url, cauHoi, 'https://example.invalid')).status, 403);
  assert.equal(soLanGoi, 0);
});

test('báo rõ khi chưa có khóa hoặc phản hồi AI trống', async (t) => {
  const chuaCauHinh = await khoiDong(t);
  assert.equal((await gui(chuaCauHinh, cauHoi)).status, 503);
  const phanHoiTrong = await khoiDong(t, {
    apiKey: 'test-key',
    goiApi: async () => Response.json({ output: [] }),
  });
  assert.equal((await gui(phanHoiTrong, cauHoi)).status, 502);
});
