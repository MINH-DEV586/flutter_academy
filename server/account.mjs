import { createHash, randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { promisify } from 'node:util';

const bamMatKhau = promisify(scrypt);
const saltGia = randomBytes(16);
const hanPhien = 14 * 24 * 60 * 60 * 1000;
const emailHopLe = /^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$/;
const bamToken = (token) => createHash('sha256').update(token).digest('hex');

function bam(matKhau, salt) {
  return bamMatKhau(matKhau, salt, 64, {
    N: 2 ** 17, r: 8, p: 1, maxmem: 160 * 1024 * 1024,
  });
}

export function taoTaiKhoan(duongDan) {
  const db = new DatabaseSync(duongDan);
  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;
    PRAGMA busy_timeout = 3000;
    CREATE TABLE IF NOT EXISTS tai_khoan (
      email TEXT PRIMARY KEY,
      ho_ten TEXT NOT NULL,
      salt BLOB NOT NULL,
      mat_khau BLOB NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS phien (
      ma_bam TEXT PRIMARY KEY,
      email TEXT NOT NULL REFERENCES tai_khoan(email),
      het_han INTEGER NOT NULL
    ) STRICT;
    CREATE INDEX IF NOT EXISTS phien_het_han ON phien(het_han);
  `);
  const themTaiKhoan = db.prepare(
    'INSERT INTO tai_khoan VALUES (?, ?, ?, ?) ON CONFLICT(email) DO NOTHING',
  );
  const timTaiKhoan = db.prepare('SELECT * FROM tai_khoan WHERE email = ?');
  const themPhien = db.prepare('INSERT INTO phien VALUES (?, ?, ?)');
  const xoaPhienCu = db.prepare('DELETE FROM phien WHERE het_han <= ?');
  const xoaPhien = db.prepare('DELETE FROM phien WHERE ma_bam = ?');
  const docPhien = db.prepare(`
    SELECT tai_khoan.email, tai_khoan.ho_ten AS hoTen
    FROM phien JOIN tai_khoan USING (email)
    WHERE phien.ma_bam = ? AND phien.het_han > ?
  `);
  let dangBam = 0;
  let soLuot = 0;
  let hetCuaSo = 0;

  function capPhien(email, hoTen) {
    const token = randomBytes(32).toString('hex');
    const hienTai = Date.now();
    xoaPhienCu.run(hienTai);
    themPhien.run(bamToken(token), email, hienTai + hanPhien);
    return { token, nguoiDung: { email, hoTen } };
  }

  async function xuLy(request, tra, docJson) {
    const { url, method } = request;
    if (url === '/api/account/session' && (method === 'GET' || method === 'DELETE')) {
      const match = /^Bearer ([a-f0-9]{64})$/.exec(request.headers.authorization ?? '');
      if (!match) return tra(401, { loi: 'Bạn chưa đăng nhập.' });
      const maBam = bamToken(match[1]);
      if (method === 'DELETE') {
        xoaPhien.run(maBam);
        return tra(200, {});
      }
      const nguoiDung = docPhien.get(maBam, Date.now());
      return nguoiDung
        ? tra(200, { nguoiDung })
        : tra(401, { loi: 'Phiên đã hết hạn. Vui lòng đăng nhập lại.' });
    }

    const dangKy = url === '/api/account/register';
    if (!dangKy && url !== '/api/account/login') return tra(404, { loi: 'Sai địa chỉ.' });
    if (method !== 'POST') return tra(405, { loi: 'Chỉ hỗ trợ POST.' });
    if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
      return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
    }
    let duLieu;
    try {
      duLieu = await docJson(request);
    } catch {
      return tra(400, { loi: 'JSON không hợp lệ.' });
    }
    const email = typeof duLieu?.email === 'string' ? duLieu.email.trim().toLowerCase() : '';
    const hoTen = typeof duLieu?.hoTen === 'string' ? duLieu.hoTen.trim() : '';
    const matKhau = duLieu?.matKhau;
    if (email.length > 254 || !emailHopLe.test(email) ||
        typeof matKhau !== 'string' || matKhau.length < 1 || matKhau.length > 128 ||
        (dangKy && (matKhau.length < 12 || hoTen.length < 2 || hoTen.length > 80))) {
      return tra(400, { loi: 'Kiểm tra lại email, họ tên và mật khẩu.' });
    }

    const hienTai = Date.now();
    if (hienTai >= hetCuaSo) {
      hetCuaSo = hienTai + 60_000;
      soLuot = 0;
    }
    if (dangBam >= 2 || soLuot >= 20) return tra(429, { loi: 'Hãy đợi một phút rồi thử lại.' });
    soLuot++;
    dangBam++;
    try {
      if (dangKy) {
        const salt = randomBytes(16);
        const maBam = await bam(matKhau, salt);
        const inserted = themTaiKhoan.run(email, hoTen, salt, maBam);
        if (!inserted.changes) return tra(409, { loi: 'Email này đã được sử dụng.' });
        return tra(201, capPhien(email, hoTen));
      }
      const taiKhoan = timTaiKhoan.get(email);
      const maBam = await bam(matKhau, taiKhoan?.salt ?? saltGia);
      if (!taiKhoan || !timingSafeEqual(maBam, taiKhoan.mat_khau)) {
        return tra(401, { loi: 'Email hoặc mật khẩu không đúng.' });
      }
      return tra(200, capPhien(email, taiKhoan.ho_ten));
    } finally {
      dangBam--;
    }
  }

  return { xuLy, dong: () => db.close() };
}
