// Chiếu các sự kiện hoàn thành do hai script demo tạo sang nhật ký học.
// Sự kiện cũ vẫn là nguồn dữ liệu, kể cả sau khi hợp nhất Coin.
export function docNhatKyDemo(db, email) {
  if (email !== 'demo@example.com' && !email.endsWith('@example.test')) return [];
  if (!db.prepare("SELECT 1 FROM sqlite_master WHERE name = 'reward_completions'").get()) return [];
  const suKien = db.prepare(`
    SELECT d.day, d.streak_id, r.lesson
    FROM reward_completions r JOIN reward_days d
      ON d.email = r.email AND d.day = json_extract(r.result, '$.day')
    WHERE r.email = ? AND d.day_count <= 6
      AND (r.event_id = 'video-demo-' || d.day || '-hoan-thanh'
        OR r.event_id = 'demo-seed-reward-day-' || (7 - d.day_count))
    ORDER BY d.day, r.rowid
  `).all(email);
  if (suKien.length === 0) return [];
  const chuoi = suKien.at(-1).streak_id;
  const theoNgay = new Map();
  for (const { day, lesson, streak_id } of suKien) {
    if (streak_id !== chuoi || theoNgay.has(day)) continue;
    theoNgay.set(day, {
      ngay: day, baiDaHoanThanh: [lesson], khoaHocDaThamGia: [lesson.split('/')[0]],
      xpNhanDuoc: 20, hoatDongDuyTri: 'Hoàn thành bài học',
    });
  }
  return [...theoNgay.values()];
}
