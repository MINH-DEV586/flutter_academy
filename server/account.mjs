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

export function taoTaiKhoan(duongDan, maKhoaHocHopLe) {
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
    CREATE TABLE IF NOT EXISTS streak_nguoi_dung (
      email TEXT PRIMARY KEY REFERENCES tai_khoan(email),
      chuoi_hien_tai INTEGER NOT NULL DEFAULT 0,
      chuoi_dai_nhat INTEGER NOT NULL DEFAULT 0,
      so_khiens_freeze INTEGER NOT NULL DEFAULT 0,
      tong_xp INTEGER NOT NULL DEFAULT 0,
      ngay_hoc_gan_nhat TEXT,
      cap_hien_tai INTEGER NOT NULL DEFAULT 1,
      muc_tieu_phut_moi_ngay INTEGER NOT NULL DEFAULT 10,
      danh_sach_huy_hieu TEXT NOT NULL DEFAULT '[]',
      cac_ngay_freeze_da_dung TEXT NOT NULL DEFAULT '[]',
      cap_nhat_luc INTEGER NOT NULL DEFAULT 0
    ) STRICT;
  `);
  const cotStreak = new Set(
    db.prepare('PRAGMA table_info(streak_nguoi_dung)').all().map((cot) => cot.name),
  );
  if (!cotStreak.has('muc_tieu_phut_moi_ngay')) {
    db.exec('ALTER TABLE streak_nguoi_dung ADD COLUMN muc_tieu_phut_moi_ngay INTEGER NOT NULL DEFAULT 10');
  }
  if (!cotStreak.has('danh_sach_huy_hieu')) {
    db.exec("ALTER TABLE streak_nguoi_dung ADD COLUMN danh_sach_huy_hieu TEXT NOT NULL DEFAULT '[]'");
  }
  if (!cotStreak.has('cac_ngay_freeze_da_dung')) {
    db.exec("ALTER TABLE streak_nguoi_dung ADD COLUMN cac_ngay_freeze_da_dung TEXT NOT NULL DEFAULT '[]'");
  }
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
  const docStreak = db.prepare('SELECT * FROM streak_nguoi_dung WHERE email = ?');
  const luuStreak = db.prepare(
    'INSERT INTO streak_nguoi_dung (email, chuoi_hien_tai, chuoi_dai_nhat, so_khiens_freeze, tong_xp, ngay_hoc_gan_nhat, cap_hien_tai, muc_tieu_phut_moi_ngay, danh_sach_huy_hieu, cac_ngay_freeze_da_dung, cap_nhat_luc) '
    + 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
    + 'ON CONFLICT(email) DO UPDATE SET '
    + 'chuoi_hien_tai = excluded.chuoi_hien_tai, '
    + 'chuoi_dai_nhat = MAX(chuoi_dai_nhat, excluded.chuoi_dai_nhat), '
    + 'so_khiens_freeze = excluded.so_khiens_freeze, '
    + 'tong_xp = excluded.tong_xp, '
    + 'ngay_hoc_gan_nhat = excluded.ngay_hoc_gan_nhat, '
    + 'cap_hien_tai = excluded.cap_hien_tai, '
    + 'muc_tieu_phut_moi_ngay = excluded.muc_tieu_phut_moi_ngay, '
    + 'danh_sach_huy_hieu = excluded.danh_sach_huy_hieu, '
    + 'cac_ngay_freeze_da_dung = excluded.cac_ngay_freeze_da_dung, '
    + 'cap_nhat_luc = excluded.cap_nhat_luc '
    + 'WHERE excluded.cap_nhat_luc >= streak_nguoi_dung.cap_nhat_luc'
  );
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
    if (url === '/api/account/streak') {
      const match = /^Bearer ([a-f0-9]{64})$/.exec(request.headers.authorization ?? '');
      const nguoiDung = match && docPhien.get(bamToken(match[1]), Date.now());
      if (!nguoiDung) return tra(401, { loi: 'Vui long dang nhap.' });
      if (method === 'GET') {
        const streak = docStreak.get(nguoiDung.email);
        return tra(200, streak ? {
          tonTai: true,
          chuoiHienTai: streak.chuoi_hien_tai,
          chuoiDaiNhat: streak.chuoi_dai_nhat,
          soKhiensFreeze: streak.so_khiens_freeze,
          tongXp: streak.tong_xp,
          ngayHocGanNhat: streak.ngay_hoc_gan_nhat,
          capHienTai: streak.cap_hien_tai,
          mucTieuPhutMoiNgay: streak.muc_tieu_phut_moi_ngay,
          danhSachHuyHieu: JSON.parse(streak.danh_sach_huy_hieu),
          cacNgayFreezeDaDung: JSON.parse(streak.cac_ngay_freeze_da_dung),
        } : {
          tonTai: false,
          chuoiHienTai: 0,
          chuoiDaiNhat: 0,
          soKhiensFreeze: 0,
          tongXp: 0,
          ngayHocGanNhat: null,
          capHienTai: 1,
          mucTieuPhutMoiNgay: 10,
          danhSachHuyHieu: [],
          cacNgayFreezeDaDung: [],
        });
      }
      if (method !== 'POST') return tra(405, { loi: 'Chi ho tro GET va POST.' });
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yeu cau noi dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON khong hop le.' }); }
      const {
        chuoiHienTai = 0,
        chuoiDaiNhat = 0,
        soKhiensFreeze = 0,
        tongXp = 0,
        ngayHocGanNhat = null,
        capHienTai = 1,
        mucTieuPhutMoiNgay = 10,
        danhSachHuyHieu = [],
        cacNgayFreezeDaDung = [],
      } = duLieu ?? {};
      if (
        !Number.isSafeInteger(chuoiHienTai) || chuoiHienTai < 0 ||
        !Number.isSafeInteger(chuoiDaiNhat) || chuoiDaiNhat < chuoiHienTai ||
        !Number.isSafeInteger(soKhiensFreeze) || soKhiensFreeze < 0 ||
        !Number.isSafeInteger(tongXp) || tongXp < 0 ||
        !Number.isSafeInteger(capHienTai) || capHienTai < 1 ||
        !Number.isSafeInteger(mucTieuPhutMoiNgay) || mucTieuPhutMoiNgay < 1 ||
        (ngayHocGanNhat !== null && (typeof ngayHocGanNhat !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(ngayHocGanNhat))) ||
        !Array.isArray(danhSachHuyHieu) ||
        !danhSachHuyHieu.every((ma) => typeof ma === 'string') ||
        !Array.isArray(cacNgayFreezeDaDung) ||
        !cacNgayFreezeDaDung.every((ngay) => typeof ngay === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(ngay))
      ) {
        return tra(400, { loi: 'Du lieu streak khong hop le.' });
      }
      luuStreak.run(
        nguoiDung.email,
        chuoiHienTai,
        chuoiDaiNhat,
        soKhiensFreeze,
        tongXp,
        ngayHocGanNhat,
        capHienTai,
        mucTieuPhutMoiNgay,
        JSON.stringify(danhSachHuyHieu),
        JSON.stringify(cacNgayFreezeDaDung),
        Date.now(),
      );
      return tra(200, { ok: true });
    }
    if (url === '/api/account/enrollments') {
      const match = /^Bearer ([a-f0-9]{64})$/.exec(request.headers.authorization ?? '');
      const nguoiDung = match && docPhien.get(bamToken(match[1]), Date.now());
      if (!nguoiDung) return tra(401, { loi: 'Vui lòng đăng nhập để đăng ký khóa học.' });
      if (method === 'GET') {
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

  return { xuLy, dong: () => db.close() };
}
