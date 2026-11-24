import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { test } from 'node:test';
import { taoChuoiThuong } from './streak-rewards.mjs';

test('chuỗi thưởng dùng giờ Việt Nam, mỗi ngày và mốc chỉ ghi một lần', () => {
  const db = new DatabaseSync(':memory:');
  try {
    db.exec(`CREATE TABLE tai_khoan (email TEXT PRIMARY KEY) STRICT;
      INSERT INTO tai_khoan VALUES ('a@example.test'), ('b@example.test');`);
    let gio = new Date('2026-11-23T16:59:59Z');
    const app = taoChuoiThuong(db, { 'flutter/b1': {}, 'flutter/b2': {} }, () => gio);
    const event = (id, lesson = 'flutter/b1') => ({
      eventId: String(id).padStart(24, '0'), lesson, from: false, to: true,
    });
    const a = (id, lesson) => app.ghiNhan('a@example.test', event(id, lesson));
    assert.equal(a(99, 'flutter/khong-co').body.code, 'INVALID_COMPLETION');
    const ngayDau = a(1).body;
    assert.equal(ngayDau.day, '2026-11-23');
    assert.equal(ngayDau.days, 1);
    assert.equal(a(2, 'flutter/b2').body.newDay, false);
    assert.equal(app.ghiNhan('b@example.test', event(1)).body.days, 1);
    gio = new Date('2026-11-23T17:00:00Z');
    assert.deepEqual(a(1).body, ngayDau);
    assert.equal(a(1, 'flutter/b2').body.code, 'COMPLETION_CONFLICT');
    assert.equal(a(3).body.days, 2);
    for (let ngay = 3; ngay <= 7; ngay++) {
      gio = new Date(gio.getTime() + 86_400_000);
      const kq = a(ngay + 1).body;
      assert.equal(kq.streakId, ngayDau.streakId);
      assert.equal(kq.days, ngay);
      assert.equal(kq.reward, ({ 3: 10, 7: 20 })[ngay] ?? 0);
      assert.equal(a(ngay + 99).body.reward, 0);
    }
    assert.deepEqual(app.trangThai('a@example.test').awards.map((x) => [x.amount, x.status]),
      [[20, 'pending'], [10, 'pending']]);
    gio = new Date(gio.getTime() + 2 * 86_400_000);
    assert.equal(app.trangThai('a@example.test').days, 0);
    assert.notEqual(a(22).body.streakId, ngayDau.streakId);
    assert.equal(a(22).body.days, 1);
  } finally {
    db.close();
  }
});

test('bù mốc đã vượt từ ngày đủ điều kiện và không cấp lặp', () => {
  const db = new DatabaseSync(':memory:');
  try {
    db.exec("CREATE TABLE tai_khoan (email TEXT PRIMARY KEY); INSERT INTO tai_khoan VALUES ('hoc@example.test'), ('legacy@example.test')");
    const email = 'hoc@example.test';
    const baiHoc = { 'flutter/b1': {} };
    let gio = new Date('2026-11-20T01:00:00Z');
    const cu = taoChuoiThuong(db, baiHoc, () => gio, {});
    for (let i = 0; i < 4; i++) {
      cu.ghiNhan(email, {
        eventId: 'lesson-test-event-' + String(i).padStart(8, '0'), lesson: 'flutter/b1', from: false, to: true,
      });
      if (i < 3) gio = new Date(gio.getTime() + 86_400_000);
    }
    const moi = taoChuoiThuong(db, baiHoc, () => gio);
    moi.buMoc(email);
    moi.buMoc(email);
    const tt = moi.trangThai(email);
    assert.equal(tt.days, 4);
    assert.equal(tt.pendingCoin, 10);
    assert.deepEqual(tt.awards.map(({ milestone, earnedAt, amount, status }) => [milestone, earnedAt, amount, status]),
      [[3, '2026-11-22', 10, 'pending']]);
    moi.buMoc('legacy@example.test');
    assert.equal(moi.trangThai('legacy@example.test').pendingCoin, 0);
  } finally {
    db.close();
  }
});
