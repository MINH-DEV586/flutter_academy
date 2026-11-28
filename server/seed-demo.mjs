import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';
import { taoChuoiThuong } from './streak-rewards.mjs';
import { ngayVietNam } from './ngay-viet-nam.mjs';
import { docNhatKyDemo } from './seed-learning.mjs';

const email = process.argv[2]?.toLowerCase();
if (!email?.endsWith('@example.test')) {
  console.error('Dùng tài khoản demo @example.test đã đăng ký và xác minh ví.');
  process.exit(1);
}
const envFile = new URL('../.env', import.meta.url);
if (existsSync(envFile)) process.loadEnvFile(envFile);
const path = process.env.ACADEMY_DB_PATH ??
  fileURLToPath(new URL('./.local/accounts.sqlite', import.meta.url));
const db = new DatabaseSync(path);

try {
  if (!db.prepare("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'verified_reward_wallets'").get() ||
      !db.prepare('SELECT 1 FROM verified_reward_wallets WHERE email = ?').get(email)) {
    throw new Error('Xác minh ví thưởng cho tài khoản trong ứng dụng trước khi gieo dữ liệu.');
  }
  const homNay = Date.now();
  const cacNgay = Array.from({ length: 6 }, (_, i) => new Date(homNay - (6 - i) * 86_400_000));
  if (db.prepare('SELECT 1 FROM reward_days WHERE email = ?').get(email)) {
    const nhatKy = docNhatKyDemo(db, email);
    if (nhatKy.length !== 6 || cacNgay.some((moc, i) => nhatKy[i].ngay !== ngayVietNam(moc).ngay)) {
      throw new Error('Tài khoản đã có chuỗi thưởng khác. Dùng tài khoản demo mới.');
    }
  } else {
    const bai = JSON.parse(readFileSync(new URL('../assets/bai_hoc_ai.json', import.meta.url), 'utf8'));
    let time;
    const chuoi = taoChuoiThuong(db, bai, () => time, {
      3: Number(process.env.STREAK_DAY_3_COIN) || 10,
      7: Number(process.env.STREAK_DAY_7_COIN) || 20,
    });
    for (const [i, moc] of cacNgay.entries()) {
      time = moc;
      const kq = chuoi.ghiNhan(email, {
        eventId: 'demo-seed-reward-day-' + (6 - i),
        lesson: 'flutter-nhap-mon/b1',
        from: false, to: true,
      });
      if (kq.status !== 200) throw new Error(kq.body.loi);
    }
  }
  console.log('Demo có 6 ngày hoạt động. Mở Ví Coin để xem mốc 3 ngày.');
} catch (loi) {
  console.error(loi.message);
  process.exitCode = 1;
} finally {
  db.close();
}
