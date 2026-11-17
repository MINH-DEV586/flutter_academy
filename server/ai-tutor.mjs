import { createServer } from 'node:http';
import { existsSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const baiHoc = JSON.parse(
  readFileSync(new URL('../assets/bai_hoc_ai.json', import.meta.url), 'utf8'),
);
const mucDo = {
  coBan: 'Giải thích thuật ngữ bằng từ đơn giản và một ví dụ ngắn.',
  trungCap: 'Giải thích từng bước và đưa một lỗi thường gặp.',
  chuyenSau: 'Giải thích cơ chế và tình huống biên bằng ví dụ cụ thể.',
};
const originCucBo = /^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/;

async function docJson(request) {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of request.iterator({ destroyOnReturn: false })) {
    bytes += chunk.length;
    if (bytes > 8192) return null;
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function yeuCauAi(nhaCungCap, apiKey, model, instructions, input) {
  if (nhaCungCap === 'openrouter') {
    return {
      url: 'https://openrouter.ai/api/v1/chat/completions',
      headers: { Authorization: `Bearer ${apiKey}` },
      body: {
        model: model ?? 'openrouter/free',
        max_tokens: 1400,
        messages: [
          { role: 'system', content: instructions },
          { role: 'user', content: input },
        ],
      },
    };
  }
  if (nhaCungCap === 'gemini') {
    return {
      url: `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model ?? 'gemini-3.5-flash')}:generateContent`,
      headers: { 'x-goog-api-key': apiKey },
      body: {
        systemInstruction: { parts: [{ text: instructions }] },
        contents: [{ role: 'user', parts: [{ text: input }] }],
        generationConfig: { maxOutputTokens: 1400 },
      },
    };
  }
  return {
    url: 'https://api.openai.com/v1/responses',
    headers: { Authorization: `Bearer ${apiKey}` },
    body: {
      model: model ?? 'gpt-5.4-mini',
      store: false,
      max_output_tokens: 1400,
      instructions,
      input,
    },
  };
}

function layVanBan(nhaCungCap, ketQua) {
  if (nhaCungCap === 'openrouter') {
    const noiDung = ketQua.choices?.[0]?.message?.content;
    return typeof noiDung === 'string' ? noiDung.trim() : '';
  }
  if (nhaCungCap === 'gemini') {
    return ketQua.candidates?.[0]?.content?.parts
      ?.filter((muc) => !muc.thought && typeof muc.text === 'string')
      .map((muc) => muc.text).join('\n').trim();
  }
  return ketQua.output
    ?.filter((muc) => muc.type === 'message')
    .flatMap((muc) => muc.content)
    .filter((muc) => muc.type === 'output_text')
    .map((muc) => muc.text).join('\n').trim();
}

export function taoMayChu({
  apiKey, model, nhaCungCap = 'openai', goiApi = fetch,
} = {}) {
  let dangXuLy = 0;
  return createServer({ requestTimeout: 15_000 }, async (request, response) => {
    const tra = (status, body) => {
      response.writeHead(status, {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
      });
      response.end(JSON.stringify(body));
    };

    // Máy chủ demo chỉ nhận kết nối loopback và origin của Flutter Web local.
    if (!/^(?:127\.0\.0\.1|localhost)(?::\d+)?$/.test(request.headers.host ?? '')) {
      return tra(403, { loi: 'Host không hợp lệ.' });
    }
    const origin = request.headers.origin;
    if (origin) {
      if (!originCucBo.test(origin)) return tra(403, { loi: 'Origin không hợp lệ.' });
      response.setHeader('Access-Control-Allow-Origin', origin);
      response.setHeader('Vary', 'Origin');
    }
    if (request.url !== '/api/ai-tutor') return tra(404, { loi: 'Sai địa chỉ.' });
    if (request.method === 'OPTIONS') {
      response.writeHead(204, {
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
      return response.end();
    }
    if (request.method !== 'POST') return tra(405, { loi: 'Chỉ hỗ trợ POST.' });
    if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
      return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
    }

    let duLieu;
    try {
      duLieu = await docJson(request);
    } catch {
      return tra(400, { loi: 'JSON không hợp lệ.' });
    }
    const cauHoi = typeof duLieu?.cauHoi === 'string' ? duLieu.cauHoi.trim() : '';
    if (!cauHoi || [...cauHoi].length > 1000 ||
        typeof duLieu.baiHoc !== 'string' || typeof duLieu.mucDo !== 'string' ||
        !Object.hasOwn(mucDo, duLieu.mucDo)) {
      return tra(400, { loi: 'Câu hỏi hoặc mức giải thích không hợp lệ.' });
    }
    if (!Object.hasOwn(baiHoc, duLieu.baiHoc)) {
      return tra(404, { loi: 'Bài học chưa có tài liệu AI Tutor.' });
    }
    if (!apiKey) return tra(503, { loi: 'Máy chủ chưa cấu hình khóa API.' });
    if (dangXuLy >= 4) return tra(429, { loi: 'Máy chủ đang bận.' });

    const taiLieu = baiHoc[duLieu.baiHoc];
    dangXuLy++;
    try {
      const instructions = [
        'Bạn là gia sư lập trình. Trả lời bằng tiếng Việt rõ ràng.',
        'Giữ đúng ngôn ngữ lập trình và chủ đề được dùng trong bài.',
        'Dựa vào tài liệu của bài hiện tại và chỉ ra chi tiết liên quan.',
        'Nếu câu hỏi ngoài bài hoặc tài liệu không đủ, nói rõ điều đó.',
        'Không nói rằng bạn đã xem video hoặc đọc transcript.',
        'Dùng văn bản thuần. Xuống dòng cho ví dụ và các bước.',
        mucDo[duLieu.mucDo],
        `Bài học: ${taiLieu.tieuDe}\n${taiLieu.noiDung}\nVí dụ:\n${taiLieu.code}`,
      ].join('\n');
      const yeuCau = yeuCauAi(nhaCungCap, apiKey, model, instructions, cauHoi);
      const upstream = await goiApi(yeuCau.url, {
        method: 'POST',
        headers: { ...yeuCau.headers, 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(30_000),
        body: JSON.stringify(yeuCau.body),
      });
      if (!upstream.ok) {
        await upstream.body?.cancel();
        console.error(`AI Tutor (${nhaCungCap}): HTTP ${upstream.status}`);
        return tra(502, { loi: 'Dịch vụ AI chưa trả lời được.' });
      }
      const ketQua = await upstream.json();
      const cauTraLoi = layVanBan(nhaCungCap, ketQua);
      if (!cauTraLoi) return tra(502, { loi: 'Phản hồi AI trống.' });
      return tra(200, { cauTraLoi });
    } catch (loi) {
      const maLoi = loi.cause?.code ?? loi.name;
      console.error(`AI Tutor (${nhaCungCap}): ${maLoi}`);
      return tra(502, { loi: 'Không kết nối được dịch vụ AI.' });
    } finally {
      dangXuLy--;
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const envFile = new URL('../.env', import.meta.url);
  if (existsSync(envFile)) process.loadEnvFile(envFile);
  const port = Number(process.env.AI_TUTOR_PORT ?? 8787);
  const nhaCungCap = ['openrouter', 'gemini', 'openai'].find(
    (ten) => process.env[`${ten.toUpperCase()}_API_KEY`]?.trim(),
  ) ?? 'openai';
  const prefix = nhaCungCap.toUpperCase();
  taoMayChu({
    nhaCungCap,
    apiKey: process.env[`${prefix}_API_KEY`]?.trim(),
    model: process.env[`${prefix}_MODEL`]?.trim() || undefined,
  }).listen(port, '127.0.0.1', () => {
    console.log(`AI Tutor (${nhaCungCap}): http://127.0.0.1:${port}/api/ai-tutor`);
  });
}
