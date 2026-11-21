import { randomUUID } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';

// ─── Cấu hình gói nạp Coin ────────────────────────────────────────────────
const GOI_NAP = [
  { id: 'pkg_50',   coinAmount: 50,   ethAmount: '0.005',  name: '50 Coin' },
  { id: 'pkg_100',  coinAmount: 100,  ethAmount: '0.01',   name: '100 Coin' },
  { id: 'pkg_250',  coinAmount: 250,  ethAmount: '0.025',  name: '250 Coin' },
  { id: 'pkg_500',  coinAmount: 500,  ethAmount: '0.05',   name: '500 Coin' },
  { id: 'pkg_1000', coinAmount: 1000, ethAmount: '0.1',    name: '1000 Coin' },
];

// ─── Cấu hình thưởng Coin ─────────────────────────────────────────────────
const THUONG = {
  lesson_complete: 5,
  quiz_complete:   10,
  daily_goal:      20,
};

// ─── Hàm tiện ích ─────────────────────────────────────────────────────────
const isAddress = (s) => typeof s === 'string' && /^0x[0-9a-fA-F]{40}$/.test(s);
const isTxHash  = (s) => typeof s === 'string' && /^0x[0-9a-fA-F]{64}$/.test(s);
const isBytes32 = (s) => typeof s === 'string' && /^0x[0-9a-fA-F]{64}$/.test(s);

function taoOrderId() {
  const uuid = randomUUID().replace(/-/g, '');
  return '0x' + uuid.padEnd(64, '0');
}

