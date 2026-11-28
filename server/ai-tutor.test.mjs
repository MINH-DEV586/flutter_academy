import assert from 'node:assert/strict';
import { EventEmitter, once } from 'node:events';
import { test } from 'node:test';
import { taoMayChu } from './ai-tutor.mjs';
import { phatTutor } from './tutor-stream.mjs';

async function khoiDong(t, tuyChon) {
  const server = taoMayChu(tuyChon).listen(0, '127.0.0.1');
  t.after(() => server.close());
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(base + '/api/account/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'tutor@example.test', hoTen: 'Người học', matKhau: 'mat-khau-kiem-thu' }),
  });
  assert.equal(response.status, 201);
  return { url: base + '/api/ai-tutor', token: (await response.json()).token };
}

function gui({ url, token }, duLieu, origin = 'http://localhost:8080', stream = false) {
  return fetch(url, {
    method: 'POST',
    headers: {
      Origin: origin, 'Content-Type': 'application/json', Authorization: `Bearer ${token}`,
      Accept: stream ? 'application/x-ndjson' : 'application/json',
    },
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
  const preflight = await fetch(url.url, {
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

test('Gemini nhận tài liệu bài học và trả nội dung hiển thị', async (t) => {
  const url = await khoiDong(t, {
    nhaCungCap: 'gemini',
    apiKey: 'test-key',
    goiApi: async (diaChi, options) => {
      assert.equal(diaChi,
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent');
      assert.equal(options.headers['x-goog-api-key'], 'test-key');
      const payload = JSON.parse(options.body);
      assert.match(payload.systemInstruction.parts[0].text, /queryParameters/);
      assert.equal(payload.contents[0].parts[0].text, cauHoi.cauHoi);
      assert.equal(payload.generationConfig.maxOutputTokens, 4096);
      return Response.json({
        candidates: [{ content: { parts: [
          { thought: true, text: 'Suy luận nội bộ' },
          { text: 'Dùng queryParameters để đọc bộ lọc.' },
        ] } }],
      });
    },
  });
  const response = await gui(url, cauHoi);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    cauTraLoi: 'Dùng queryParameters để đọc bộ lọc.',
  });
});

test('OpenRouter nhận tài liệu bài hiện tại và trả nội dung chat', async (t) => {
  const url = await khoiDong(t, {
    nhaCungCap: 'openrouter',
    apiKey: 'test-key',
    goiApi: async (diaChi, options) => {
      assert.equal(diaChi, 'https://openrouter.ai/api/v1/chat/completions');
      assert.equal(options.headers.Authorization, 'Bearer test-key');
      const payload = JSON.parse(options.body);
      assert.equal(payload.model, 'openrouter/free');
      assert.equal(payload.messages[0].role, 'system');
      assert.match(payload.messages[0].content, /queryParameters/);
      assert.deepEqual(payload.messages[1], { role: 'user', content: cauHoi.cauHoi });
      return Response.json({
        choices: [{ message: { content: 'Dùng queryParameters để đọc bộ lọc.' } }],
      });
    },
  });
  const response = await gui(url, cauHoi);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    cauTraLoi: 'Dùng queryParameters để đọc bộ lọc.',
  });
});

test('báo rõ khi phản hồi AI trống', async (t) => {
  const phanHoiTrong = await khoiDong(t, {
    apiKey: 'test-key',
    goiApi: async () => Response.json({ output: [] }),
  });
  assert.equal((await gui(phanHoiTrong, cauHoi)).status, 502);
});

test('Demo streaming có các phần, nguồn mở được, quiz và quota theo ngày Việt Nam', async (t) => {
  let gio = new Date('2026-11-23T16:59:59Z');
  const server = await khoiDong(t, { tutorFree: 1, dongHo: () => gio });
  const anonymous = await gui({ ...server, token: '' }, cauHoi);
  assert.equal(anonymous.status, 401);
  const response = await gui(server, cauHoi, undefined, true);
  assert.equal(response.status, 200);
  const events = (await response.text()).trim().split('\n').map(JSON.parse);
  assert.deepEqual(events.map((event) => event.loai), ['batDau', 'phan', 'phan', 'phan', 'xong']);
  assert.equal(events[0].demo, true);
  assert.equal(events[0].remaining, 0);
  assert.match(events[3].text, /queryParameters/);
  const { nguon, quiz } = events.at(-1);
  assert.equal(quiz.luaChon[quiz.dung], quiz.giaiThich);
  const trang = await fetch(new URL(nguon.duongDan, server.url));
  assert.equal(trang.status, 200);
  assert.match(await trang.text(), /Trang 2.*queryParameters/s);
  const hetLuot = await gui(server, cauHoi, undefined, true);
  assert.equal(hetLuot.status, 429);
  assert.equal((await hetLuot.json()).resetAt, '2026-11-23T17:00:00.000Z');
  gio = new Date('2026-11-23T17:00:00Z');
  assert.equal((await gui(server, cauHoi, undefined, true)).status, 200);
});

test('chuyển SSE nhà cung cấp thành từng phần và báo khi upstream ngắt', async (t) => {
  let hoanTat = true;
  const server = await khoiDong(t, {
    apiKey: 'test-key',
    goiApi: async (_, options) => {
      assert.equal(JSON.parse(options.body).stream, true);
      return new Response(
        'data: {"type":"response.output_text.delta","delta":"Đoạn 1"}\n\n' +
        'data: {"type":"response.output_text.delta","delta":" và đoạn 2"}\n\n' +
        (hoanTat ? 'data: {"type":"response.completed"}\n\n' : ''),
      );
    },
  });
  const goi = () => gui(server, cauHoi, undefined, true);
  assert.match(await (await goi()).text(), /Đoạn 1.*và đoạn 2.*"loai":"xong"/s);
  hoanTat = false;
  assert.match(await (await goi()).text(), /Đoạn 1.*"loai":"loi"/s);
});

function thuChoGemini(goiApi) {
  const suKien = [];
  const response = new EventEmitter();
  response.writeHead = () => {};
  response.write = (line) => suKien.push(JSON.parse(line));
  response.end = () => {};
  const xong = phatTutor({
    response, nhaCungCap: 'gemini', goiApi,
    yeuCau: { url: 'https://example.test', body: {} },
    moRong: { nguon: { trang: 2 } },
  });
  return { suKien, response, xong };
}

test('Gemini chờ quá 15 giây, giữ kết nối và vẫn hoàn tất khi có SSE', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const live = thuChoGemini((_, { signal }) => new Promise((resolve, reject) => {
    signal.addEventListener('abort', () => reject(signal.reason), { once: true });
    setTimeout(() => resolve(new Response(
      'data: {"candidates":[{"content":{"parts":[{"thought":true,"text":"ẩn"}]}}]}\n\n' +
      'data: {"candidates":[{"content":{"parts":[{"text":"Giải thích"}]},"finishReason":"STOP"}]}\n\n',
    )), 19_500);
  }));
  t.mock.timers.tick(19_500);
  await live.xong;
  assert.deepEqual(live.suKien.map((e) => e.loai), ['batDau', 'cho', 'phan', 'xong']);
  assert.equal(live.suKien[2].text, 'Giải thích');
  t.mock.timers.tick(35_000);
  assert.equal(live.suKien.length, 4);
});

test('Gemini không có phản hồi đầu sẽ bị hủy sau 35 giây', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const live = thuChoGemini((_, { signal }) => new Promise((_, reject) => {
    signal.addEventListener('abort', () => reject(signal.reason), { once: true });
  }));
  t.mock.timers.tick(34_999);
  assert.equal(live.suKien.some((e) => e.loai === 'loi'), false);
  t.mock.timers.tick(1);
  await live.xong;
  assert.match(live.suKien.at(-1).loi, /quá thời gian chờ/);
  assert.equal(live.response.listenerCount('close'), 0);
});

test('Gemini trả 503 thì báo bận và không trả chi tiết upstream cho app', async () => {
  const live = thuChoGemini(async () => new Response('Lỗi nội bộ nhà cung cấp', {
    status: 503,
  }));
  await live.xong;
  assert.deepEqual(live.suKien.map((e) => e.loai), ['batDau', 'loi']);
  assert.match(live.suKien.at(-1).loi, /đang bận.*thử lại/);
  assert.equal(live.response.listenerCount('close'), 0);
});
