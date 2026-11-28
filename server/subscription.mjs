import { randomUUID } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';

export const GOI_PRO_THUONG = Object.freeze({ id: 'pro_7', days: 7, amount: 30 });

// ─── Module quản lý gói thành viên Pro ─────────────────────────────────────
export function taoThanhVien(duongDan, dongHo = () => new Date(), { coinChung = false } = {}) {
  const db = typeof duongDan === 'object' && duongDan !== null && duongDan.prepare ? duongDan : new DatabaseSync(duongDan);
  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;
    PRAGMA busy_timeout = 3000;

    CREATE TABLE IF NOT EXISTS pro_packages (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      duration_days INTEGER NOT NULL,
      coin_price INTEGER NOT NULL,
      description TEXT,
      benefits TEXT NOT NULL DEFAULT '[]',
      is_active INTEGER NOT NULL DEFAULT 1
    ) STRICT;

    CREATE TABLE IF NOT EXISTS user_subscriptions (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      package_id TEXT NOT NULL,
      started_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      coin_transaction_id TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    ) STRICT;
    CREATE INDEX IF NOT EXISTS idx_sub_email ON user_subscriptions(email);
  `);

  // ── Gieo dữ liệu gói Pro mặc định ────────────────────────────────────
  const demGoi = db.prepare('SELECT COUNT(*) AS cnt FROM pro_packages').get();
  if (demGoi.cnt === 0) {
    const gieo = db.prepare('INSERT INTO pro_packages (id, name, duration_days, coin_price, description, benefits) VALUES (?, ?, ?, ?, ?, ?)');
    gieo.run('pro_30', 'Pro 30 ngày', 30, 100,
      'Trải nghiệm đầy đủ quyền Pro trong 30 ngày.',
      JSON.stringify(['Mở khóa nội dung Pro', 'AI Tutor nâng cao', 'Tài liệu chuyên sâu', 'Huy hiệu Pro']),
    );
    gieo.run('pro_90', 'Pro 90 ngày', 90, 250,
      'Gói tiết kiệm cho 3 tháng học tập chuyên sâu.',
      JSON.stringify(['Mở khóa nội dung Pro', 'AI Tutor nâng cao', 'Tài liệu chuyên sâu', 'Huy hiệu Pro', 'Tiết kiệm 17%']),
    );
    gieo.run('pro_365', 'Pro 365 ngày', 365, 800,
      'Gói trọn năm, tiết kiệm nhất.',
      JSON.stringify(['Mở khóa nội dung Pro', 'AI Tutor nâng cao', 'Tài liệu chuyên sâu', 'Huy hiệu Pro', 'Tiết kiệm 34%', 'Ưu tiên hỗ trợ']),
    );
  }

  // ── Prepared Statements ────────────────────────────────────────────────
  const dsGoi        = db.prepare("SELECT * FROM pro_packages WHERE is_active = 1 ORDER BY duration_days");
  const layGoi       = db.prepare('SELECT * FROM pro_packages WHERE id = ? AND is_active = 1');
  const laySubActive = db.prepare("SELECT * FROM user_subscriptions WHERE email = ? AND status = 'active' AND julianday(expires_at) > julianday(?) ORDER BY julianday(expires_at) DESC LIMIT 1");
  const laySubAll    = db.prepare("SELECT us.*, pp.name AS package_name FROM user_subscriptions us JOIN pro_packages pp ON us.package_id = pp.id WHERE us.email = ? ORDER BY us.created_at DESC LIMIT 20");
  const themSub      = db.prepare('INSERT INTO user_subscriptions (id, email, package_id, started_at, expires_at, status, coin_transaction_id) VALUES (?, ?, ?, ?, ?, ?, ?)');
  const laySubGanNhat = db.prepare("SELECT * FROM user_subscriptions WHERE email = ? ORDER BY expires_at DESC LIMIT 1");

  // ── Ví Coin (truy cập bảng wallets trong cùng database) ────────────────
  const layVi        = db.prepare('SELECT coin_balance FROM wallets WHERE email = ?');
  const capNhatSoDu  = db.prepare("UPDATE wallets SET coin_balance = ?, updated_at = datetime('now') WHERE email = ?");
  const themGiaoDich = db.prepare('INSERT INTO coin_transactions (id, email, type, amount, balance_before, balance_after, status, description, reference_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');

  // ── Kiểm tra quyền Pro ────────────────────────────────────────────────
  function kiemTraPro(email) {
    const sub = laySubActive.get(email, dongHo().toISOString());
    if (!sub) return { isPro: false, expiresAt: null, packageId: null };
    return {
      isPro: true,
      expiresAt: sub.expires_at,
      packageId: sub.package_id,
      startedAt: sub.started_at,
    };
  }

  db.prepare(`INSERT OR IGNORE INTO pro_packages
    (id, name, duration_days, coin_price, description, is_active)
    VALUES (?, ?, ?, ?, 'Đổi bằng Coin thưởng học tập.', 0)`).run(
    GOI_PRO_THUONG.id, `Pro ${GOI_PRO_THUONG.days} ngày`, GOI_PRO_THUONG.days, GOI_PRO_THUONG.amount,
  );

  function timGoiCoin(id) {
    if (id === GOI_PRO_THUONG.id) return GOI_PRO_THUONG;
    const goi = layGoi.get(id);
    return goi ? { id, amount: goi.coin_price, days: goi.duration_days } : null;
  }

  function capProBlockchain(email, requestId, packageId = GOI_PRO_THUONG.id) {
    const goi = timGoiCoin(packageId);
    const hienTai = dongHo();
    const sub = laySubActive.get(email, hienTai.toISOString());
    const batDau = sub ? new Date(sub.expires_at.replace(' ', 'T') + (sub.expires_at.includes('T') ? '' : 'Z')) : hienTai;
    const expiresAt = new Date(batDau.getTime() + goi.days * 86_400_000).toISOString();
    themSub.run(requestId, email, packageId, batDau.toISOString(), expiresAt, 'active', null);
    return expiresAt;
  }

  // ── Handler HTTP ───────────────────────────────────────────────────────
  async function xuLy(request, tra, docJson, nguoiDung) {
    const { url, method } = request;

    // GET /api/subscriptions/packages — danh sách gói Pro
    if (url === '/api/subscriptions/packages' && method === 'GET') {
      const goiList = dsGoi.all().map((g) => ({
        id: g.id, name: g.name, durationDays: g.duration_days,
        coinPrice: g.coin_price, description: g.description,
        benefits: JSON.parse(g.benefits),
      }));
      return tra(200, { packages: goiList });
    }

    // GET /api/subscriptions/me — trạng thái thành viên
    if (url === '/api/subscriptions/me' && method === 'GET') {
      const trangThai = kiemTraPro(nguoiDung.email);
      const lichSu = laySubAll.all(nguoiDung.email).map((s) => ({
        id: s.id, packageId: s.package_id, packageName: s.package_name,
        startedAt: s.started_at, expiresAt: s.expires_at,
        status: s.status, createdAt: s.created_at,
      }));
      return tra(200, { ...trangThai, history: lichSu });
    }

    // POST /api/subscriptions/purchase — mua gói Pro
    if (url === '/api/subscriptions/purchase' && method === 'POST') {
      if (coinChung) return tra(409, { loi: 'Chọn gói Pro và xác nhận giao dịch bằng MetaMask trong app mới.' });
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      const packageId = duLieu?.packageId;
      const goi = layGoi.get(packageId);
      if (!goi) return tra(404, { loi: 'Gói thành viên không tồn tại.' });

      // Kiểm tra số dư Coin
      const vi = layVi.get(nguoiDung.email);
      if (!vi) return tra(400, { loi: 'Chưa có ví Coin. Hãy truy cập ví trước.' });
      if (vi.coin_balance < goi.coin_price) {
        return tra(400, { loi: `Không đủ Coin. Cần ${goi.coin_price} Coin, hiện có ${vi.coin_balance} Coin.` });
      }

      // Tính thời gian bắt đầu và kết thúc
      const subHienTai = laySubGanNhat.get(nguoiDung.email);
      let ngayBatDau;
      if (subHienTai && subHienTai.status === 'active' && subHienTai.expires_at > new Date().toISOString()) {
        // Đang có Pro → gia hạn từ ngày hết hạn
        ngayBatDau = new Date(subHienTai.expires_at);
      } else {
        // Chưa có Pro hoặc đã hết → bắt đầu từ bây giờ
        ngayBatDau = new Date();
      }
      const ngayKetThuc = new Date(ngayBatDau);
      ngayKetThuc.setDate(ngayKetThuc.getDate() + goi.duration_days);

      const subId = randomUUID();
      const txId  = randomUUID();
      const soDuTruoc = vi.coin_balance;
      const soDuSau   = soDuTruoc - goi.coin_price;

      db.exec('BEGIN IMMEDIATE');
      try {
        // Trừ Coin
        capNhatSoDu.run(soDuSau, nguoiDung.email);
        // Ghi giao dịch Coin
        themGiaoDich.run(
          txId, nguoiDung.email, 'PURCHASE_PRO', -goi.coin_price,
          soDuTruoc, soDuSau, 'completed',
          `Mua gói ${goi.name}`, subId,
        );
        // Tạo subscription
        themSub.run(
          subId, nguoiDung.email, goi.id,
          ngayBatDau.toISOString(), ngayKetThuc.toISOString(),
          'active', txId,
        );
        db.exec('COMMIT');
      } catch (err) {
        db.exec('ROLLBACK');
        throw err;
      }

      return tra(200, {
        ok: true,
        subscription: {
          id: subId, packageId: goi.id, packageName: goi.name,
          startedAt: ngayBatDau.toISOString(),
          expiresAt: ngayKetThuc.toISOString(),
        },
        coinDeducted: goi.coin_price,
        newBalance: soDuSau,
      });
    }

    // GET /api/subscriptions/check-pro — kiểm tra quyền (dùng bởi API khác)
    if (url === '/api/subscriptions/check-pro' && method === 'GET') {
      return tra(200, kiemTraPro(nguoiDung.email));
    }

    return tra(404, { loi: 'Sai địa chỉ thành viên.' });
  }

  return { xuLy, dong: () => db.close(), kiemTraPro, capProBlockchain, timGoiCoin };
}
