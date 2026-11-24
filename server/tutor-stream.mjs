import { setTimeout as doi } from 'node:timers/promises';
import { ngayVietNam } from './ngay-viet-nam.mjs';

export function taoHanMuc(db, dongHo, free = 5, pro = 30) {
  db.exec(`CREATE TABLE IF NOT EXISTS tutor_usage (
    email TEXT NOT NULL, day TEXT NOT NULL, used INTEGER NOT NULL,
    PRIMARY KEY (email, day)
  ) STRICT`);
  const them = db.prepare(`
    INSERT INTO tutor_usage VALUES (?, ?, 1)
    ON CONFLICT(email, day) DO UPDATE SET used = used + 1 WHERE used < ?
    RETURNING used`);
  const doc = db.prepare('SELECT used FROM tutor_usage WHERE email = ? AND day = ?');
  return (email, laPro) => {
    const { ngay, resetAt } = ngayVietNam(dongHo());
    const limit = laPro ? pro : free;
    const ketQua = them.get(email, ngay, limit);
    const used = ketQua?.used ?? doc.get(email, ngay)?.used ?? 0;
    return { duocHoi: !!ketQua, limit, remaining: Math.max(0, limit - used), resetAt };
  };
}

export function taoTaiLieuTutor(baiHoc) {
  const danhMuc = Object.entries(baiHoc);
  const trangTheoKhoa = new Map();
  return new Map(danhMuc.map(([ma, bai]) => {
    const khoa = ma.split('/')[0];
    const trang = (trangTheoKhoa.get(khoa) ?? 0) + 1;
    trangTheoKhoa.set(khoa, trang);
    const dapAnSai = danhMuc
      .filter(([maKhac, baiKhac]) => maKhac !== ma && baiKhac.noiDung !== bai.noiDung)
      .sort(([a], [b]) => Number(b.startsWith(khoa + '/')) - Number(a.startsWith(khoa + '/')))
      .map(([, muc]) => muc.noiDung);
    const luaChon = [...new Set(dapAnSai)].slice(0, 2);
    const dung = (trang - 1) % 3;
    luaChon.splice(dung, 0, bai.noiDung);
    return [ma, {
      nguon: { ten: bai.tieuDe, trang, duongDan: '/tai-lieu/' + ma },
      quiz: {
        cauHoi: `Nhận định nào mô tả đúng nội dung của bài “${bai.tieuDe}”?`,
        luaChon, dung, giaiThich: bai.noiDung,
      },
    }];
  }));
}

export function htmlTaiLieu(bai, nguon) {
  const html = (s) => s.replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);
  return `<!doctype html><html lang="vi"><meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${html(nguon.ten)} · Flutter Academy</title>
  <style>body{margin:2rem auto;padding:0 1rem;max-width:45rem;font:1rem/1.6 system-ui;color:#182525}
  pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#edf4f4;padding:1rem;border-radius:.5rem}</style>
  <main><p>Flutter Academy · Tài liệu bài học · Trang ${nguon.trang}</p>
  <h1>${html(nguon.ten)}</h1><p>${html(bai.noiDung)}</p><pre><code>${html(bai.code)}</code></pre></main></html>`;
}

async function* docSse(body) {
  const decoder = new TextDecoder();
  let buffer = '';
  let data = [];
  for await (const chunk of body) {
    buffer += decoder.decode(chunk, { stream: true });
    let xuongDong;
    while ((xuongDong = buffer.indexOf('\n')) !== -1) {
      const dong = buffer.slice(0, xuongDong).replace(/\r$/, '');
      buffer = buffer.slice(xuongDong + 1);
      if (dong.startsWith('data:')) data.push(dong.slice(5).trimStart());
      if (!dong && data.length) {
        yield data.join('\n');
        data = [];
      }
    }
  }
}

async function* trichSse(upstream, nhaCungCap) {
  for await (const dong of docSse(upstream.body)) {
    if (nhaCungCap === 'openrouter' && dong === '[DONE]') return;
    const json = JSON.parse(dong);
    if (json.error || ['error', 'response.failed', 'response.incomplete'].includes(json.type)) {
      throw new Error('Upstream báo lỗi.');
    }
    if (nhaCungCap === 'gemini') {
      const ungVien = json.candidates?.[0];
      for (const phan of ungVien?.content?.parts ?? []) {
        if (!phan.thought && typeof phan.text === 'string') yield phan.text;
      }
      if (ungVien?.finishReason === 'STOP') return;
      if (ungVien?.finishReason) throw new Error('Gemini đã dừng giữa câu trả lời.');
    } else if (nhaCungCap === 'openrouter') {
      const luaChon = json.choices?.[0];
      if (typeof luaChon?.delta?.content === 'string') yield luaChon.delta.content;
      if (luaChon?.finish_reason && luaChon.finish_reason !== 'stop') {
        throw new Error('OpenRouter đã dừng giữa câu trả lời.');
      }
    } else {
      if (json.type === 'response.output_text.delta') yield json.delta;
      if (json.type === 'response.completed') return;
    }
  }
  throw new Error('Dịch vụ AI ngắt kết nối trước khi hoàn tất.');
}

