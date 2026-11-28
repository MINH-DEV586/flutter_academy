import { createHash } from 'node:crypto';
import { giaoDich } from './streak-rewards.mjs';

export function taoSoCoinChung(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS coin_credits (
      id TEXT PRIMARY KEY, email TEXT NOT NULL REFERENCES tai_khoan(email),
      amount INTEGER NOT NULL CHECK(amount > 0),
      status TEXT NOT NULL DEFAULT 'claiming', tx_hash TEXT
    ) STRICT;
    CREATE INDEX IF NOT EXISTS idx_coin_credits_email ON coin_credits(email, status);
    CREATE TABLE IF NOT EXISTS coin_chain_upgrade (
      id INTEGER PRIMARY KEY CHECK(id = 1),
      old_contract TEXT NOT NULL, new_contract TEXT NOT NULL,
      snapshot_block INTEGER NOT NULL, instance_id TEXT NOT NULL
    ) STRICT;
  `);
  const them = db.prepare('INSERT OR IGNORE INTO coin_credits (id,email,amount) VALUES (?,?,?)');
  const themNhatKy = db.prepare(`INSERT INTO coin_transactions
    (id,email,type,amount,balance_before,balance_after,status,description,reference_id,transaction_hash)
    VALUES (?,?,?,?,0,0,'pending',?,?,?)`);
  const tim = db.prepare('SELECT status FROM coin_credits WHERE id = ?');
  const lay = db.prepare("SELECT * FROM coin_credits WHERE email = ? AND status != 'issued' ORDER BY rowid");
  const capNhat = db.prepare("UPDATE coin_credits SET status = ?, tx_hash = ? WHERE id = ? AND status != 'issued'");
  const capNhatNhatKy = db.prepare(`UPDATE coin_transactions
    SET status = 'completed', balance_before = ?, balance_after = ?, transaction_hash = COALESCE(transaction_hash, ?)
    WHERE id = ?`);
  const tongCho = db.prepare("SELECT COALESCE(SUM(amount),0) AS coin FROM coin_credits WHERE email = ? AND status != 'issued'");

  function maCoin(loai, email, thamChieu) {
    return '0x' + createHash('sha256').update(JSON.stringify([loai, email, thamChieu])).digest('hex');
  }

  function ghiNhan({ email, loai, thamChieu, coin, moTa, txHash = null }) {
    const id = maCoin(loai, email, thamChieu);
    if (them.run(id, email, coin).changes) {
      themNhatKy.run(id, email, loai, coin, moTa, thamChieu, txHash);
    }
    return id;
  }

  function hoanTat(credit, txHash, soDu) {
    giaoDich(db, () => {
      if (capNhat.run('issued', txHash, credit.id).changes) {
        capNhatNhatKy.run(Math.max(0, soDu - credit.amount), soDu, txHash, credit.id);
      }
    });
  }

  return {
    ghiNhan, hoanTat,
    capNhat,
    dangCho: (email) => lay.all(email),
    coinCho: (email) => tongCho.get(email).coin,
    dangCapNap: (email, orderId) => {
      const credit = tim.get(maCoin('DEPOSIT', email, orderId));
      return !!credit && credit.status !== 'issued';
    },
    nangCap: () => db.prepare('SELECT * FROM coin_chain_upgrade WHERE id = 1').get(),
  };
}
