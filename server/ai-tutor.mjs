import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
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

export function taoMayChu({ apiKey, model = 'gpt-5.4-mini', goiApi = fetch } = {}) {
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
    if (!apiKey) return tra(503, { loi: 'Máy chủ chưa cấu hình OpenAI.' });
    if (dangXuLy >= 4) return tra(429, { loi: 'Máy chủ đang bận.' });

    const taiLieu = baiHoc[duLieu.baiHoc];
    dangXuLy++;
    try {
      const upstream = await goiApi('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(30_000),
        body: JSON.stringify({
          model,
          store: false,
          max_output_tokens: 1400,
          instructions: [
            'Bạn là gia sư Flutter. Trả lời bằng tiếng Việt rõ ràng.',
            'Dựa vào tài liệu của bài hiện tại và chỉ ra chi tiết liên quan.',
            'Nếu câu hỏi ngoài bài hoặc tài liệu không đủ, nói rõ điều đó.',
            'Không nói rằng bạn đã xem video hoặc đọc transcript.',
            'Dùng văn bản thuần. Xuống dòng cho ví dụ và các bước.',
            mucDo[duLieu.mucDo],
            `Bài học: ${taiLieu.tieuDe}\n${taiLieu.noiDung}\nVí dụ:\n${taiLieu.code}`,
          ].join('\n'),
          input: cauHoi,
        }),
      });
      if (!upstream.ok) {
        await upstream.body?.cancel();
        console.error(`OpenAI Responses API: HTTP ${upstream.status}`);
        return tra(502, { loi: 'Dịch vụ AI chưa trả lời được.' });
      }
      const ketQua = await upstream.json();
      const cauTraLoi = ketQua.output
        ?.filter((muc) => muc.type === 'message')
        .flatMap((muc) => muc.content)
        .filter((muc) => muc.type === 'output_text')
        .map((muc) => muc.text)
        .join('\n')
        .trim();
      if (!cauTraLoi) return tra(502, { loi: 'Phản hồi AI trống.' });
      return tra(200, { cauTraLoi });
    } catch {
      return tra(502, { loi: 'Không kết nối được dịch vụ AI.' });
    } finally {
      dangXuLy--;
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.AI_TUTOR_PORT ?? 8787);
  taoMayChu({
    apiKey: process.env.OPENAI_API_KEY,
    model: process.env.OPENAI_MODEL,
  }).listen(port, '127.0.0.1', () => {
    console.log(`AI Tutor: http://127.0.0.1:${port}/api/ai-tutor`);
  });
}
