import { createHash, randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { promisify } from 'node:util';
import { taoThuong } from './rewards.mjs';
import { readFileSync } from 'node:fs';

const khoaCoPhi = JSON.parse(readFileSync(new URL('./paid-courses.json', import.meta.url), 'utf8'));

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

export function taoTaiKhoan(duongDan, maKhoaHocHopLe, baiHoc, rewardsOptions) {
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
    CREATE TABLE IF NOT EXISTS dang_ky_khoa_hoc (
      email TEXT NOT NULL REFERENCES tai_khoan(email),
      ma_khoa_hoc TEXT NOT NULL,
      PRIMARY KEY (email, ma_khoa_hoc)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS don_mua_khoa_hoc (
      email TEXT NOT NULL REFERENCES tai_khoan(email),
      ma_khoa_hoc TEXT NOT NULL,
      so_tien INTEGER NOT NULL,
      da_thanh_toan_luc INTEGER NOT NULL,
      PRIMARY KEY (email, ma_khoa_hoc)
    ) STRICT;
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
  const danhSachDangKy = db.prepare(
    'SELECT ma_khoa_hoc FROM dang_ky_khoa_hoc WHERE email = ? ORDER BY ma_khoa_hoc',
  );
  const themDangKy = db.prepare(
    'INSERT INTO dang_ky_khoa_hoc VALUES (?, ?) ON CONFLICT(email, ma_khoa_hoc) DO NOTHING',
  );
  const docDangKy = db.prepare(
    'SELECT 1 FROM dang_ky_khoa_hoc WHERE email = ? AND ma_khoa_hoc = ?',
  );
  const themDon = db.prepare('INSERT INTO don_mua_khoa_hoc VALUES (?, ?, ?, ?)');

  function coQuyenHoc(email, bai) {
    const [ma, maBai] = bai.split('/');
    const khoa = Object.hasOwn(khoaCoPhi, ma) ? khoaCoPhi[ma] : null;
    return !khoa || khoa.xemThu.includes(maBai) ||
      Boolean(email && docDangKy.get(email, ma));
  }
  const thuong = taoThuong(db, baiHoc, rewardsOptions);
  function emailPhien(request) {
    const match = /^Bearer ([a-f0-9]{64})$/.exec(request.headers.authorization ?? '');
    return match ? docPhien.get(bamToken(match[1]), Date.now())?.email : null;
  }
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
    if (url === '/api/account/rewards' || url.startsWith('/api/account/rewards/')) {
      const email = emailPhien(request);
      if (!email) return tra(401, { loi: 'Vui lòng đăng nhập.' });
      return thuong.xuLy(email, request, tra, docJson, () => emailPhien(request) === email,
        (bai) => coQuyenHoc(email, bai));
    }
    const muaThu = url === '/api/account/purchases/demo';
    if (url === '/api/account/enrollments' || muaThu) {
      const match = /^Bearer ([a-f0-9]{64})$/.exec(request.headers.authorization ?? '');
      const nguoiDung = match && docPhien.get(bamToken(match[1]), Date.now());
      if (!nguoiDung) return tra(401, { loi: 'Vui lòng đăng nhập để đăng ký khóa học.' });
      if (method === 'GET' && !muaThu) {
        const maKhoaHoc = danhSachDangKy.all(nguoiDung.email).map((row) => row.ma_khoa_hoc);
        return tra(200, { maKhoaHoc });
      }
      if (method !== 'POST') return tra(405, { loi: 'Chỉ hỗ trợ GET và POST.' });
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try {
        duLieu = await docJson(request);
      } catch {
        return tra(400, { loi: 'JSON không hợp lệ.' });
      }
      const maKhoaHoc = duLieu?.maKhoaHoc;
      if (!maKhoaHocHopLe.has(maKhoaHoc)) {
        return tra(404, { loi: 'Không tìm thấy khóa học để đăng ký.' });
      }
      // Kiểm tra lại phiên sau khi đọc body vì nó có thể vừa bị thu hồi.
      if (!docPhien.get(bamToken(match[1]), Date.now())) {
        return tra(401, { loi: 'Phiên đã hết hạn. Vui lòng đăng nhập lại.' });
      }
      const khoa = Object.hasOwn(khoaCoPhi, maKhoaHoc) ? khoaCoPhi[maKhoaHoc] : null;
      if (muaThu) {
        if (!khoa) return tra(400, { loi: 'Khóa này có thể đăng ký miễn phí.' });
        if (duLieu.soTien !== khoa.gia) {
          return tra(409, { loi: 'Giá khóa học đã thay đổi. Vui lòng tải lại trang.' });
        }
        db.exec('BEGIN IMMEDIATE');
        try {
          if (!docDangKy.get(nguoiDung.email, maKhoaHoc)) {
            themDon.run(nguoiDung.email, maKhoaHoc, khoa.gia, Date.now());
            themDangKy.run(nguoiDung.email, maKhoaHoc);
          }
          db.exec('COMMIT');
        } catch (loi) {
          db.exec('ROLLBACK');
          throw loi;
        }
        return tra(200, { maKhoaHoc, phuongThuc: 'demo' });
      }
      if (khoa) return tra(403, { loi: 'Cần mua khóa học trước khi đăng ký.' });
      themDangKy.run(nguoiDung.email, maKhoaHoc);
      return tra(200, { maKhoaHoc });
    }
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

  return { xuLy, emailPhien, coQuyenHoc, dungLuotAi: thuong.dungLuotAi, dong: () => db.close() };
}