// ─── Module chính ──────────────────────────────────────────────────────────
export function taoViCoin(duongDan, cauHinh = {}) {
  const {
    rpcUrl          = process.env.SEPOLIA_RPC_URL || 'http://127.0.0.1:8545',
    contractAddress = process.env.CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    depositEventTopic = process.env.DEPOSIT_EVENT_TOPIC || '0xa1f70d8aaaf6aafecf69db7239885a8dbc2d3636257385ea05b8038a273b6587',
    requiredConfirmations = Number(process.env.REQUIRED_CONFIRMATIONS) || 0,
  } = cauHinh;

  const db = typeof duongDan === 'object' && duongDan !== null && duongDan.prepare ? duongDan : new DatabaseSync(duongDan);
  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;
    PRAGMA busy_timeout = 3000;

    CREATE TABLE IF NOT EXISTS wallets (
      email TEXT PRIMARY KEY,
      coin_balance INTEGER NOT NULL DEFAULT 0 CHECK(coin_balance >= 0),
      metamask_address TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    ) STRICT;

    CREATE TABLE IF NOT EXISTS coin_transactions (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      type TEXT NOT NULL,
      amount INTEGER NOT NULL,
      balance_before INTEGER NOT NULL,
      balance_after INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'completed',
      description TEXT,
      reference_id TEXT,
      transaction_hash TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    ) STRICT;
    CREATE INDEX IF NOT EXISTS idx_coin_tx_email ON coin_transactions(email);
    CREATE INDEX IF NOT EXISTS idx_coin_tx_ref ON coin_transactions(reference_id);

    CREATE TABLE IF NOT EXISTS deposit_orders (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      wallet_address TEXT,
      package_id TEXT NOT NULL,
      eth_amount TEXT NOT NULL,
      coin_amount INTEGER NOT NULL,
      transaction_hash TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      confirmed_at TEXT
    ) STRICT;
    CREATE INDEX IF NOT EXISTS idx_deposit_email ON deposit_orders(email);

    CREATE TABLE IF NOT EXISTS blockchain_transactions (
      id TEXT PRIMARY KEY,
      transaction_hash TEXT UNIQUE NOT NULL,
      block_number INTEGER,
      from_address TEXT,
      to_address TEXT,
      contract_address TEXT,
      event_name TEXT,
      order_id TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      confirmations INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    ) STRICT;
    CREATE INDEX IF NOT EXISTS idx_bc_tx_order ON blockchain_transactions(order_id);
  `);

  // ── Prepared Statements ────────────────────────────────────────────────
  const layVi          = db.prepare('SELECT * FROM wallets WHERE email = ?');
  const taoVi          = db.prepare("INSERT INTO wallets (email) VALUES (?) ON CONFLICT(email) DO NOTHING");
  const capNhatSoDu    = db.prepare("UPDATE wallets SET coin_balance = ?, updated_at = datetime('now') WHERE email = ?");
  const lienKetMM      = db.prepare("UPDATE wallets SET metamask_address = ?, updated_at = datetime('now') WHERE email = ?");

  const themGiaoDich   = db.prepare('INSERT INTO coin_transactions (id, email, type, amount, balance_before, balance_after, status, description, reference_id, transaction_hash) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  const dsGiaoDich     = db.prepare('SELECT * FROM coin_transactions WHERE email = ? ORDER BY created_at DESC LIMIT ? OFFSET ?');
  const kiemTraRef     = db.prepare("SELECT id FROM coin_transactions WHERE reference_id = ? AND type = ? AND status = 'completed' LIMIT 1");

  const taoDonNap      = db.prepare("INSERT INTO deposit_orders (id, email, wallet_address, package_id, eth_amount, coin_amount, status) VALUES (?, ?, ?, ?, ?, ?, 'pending')");
  const layDonNap      = db.prepare('SELECT * FROM deposit_orders WHERE id = ? AND email = ?');
  const layDonNapById  = db.prepare('SELECT * FROM deposit_orders WHERE id = ?');
  const capNhatDonNap  = db.prepare('UPDATE deposit_orders SET transaction_hash = ?, status = ?, confirmed_at = ? WHERE id = ?');
  const dsDonNapCho    = db.prepare("SELECT * FROM deposit_orders WHERE status IN ('submitted', 'confirming')");
  const layDonTheoHash = db.prepare('SELECT * FROM deposit_orders WHERE transaction_hash = ?');

  const themBcTx       = db.prepare('INSERT INTO blockchain_transactions (id, transaction_hash, block_number, from_address, to_address, contract_address, event_name, order_id, status, confirmations) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  const layBcTx        = db.prepare('SELECT * FROM blockchain_transactions WHERE transaction_hash = ?');
  const capNhatBcTx    = db.prepare('UPDATE blockchain_transactions SET block_number = ?, status = ?, confirmations = ? WHERE transaction_hash = ?');

  // ── Helper: đảm bảo ví tồn tại ────────────────────────────────────────
  function damBaoVi(email) {
    let vi = layVi.get(email);
    if (!vi) {
      taoVi.run(email);
      vi = layVi.get(email);
    }
    return vi;
  }

  // ── Helper: cộng/trừ Coin trong transaction ────────────────────────────
  function thayDoiSoDu(email, amount, type, description, refId = null, txHash = null) {
    const vi = damBaoVi(email);
    const soDuTruoc = vi.coin_balance;
    const soDuSau   = soDuTruoc + amount;
    if (soDuSau < 0) return null; // Không đủ số dư
    db.exec('BEGIN IMMEDIATE');
    try {
      capNhatSoDu.run(soDuSau, email);
      themGiaoDich.run(
        randomUUID(), email, type, amount,
        soDuTruoc, soDuSau, 'completed',
        description, refId, txHash,
      );
      db.exec('COMMIT');
      return { soDuTruoc, soDuSau };
    } catch (err) {
      db.exec('ROLLBACK');
      throw err;
    }
  }

  // ── Blockchain RPC calls ───────────────────────────────────────────────
  async function goiRpc(method, params = []) {
    if (!rpcUrl) return null;
    const res = await fetch(rpcUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
      signal: AbortSignal.timeout(15_000),
    });
    const json = await res.json();
    return json.result ?? null;
  }

  async function layReceipt(txHash) {
    return goiRpc('eth_getTransactionReceipt', [txHash]);
  }

  async function laySoBlock() {
    const hex = await goiRpc('eth_blockNumber');
    return hex ? parseInt(hex, 16) : null;
  }

  // ── Xác minh giao dịch blockchain ──────────────────────────────────────
  async function xacMinhGiaoDich(orderId, txHash) {
    if (!rpcUrl || !contractAddress) {
      return { ok: false, loi: 'Chưa cấu hình RPC hoặc Contract.' };
    }
    // Kiểm tra đã xử lý chưa
    const bcTxCu = layBcTx.get(txHash);
    if (bcTxCu && bcTxCu.status === 'confirmed') {
      return { ok: false, loi: 'Giao dịch đã được xử lý.' };
    }

    const receipt = await layReceipt(txHash);
    if (!receipt) return { ok: false, loi: 'Chưa tìm thấy giao dịch trên blockchain.' };
    if (receipt.status !== '0x1') {
      capNhatDonNap.run(txHash, 'failed', null, orderId);
      return { ok: false, loi: 'Giao dịch thất bại trên blockchain.' };
    }

    // Kiểm tra contract address
    if (receipt.to?.toLowerCase() !== contractAddress.toLowerCase()) {
      return { ok: false, loi: 'Giao dịch không gửi đến đúng Smart Contract.' };
    }

    // Kiểm tra block confirmations
    const blockHienTai = await laySoBlock();
    const blockGiaoDich = parseInt(receipt.blockNumber, 16);
    const confirmations = blockHienTai ? blockHienTai - blockGiaoDich : 0;
    if (confirmations < requiredConfirmations) {
      // Lưu trạng thái confirming
      if (!bcTxCu) {
        themBcTx.run(
          randomUUID(), txHash, blockGiaoDich, receipt.from, receipt.to,
          contractAddress, 'Deposit', orderId, 'pending', confirmations,
        );
      } else {
        capNhatBcTx.run(blockGiaoDich, 'pending', confirmations, txHash);
      }
      capNhatDonNap.run(txHash, 'confirming', null, orderId);
      return { ok: false, loi: `Đang chờ xác nhận (${confirmations}/${requiredConfirmations}).`, dangCho: true };
    }

    // Kiểm tra event logs - tìm Deposit event
    let eventHopLe = false;
    let eventData = null;
    for (const log of receipt.logs ?? []) {
      if (log.address?.toLowerCase() !== contractAddress.toLowerCase()) continue;
      // Nếu có depositEventTopic, kiểm tra topic[0]
      if (depositEventTopic && log.topics?.[0]?.toLowerCase() !== depositEventTopic.toLowerCase()) continue;
      // topic[1] là orderId (indexed bytes32)
      const logOrderId = log.topics?.[1];
      if (logOrderId?.toLowerCase() === orderId.toLowerCase()) {
        eventHopLe = true;
        eventData = {
          buyer: '0x' + (log.topics?.[2] ?? '').slice(26),
          data: log.data,
        };
        break;
      }
    }

    if (!eventHopLe) {
      return { ok: false, loi: 'Không tìm thấy event Deposit hợp lệ cho đơn hàng này.' };
    }

    // Lưu blockchain transaction
    if (!bcTxCu) {
      themBcTx.run(
        randomUUID(), txHash, blockGiaoDich, receipt.from, receipt.to,
        contractAddress, 'Deposit', orderId, 'confirmed', confirmations,
      );
    } else {
      capNhatBcTx.run(blockGiaoDich, 'confirmed', confirmations, txHash);
    }

    return { ok: true, confirmations, blockNumber: blockGiaoDich, buyer: eventData?.buyer };
  }

  // ── Thưởng Coin (dùng bởi module khác hoặc API) ───────────────────────
  function thuongCoin(email, loai, referenceId, moTa) {
    const soLuong = THUONG[loai];
    if (!soLuong) return { ok: false, loi: 'Loại thưởng không hợp lệ.' };
    // Chống trùng
    const daThuong = kiemTraRef.get(referenceId, 'REWARD');
    if (daThuong) return { ok: false, loi: 'Phần thưởng đã được nhận.' };
    const kq = thayDoiSoDu(email, soLuong, 'REWARD', moTa || `Thưởng ${loai}`, referenceId);
    if (!kq) return { ok: false, loi: 'Lỗi cập nhật số dư.' };
    return { ok: true, coinNhan: soLuong, soDuMoi: kq.soDuSau };
  }

  // ── Xác minh lại các giao dịch đang chờ (gọi khi khởi động) ───────────
  async function xacMinhGiaoDichDangCho() {
    const dsDangCho = dsDonNapCho.all();
    for (const don of dsDangCho) {
      if (!don.transaction_hash) continue;
      try {
        const kq = await xacMinhGiaoDich(don.id, don.transaction_hash);
        if (kq.ok) {
          db.exec('BEGIN IMMEDIATE');
          try {
            capNhatDonNap.run(don.transaction_hash, 'completed', new Date().toISOString(), don.id);
            const vi = damBaoVi(don.email);
            const soDuTruoc = vi.coin_balance;
            const soDuSau = soDuTruoc + don.coin_amount;
            capNhatSoDu.run(soDuSau, don.email);
            themGiaoDich.run(
              randomUUID(), don.email, 'DEPOSIT', don.coin_amount,
              soDuTruoc, soDuSau, 'completed',
              `Nạp ${don.coin_amount} Coin qua MetaMask`, don.id, don.transaction_hash,
            );
            db.exec('COMMIT');
            console.log(`Wallet: đã xác minh giao dịch ${don.id}`);
          } catch (err) {
            db.exec('ROLLBACK');
            console.error(`Wallet: lỗi xử lý giao dịch ${don.id}:`, err.message);
          }
        }
      } catch (err) {
        console.error(`Wallet: lỗi xác minh ${don.id}:`, err.message);
      }
    }
  }

  // ── Handler HTTP ───────────────────────────────────────────────────────
  async function xuLy(request, tra, docJson, nguoiDung) {
    const { url, method } = request;

    // GET /api/wallet — thông tin ví
    if (url === '/api/wallet' && method === 'GET') {
      const vi = damBaoVi(nguoiDung.email);
      return tra(200, {
        email: vi.email,
        coinBalance: vi.coin_balance,
        metamaskAddress: vi.metamask_address,
        createdAt: vi.created_at,
      });
    }

    // GET /api/wallet/transactions — lịch sử giao dịch
    if (url?.startsWith('/api/wallet/transactions') && method === 'GET') {
      const params = new URL(url, 'http://x').searchParams;
      const page  = Math.max(1, parseInt(params.get('page') ?? '1'));
      const limit = Math.min(50, Math.max(1, parseInt(params.get('limit') ?? '20')));
      const offset = (page - 1) * limit;
      const ds = dsGiaoDich.all(nguoiDung.email, limit, offset);
      return tra(200, {
        transactions: ds.map((gd) => ({
          id: gd.id, type: gd.type, amount: gd.amount,
          balanceBefore: gd.balance_before, balanceAfter: gd.balance_after,
          status: gd.status, description: gd.description,
          referenceId: gd.reference_id, transactionHash: gd.transaction_hash,
          createdAt: gd.created_at,
        })),
        page, limit,
      });
    }

    // GET /api/wallet/deposit-packages — danh sách gói nạp
    if (url === '/api/wallet/deposit-packages' && method === 'GET') {
      return tra(200, {
        packages: GOI_NAP,
        contractAddress: contractAddress || null,
        chainId: 11155111,
        network: 'sepolia',
      });
    }

    // POST /api/wallet/metamask — liên kết/huỷ liên kết MetaMask
    if (url === '/api/wallet/metamask' && method === 'POST') {
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      const address = duLieu?.address;
      if (address !== null && !isAddress(address)) {
        return tra(400, { loi: 'Địa chỉ ví không hợp lệ.' });
      }
      damBaoVi(nguoiDung.email);
      lienKetMM.run(address, nguoiDung.email);
      return tra(200, { ok: true, metamaskAddress: address });
    }

    // POST /api/wallet/deposits — tạo đơn nạp
    if (url === '/api/wallet/deposits' && method === 'POST') {
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      const packageId = duLieu?.packageId;
      const walletAddress = duLieu?.walletAddress;
      const goi = GOI_NAP.find((g) => g.id === packageId);
      if (!goi) return tra(400, { loi: 'Gói nạp không hợp lệ.' });
      if (walletAddress && !isAddress(walletAddress)) {
        return tra(400, { loi: 'Địa chỉ ví không hợp lệ.' });
      }
      const orderId = taoOrderId();
      damBaoVi(nguoiDung.email);
      taoDonNap.run(orderId, nguoiDung.email, walletAddress ?? null, goi.id, goi.ethAmount, goi.coinAmount);
      return tra(201, {
        orderId,
        packageId: goi.id,
        coinAmount: goi.coinAmount,
        ethAmount: goi.ethAmount,
        contractAddress: contractAddress || null,
        chainId: 11155111,
      });
    }

    // POST /api/wallet/deposits/:id/submit — gửi transaction hash
    const submitMatch = url?.match(/^\/api\/wallet\/deposits\/([^/]+)\/submit$/);
    if (submitMatch && method === 'POST') {
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      const donId = submitMatch[1];
      const txHash = duLieu?.transactionHash;
      if (!isTxHash(txHash)) return tra(400, { loi: 'Transaction hash không hợp lệ.' });
      const don = layDonNap.get(donId, nguoiDung.email);
      if (!don) return tra(404, { loi: 'Không tìm thấy đơn nạp.' });
      if (don.status !== 'pending') return tra(400, { loi: `Đơn nạp đang ở trạng thái "${don.status}", không thể cập nhật.` });
      // Kiểm tra tx hash chưa được dùng
      const donCu = layDonTheoHash.get(txHash);
      if (donCu) return tra(409, { loi: 'Transaction hash đã được sử dụng cho đơn nạp khác.' });
      capNhatDonNap.run(txHash, 'submitted', null, donId);
      return tra(200, { ok: true, status: 'submitted' });
    }

    // POST /api/wallet/deposits/:id/verify — xác minh blockchain
    const verifyMatch = url?.match(/^\/api\/wallet\/deposits\/([^/]+)\/verify$/);
    if (verifyMatch && method === 'POST') {
      const donId = verifyMatch[1];
      const don = layDonNap.get(donId, nguoiDung.email);
      if (!don) return tra(404, { loi: 'Không tìm thấy đơn nạp.' });
      if (don.status === 'completed') return tra(200, { ok: true, status: 'completed', coinAmount: don.coin_amount });
      if (don.status === 'failed') return tra(400, { loi: 'Đơn nạp đã thất bại.' });
      if (!don.transaction_hash) return tra(400, { loi: 'Chưa có transaction hash.' });

      try {
        const kq = await xacMinhGiaoDich(donId, don.transaction_hash);
        if (!kq.ok) {
          return tra(kq.dangCho ? 202 : 400, {
            ok: false, status: don.status, loi: kq.loi,
          });
        }
        // Giao dịch xác minh thành công → cộng coin
        db.exec('BEGIN IMMEDIATE');
        try {
          capNhatDonNap.run(don.transaction_hash, 'completed', new Date().toISOString(), donId);
          const vi = damBaoVi(nguoiDung.email);
          const soDuTruoc = vi.coin_balance;
          const soDuSau = soDuTruoc + don.coin_amount;
          capNhatSoDu.run(soDuSau, nguoiDung.email);
          themGiaoDich.run(
            randomUUID(), nguoiDung.email, 'DEPOSIT', don.coin_amount,
            soDuTruoc, soDuSau, 'completed',
            `Nạp ${don.coin_amount} Coin qua MetaMask`, donId, don.transaction_hash,
          );
          db.exec('COMMIT');
        } catch (err) {
          db.exec('ROLLBACK');
          throw err;
        }
        const viMoi = layVi.get(nguoiDung.email);
        return tra(200, { ok: true, status: 'completed', coinAmount: don.coin_amount, newBalance: viMoi.coin_balance });
      } catch (err) {
        console.error(`Wallet verify: ${err.message}`);
        return tra(500, { loi: 'Lỗi xác minh giao dịch blockchain.' });
      }
    }

    // GET /api/wallet/deposits/:id — chi tiết đơn nạp
    const detailMatch = url?.match(/^\/api\/wallet\/deposits\/([^/]+)$/);
    if (detailMatch && method === 'GET') {
      const don = layDonNap.get(detailMatch[1], nguoiDung.email);
      if (!don) return tra(404, { loi: 'Không tìm thấy đơn nạp.' });
      return tra(200, {
        orderId: don.id, email: don.email, walletAddress: don.wallet_address,
        packageId: don.package_id, ethAmount: don.eth_amount,
        coinAmount: don.coin_amount, transactionHash: don.transaction_hash,
        status: don.status, createdAt: don.created_at, confirmedAt: don.confirmed_at,
      });
    }

    // POST /api/wallet/claim-reward — nhận thưởng Coin
    if (url === '/api/wallet/claim-reward' && method === 'POST') {
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      const loai = duLieu?.type;
      const refId = duLieu?.referenceId;
      if (!loai || !refId || typeof loai !== 'string' || typeof refId !== 'string') {
        return tra(400, { loi: 'Thiếu type hoặc referenceId.' });
      }
      const kq = thuongCoin(nguoiDung.email, loai, refId, duLieu.description);
      if (!kq.ok) return tra(409, { loi: kq.loi });
      return tra(200, { ok: true, coinNhan: kq.coinNhan, soDuMoi: kq.soDuMoi });
    }

    return tra(404, { loi: 'Sai địa chỉ ví.' });
  }

  // Khởi chạy xác minh giao dịch chờ sau 5 giây
  setTimeout(() => { xacMinhGiaoDichDangCho().catch(() => {}); }, 5000);

  return { xuLy, dong: () => db.close(), thuongCoin, damBaoVi };
}
