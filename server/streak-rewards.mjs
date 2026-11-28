import { randomBytes, randomUUID } from 'node:crypto';
import { ngayVietNam } from './ngay-viet-nam.mjs';

export function giaoDich(db, xuLy) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const ketQua = xuLy();
    db.exec('COMMIT');
    return ketQua;
  } catch (loi) {
    db.exec('ROLLBACK');
    throw loi;
  }
}

export function taoChuoiThuong(db, baiHoc, dongHo, mocThuong = { 3: 10, 7: 20 }) {
  const milestones = Object.entries(mocThuong)
    .map(([day, amount]) => ({ day: Number(day), amount: Number(amount) }))
    .filter(({ day, amount }) => Number.isSafeInteger(day) && day > 0 && Number.isSafeInteger(amount) && amount > 0)
    .sort((a, b) => a.day - b.day);
  const thuongTheoNgay = new Map(milestones.map(({ day, amount }) => [day, amount]));
  db.exec(`
    CREATE TABLE IF NOT EXISTS reward_days (
      email TEXT NOT NULL REFERENCES tai_khoan(email), day TEXT NOT NULL,
      streak_id TEXT NOT NULL, day_count INTEGER NOT NULL,
      PRIMARY KEY (email, day)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS reward_completions (
      email TEXT NOT NULL REFERENCES tai_khoan(email), event_id TEXT NOT NULL,
      lesson TEXT NOT NULL, result TEXT NOT NULL,
      PRIMARY KEY (email, event_id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS reward_mints (
      id TEXT PRIMARY KEY, email TEXT NOT NULL REFERENCES tai_khoan(email),
      streak_id TEXT NOT NULL, milestone INTEGER NOT NULL, amount INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending', tx_hash TEXT, earned_at TEXT,
      UNIQUE (email, streak_id, milestone)
    ) STRICT;`);
  if (!db.prepare('PRAGMA table_info(reward_mints)').all().some((col) => col.name === 'earned_at')) {
    db.exec('ALTER TABLE reward_mints ADD COLUMN earned_at TEXT');
  }
  const xemSuKien = db.prepare('SELECT lesson, result FROM reward_completions WHERE email = ? AND event_id = ?');
  const luuSuKien = db.prepare('INSERT INTO reward_completions VALUES (?, ?, ?, ?)');
  const xemNgay = db.prepare('SELECT * FROM reward_days WHERE email = ? AND day = ?');
  const themNgay = db.prepare('INSERT INTO reward_days VALUES (?, ?, ?, ?)');
  const xemGanNhat = db.prepare('SELECT * FROM reward_days WHERE email = ? ORDER BY day DESC LIMIT 1');
  const themThuong = db.prepare(`
    INSERT INTO reward_mints (id, email, streak_id, milestone, amount, earned_at) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT (email, streak_id, milestone) DO NOTHING`);
  const xemThuong = db.prepare(`
    SELECT m.id, m.milestone, m.amount, m.status, m.tx_hash AS txHash,
           COALESCE(m.earned_at, d.day) AS earnedAt
    FROM reward_mints m LEFT JOIN reward_days d
      ON d.email = m.email AND d.streak_id = m.streak_id AND d.day_count = m.milestone
    WHERE m.email = ? ORDER BY earnedAt DESC, m.rowid DESC LIMIT 25`);
  const xemCoinCho = db.prepare("SELECT COALESCE(SUM(amount), 0) AS total FROM reward_mints WHERE email = ? AND status != 'issued'");
  const mocCuaChuoi = db.prepare('SELECT milestone, status FROM reward_mints WHERE email = ? AND streak_id = ?');
  const mocBiThieu = db.prepare(`
    SELECT d.streak_id, MIN(d.day) AS diaNgay
    FROM reward_days d
    WHERE d.email = ? AND d.day_count >= ? AND NOT EXISTS (
      SELECT 1 FROM reward_mints m
      WHERE m.email = d.email AND m.streak_id = d.streak_id AND m.milestone = ?
    )
    GROUP BY d.streak_id`);

  function buMoc(email) {
    giaoDich(db, () => {
      for (const { day, amount } of milestones) {
        for (const row of mocBiThieu.all(email, day, day)) {
          themThuong.run('0x' + randomBytes(32).toString('hex'), email, row.streak_id, day, amount, row.diaNgay);
        }
      }
    });
  }

  function ghiNhan(email, duLieu) {
    const { eventId, lesson, from, to } = duLieu ?? {};
    if (typeof eventId !== 'string' || !/^[A-Za-z0-9_-]{20,64}$/.test(eventId) ||
        typeof lesson !== 'string' || !Object.hasOwn(baiHoc, lesson) ||
        from !== false || to !== true) {
      return { status: 400, body: { code: 'INVALID_COMPLETION', loi: 'Sự kiện hoàn thành bài không hợp lệ.' } };
    }
    return giaoDich(db, () => {
      const cu = xemSuKien.get(email, eventId);
      if (cu) return cu.lesson === lesson
        ? { status: 200, body: JSON.parse(cu.result) }
        : { status: 409, body: { code: 'COMPLETION_CONFLICT', loi: 'Mã sự kiện đã dùng cho bài khác.' } };
      const thoiDiem = dongHo();
      const { ngay, ngayTruoc } = ngayVietNam(thoiDiem);
      const homNay = xemNgay.get(email, ngay);
      const homQua = homNay ? null : xemNgay.get(email, ngayTruoc);
      const streakId = homNay?.streak_id ?? homQua?.streak_id ?? randomUUID();
      const days = homNay?.day_count ?? ((homQua?.day_count ?? 0) + 1);
      const amount = homNay ? 0 : (thuongTheoNgay.get(days) ?? 0);
      if (!homNay) themNgay.run(email, ngay, streakId, days);
      if (amount > 0) {
        themThuong.run('0x' + randomBytes(32).toString('hex'), email, streakId, days, amount, thoiDiem.toISOString());
      }
      const body = { day: ngay, streakId, days, newDay: !homNay, reward: amount };
      luuSuKien.run(email, eventId, lesson, JSON.stringify(body));
      return { status: 200, body };
    });
  }

  function trangThai(email) {
    const ganNhat = xemGanNhat.get(email);
    const { ngay, ngayTruoc } = ngayVietNam(dongHo());
    const lienTiep = ganNhat && [ngay, ngayTruoc].includes(ganNhat.day);
    const trangThaiMoc = new Map(lienTiep
      ? mocCuaChuoi.all(email, ganNhat.streak_id).map(({ milestone, status }) => [milestone, status])
      : []);
    return {
      days: lienTiep ? ganNhat.day_count : 0,
      lastDay: ganNhat?.day ?? null,
      milestones: milestones.map((muc) => ({ ...muc, status: trangThaiMoc.get(muc.day) ?? null })),
      pendingCoin: xemCoinCho.get(email).total,
      awards: xemThuong.all(email),
    };
  }

  return { ghiNhan, buMoc, trangThai };
}