function demo(bai, mucDo) {
  const moDau = {
    coBan: 'Hãy bắt đầu từ ý chính của bài.',
    trungCap: 'Đọc ý chính trước, sau đó đối chiếu từng bước với ví dụ.',
    chuyenSau: 'Đối chiếu cơ chế trong bài với ví dụ, rồi thay đổi đầu vào hoặc điều kiện để kiểm tra hành vi.',
  };
  return [moDau[mucDo] + '\n\n', bai.noiDung + '\n\n', 'Ví dụ trong bài\n' + bai.code];
}

export async function phatTutor({
  response, nhaCungCap, goiApi, yeuCau, bai, duLieu, moRong, hanMuc,
}) {
  const laGeminiLive = !!yeuCau && nhaCungCap === 'gemini';
  const huy = new AbortController();
  const huyKhiDong = () => huy.abort();
  response.once('close', huyKhiDong);
  let hetGio = false;
  const huyKhiHetGio = () => {
    hetGio = true;
    huy.abort();
  };
  let timeout = setTimeout(huyKhiHetGio, laGeminiLive ? 35_000 : 15_000);
  const gui = (suKien) => {
    if (!response.destroyed) response.write(JSON.stringify(suKien) + '\n');
  };
  // Flutter đặt lại thời gian chờ mỗi dòng NDJSON, kể cả khi Gemini chưa có văn bản.
  const baoCho = laGeminiLive ? setInterval(() => gui({ loai: 'cho' }), 10_000) : null;
  try {
    response.writeHead(200, {
      'Content-Type': 'application/x-ndjson; charset=utf-8',
      'Cache-Control': 'no-store, no-transform', 'X-Accel-Buffering': 'no',
    });
    gui({ loai: 'batDau', demo: !yeuCau, ...hanMuc });
    if (!yeuCau) {
      for (const text of demo(bai, duLieu.mucDo)) {
        await doi(90, undefined, { signal: huy.signal });
        gui({ loai: 'phan', text });
      }
    } else {
      const upstream = await goiApi(yeuCau.url, {
        method: 'POST',
        headers: { ...yeuCau.headers, 'Content-Type': 'application/json' },
        signal: huy.signal,
        body: JSON.stringify(yeuCau.body),
      });
      if (!upstream.ok) {
        console.error(`AI Tutor (${nhaCungCap}): stream HTTP ${upstream.status}`);
        gui({
          loai: 'loi',
          loi: upstream.status === 503 || upstream.status === 429
            ? 'Dịch vụ AI đang bận. Vui lòng thử lại sau.'
            : 'Dịch vụ AI chưa thể trả lời. Vui lòng kiểm tra cấu hình máy chủ.',
        });
        return;
      }
      if (!upstream.body) throw new Error('Phản hồi AI không có nội dung.');
      if (!laGeminiLive) {
        clearTimeout(timeout);
        timeout = setTimeout(huyKhiHetGio, 20_000);
      }
      let daCoText = false;
      for await (const text of trichSse(upstream, nhaCungCap)) {
        if (typeof text !== 'string' || text.length === 0) continue;
        if (daCoText || text.trim()) {
          clearTimeout(timeout);
          timeout = setTimeout(huyKhiHetGio, 20_000);
        }
        daCoText ||= text.trim().length > 0;
        gui({ loai: 'phan', text });
      }
      if (!daCoText) throw new Error('Phản hồi AI trống.');
    }
    gui({ loai: 'xong', ...moRong });
  } catch {
    gui({
      loai: 'loi',
      loi: hetGio
        ? 'Dịch vụ AI phản hồi quá thời gian chờ. Bạn có thể thử lại.'
        : 'Câu trả lời bị gián đoạn. Bạn có thể thử lại.',
    });
  } finally {
    clearTimeout(timeout);
    clearInterval(baoCho);
    response.off('close', huyKhiDong);
    huy.abort();
    response.end();
  }
}
