import { randomUUID } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { diaChiHopLe, taoDonNapCoin } from './deposit-orders.mjs';
import { giaoDich } from './streak-rewards.mjs';

const GOI_NAP = [
  { id: 'pkg_50', maHopDong: 1, coinAmount: 50, ethAmount: '0.005', name: '50 Coin' },
  { id: 'pkg_100', maHopDong: 2, coinAmount: 100, ethAmount: '0.01', name: '100 Coin' },
  { id: 'pkg_250', maHopDong: 3, coinAmount: 250, ethAmount: '0.025', name: '250 Coin' },
  { id: 'pkg_500', maHopDong: 4, coinAmount: 500, ethAmount: '0.05', name: '500 Coin' },
  { id: 'pkg_1000', maHopDong: 5, coinAmount: 1000, ethAmount: '0.1', name: '1000 Coin' },
];

const THUONG = { lesson_complete: 5, quiz_complete: 10, daily_goal: 20 };

export function taoViCoin(duongDan, cauHinh = {}) {
  const {
    rpcUrl = process.env.SEPOLIA_RPC_URL || 'http://127.0.0.1:8545',
    contractAddress = process.env.CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    depositEventTopic = process.env.DEPOSIT_EVENT_TOPIC,
    requiredConfirmations = Number(process.env.REQUIRED_CONFIRMATIONS) || 0,
    chainId = Number(process.env.DEPOSIT_CHAIN_ID) || (/^http:\/\/(?:127\.0\.0\.1|localhost):8545\/?$/.test(rpcUrl) ? 31337 : 11155111),
    walletRpcUrl, goiRpcFetch,
  } = cauHinh;

  const db = typeof duongDan === 'object' && duongDan?.prepare ? duongDan : new DatabaseSync(duongDan);
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

  const layVi = db.prepare('SELECT * FROM wallets WHERE email = ?');
  const taoVi = db.prepare("INSERT INTO wallets (email) VALUES (?) ON CONFLICT(email) DO NOTHING");
  const capNhatSoDu = db.prepare("UPDATE wallets SET coin_balance = ?, updated_at = datetime('now') WHERE email = ?");
  const lienKetMM = db.prepare("UPDATE wallets SET metamask_address = ?, updated_at = datetime('now') WHERE email = ?");
  const themGiaoDich = db.prepare('INSERT INTO coin_transactions (id, email, type, amount, balance_before, balance_after, status, description, reference_id, transaction_hash) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  const dsGiaoDich = db.prepare('SELECT * FROM coin_transactions WHERE email = ? ORDER BY created_at DESC, rowid DESC LIMIT ? OFFSET ?');
  const kiemTraRef = db.prepare("SELECT id FROM coin_transactions WHERE email = ? AND reference_id = ? AND type = ? AND status = 'completed' LIMIT 1");

  function damBaoVi(email) {
    const vi = layVi.get(email);
    if (vi) return vi;
    taoVi.run(email);
    return layVi.get(email);
  }

  const donNap = taoDonNapCoin(db, GOI_NAP, (don, hash, wallet) => {
    if (kiemTraRef.get(don.email, don.id, 'DEPOSIT')) return;
    const vi = damBaoVi(don.email);
    const soDuMoi = vi.coin_balance + don.coin_amount;
    capNhatSoDu.run(soDuMoi, don.email);
    if (!vi.metamask_address) lienKetMM.run(wallet, don.email);
    themGiaoDich.run(
      randomUUID(), don.email, 'DEPOSIT', don.coin_amount, vi.coin_balance, soDuMoi,
      'completed', `Nạp ${don.coin_amount} Coin qua MetaMask`, don.id, hash,
    );
  }, { rpcUrl, walletRpcUrl, goiRpcFetch, contractAddress, depositEventTopic, requiredConfirmations, chainId });

  function thuongCoin(email, loai, referenceId, moTa) {
    const soLuong = THUONG[loai];
    if (!soLuong) return { ok: false, loi: 'Loại thưởng không hợp lệ.' };
    return giaoDich(db, () => {
      if (kiemTraRef.get(email, referenceId, 'REWARD')) return { ok: false, loi: 'Phần thưởng đã được nhận.' };
      const soDuTruoc = damBaoVi(email).coin_balance;
      const soDuMoi = soDuTruoc + soLuong;
      capNhatSoDu.run(soDuMoi, email);
      themGiaoDich.run(
        randomUUID(), email, 'REWARD', soLuong, soDuTruoc, soDuMoi,
        'completed', moTa || `Thưởng ${loai}`, referenceId, null,
      );
      return { ok: true, coinNhan: soLuong, soDuMoi };
    });
  }

  async function xuLy(request, tra, docJson, nguoiDung) {
    const { url, method } = request;
    const { email } = nguoiDung;

    if (url === '/api/wallet' && method === 'GET') {
      const vi = damBaoVi(email);
      return tra(200, { email, coinBalance: vi.coin_balance, metamaskAddress: vi.metamask_address, createdAt: vi.created_at });
    }
    if (url?.startsWith('/api/wallet/transactions') && method === 'GET') {
      const params = new URL(url, 'http://x').searchParams;
      const page = Math.max(1, Number.parseInt(params.get('page'), 10) || 1);
      const limit = Math.min(50, Math.max(1, Number.parseInt(params.get('limit'), 10) || 20));
      const giaoDich = dsGiaoDich.all(email, limit, (page - 1) * limit);
      return tra(200, {
        transactions: giaoDich.map((gd) => ({
          id: gd.id, type: gd.type, amount: gd.amount,
          balanceBefore: gd.balance_before, balanceAfter: gd.balance_after,
          status: gd.status, description: gd.description, referenceId: gd.reference_id,
          transactionHash: gd.transaction_hash, createdAt: gd.created_at,
        })), page, limit,
      });
    }
    if (url === '/api/wallet/deposit-packages' && method === 'GET') {
      return tra(200, {
        packages: GOI_NAP.map(({ maHopDong, ...goi }) => goi), contractAddress: contractAddress || null, chainId,
        network: chainId === 31337 ? 'hardhat' : chainId === 11155111 ? 'sepolia' : 'custom',
      });
    }
    if (url === '/api/wallet/deposits/latest' && method === 'GET') {
      return tra(200, { order: await donNap.kiemTraGanNhat(email) });
    }

    const routeDon = url?.match(/^\/api\/wallet\/deposits\/([^/]+)(?:\/(submit|verify))?$/);
    if (routeDon && method === 'GET' && !routeDon[2]) {
      return tra(200, donNap.thongTin(donNap.cuaToi(email, routeDon[1])));
    }
    if (routeDon && method === 'POST' && routeDon[2] === 'verify') {
      const kq = await donNap.doiSoat(donNap.cuaToi(email, routeDon[1]));
      if (kq.status === 'completed') {
        return tra(200, { ...kq, ok: true, newBalance: damBaoVi(email).coin_balance });
      }
      return tra(kq.status === 'failed' ? 400 : 202, {
        ...kq, ok: false, loi: kq.status === 'failed' ? 'Giao dịch nạp không hợp lệ hoặc thất bại.' : 'Đang chờ giao dịch được xác nhận.',
      });
    }

    if (method === 'POST' && (routeDon?.[2] === 'submit' ||
        ['/api/wallet/metamask', '/api/wallet/deposits', '/api/wallet/claim-reward'].includes(url))) {
      if (request.headers['content-type']?.split(';')[0] !== 'application/json') {
        return tra(415, { loi: 'Yêu cầu nội dung JSON.' });
      }
      let duLieu;
      try { duLieu = await docJson(request); } catch { return tra(400, { loi: 'JSON không hợp lệ.' }); }
      if (routeDon?.[2] === 'submit') {
        return tra(200, { ok: true, ...donNap.guiHash(donNap.cuaToi(email, routeDon[1]), duLieu?.transactionHash) });
      }
      if (url === '/api/wallet/metamask') {
        const address = duLieu?.address;
        if (address !== null && !diaChiHopLe(address)) return tra(400, { loi: 'Địa chỉ ví không hợp lệ.' });
        damBaoVi(email);
        lienKetMM.run(address, email);
        return tra(200, { ok: true, metamaskAddress: address });
      }
      if (url === '/api/wallet/deposits') {
        const goi = GOI_NAP.find((g) => g.id === duLieu?.packageId);
        if (!goi) return tra(400, { loi: 'Gói nạp không hợp lệ.' });
        if (duLieu?.walletAddress != null && !diaChiHopLe(duLieu.walletAddress)) {
          return tra(400, { loi: 'Địa chỉ ví không hợp lệ.' });
        }
        return tra(201, await donNap.batDau(email, goi, duLieu));
      }
      const { type, referenceId, description } = duLieu ?? {};
      if (!type || !referenceId || typeof type !== 'string' || typeof referenceId !== 'string') {
        return tra(400, { loi: 'Thiếu type hoặc referenceId.' });
      }
      const kq = thuongCoin(email, type, referenceId, description);
      return tra(kq.ok ? 200 : 409, kq);
    }
    return tra(404, { loi: 'Sai địa chỉ ví.' });
  }

  return { xuLy, thuongCoin, damBaoVi, trangNap: donNap.trangVi, dong: () => db.close() };
}
