import { randomBytes } from 'node:crypto';

const ngayMs = 86_400_000;
export const ngayVietNam = (ms) => Math.floor((ms + 7 * 3_600_000) / ngayMs);
const diaChi = /^0x[0-9a-f]{40}$/;
const maGiaoDich = /^0x[0-9a-f]{64}$/;
const giaPro = 30;
const chainId = '0x7a69';
const rpcUrl = 'http://127.0.0.1:8545';

async function hardhat(method, params = []) {
  const response = await fetch(rpcUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    signal: AbortSignal.timeout(4000),
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
  });
  const json = await response.json();
  if (!response.ok || json.error) throw new Error('Hardhat RPC');
  return json.result;
}

export function taoThuong(db, baiHoc, { gio = Date.now, rpc = hardhat } = {}) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS thuong_hoc (
      email TEXT PRIMARY KEY REFERENCES tai_khoan(email),
      ngay INTEGER NOT NULL, chuoi INTEGER NOT NULL,
      xu INTEGER NOT NULL CHECK(xu >= 0), pro_den INTEGER NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS doi_pro (
      payload TEXT PRIMARY KEY, email TEXT NOT NULL REFERENCES tai_khoan(email),
      vi TEXT NOT NULL, het_han INTEGER NOT NULL, giao_dich TEXT UNIQUE
    ) STRICT;
    CREATE TABLE IF NOT EXISTS luot_ai (
      email TEXT NOT NULL REFERENCES tai_khoan(email), ngay INTEGER NOT NULL,
      so_luot INTEGER NOT NULL, PRIMARY KEY(email, ngay)
    ) STRICT;
  `);
  const docThuong = db.prepare('SELECT * FROM thuong_hoc WHERE email = ?');
  const luuNgay = db.prepare(`
    INSERT INTO thuong_hoc VALUES (?, ?, ?, ?, 0)
    ON CONFLICT(email) DO UPDATE SET ngay=excluded.ngay, chuoi=excluded.chuoi,
      xu=thuong_hoc.xu + excluded.xu
  `);
  const doiXu = db.prepare('UPDATE thuong_hoc SET xu=xu-?, pro_den=? WHERE email=?');
  const luuYeuCau = db.prepare('INSERT INTO doi_pro VALUES (?, ?, ?, ?, NULL)');
  const docYeuCau = db.prepare('SELECT * FROM doi_pro WHERE payload=? AND email=?');
  const xoaYeuCauCu = db.prepare('DELETE FROM doi_pro WHERE email=? AND het_han<=? AND giao_dich IS NULL');
  const docGiaoDich = db.prepare('SELECT email FROM doi_pro WHERE giao_dich=?');
  const xacNhan = db.prepare('UPDATE doi_pro SET giao_dich=? WHERE payload=?');
  const docLuot = db.prepare('SELECT so_luot FROM luot_ai WHERE email=? AND ngay=?');
  const tangLuot = db.prepare(`
    INSERT INTO luot_ai VALUES (?, ?, 1)
    ON CONFLICT(email, ngay) DO UPDATE SET so_luot=so_luot+1
  `);
  const traLuot = db.prepare('UPDATE luot_ai SET so_luot=so_luot-1 WHERE email=? AND ngay=?');

  function giaoDich(fn) {
    db.exec('BEGIN IMMEDIATE');
    try {
      const result = fn();
      db.exec('COMMIT');
      return result;
    } catch (loi) {
      db.exec('ROLLBACK');
      throw loi;
    }
  }

  function trangThai(email, hienTai = gio()) {
    const ngay = ngayVietNam(hienTai);
    const row = docThuong.get(email);
    const proDen = row?.pro_den ?? 0;
    return {
      xu: row?.xu ?? 0,
      chuoi: row && row.ngay >= ngay - 1 ? row.chuoi : 0,
      daHocHomNay: row?.ngay === ngay,
      proDen,
      pro: proDen > hienTai,
      gioiHanAi: proDen > hienTai ? 50 : 10,
      daDungAi: docLuot.get(email, ngay)?.so_luot ?? 0,
    };
  }

  function dungLuotAi(email) {
    const hienTai = gio();
    const ngay = ngayVietNam(hienTai);
    const daDung = giaoDich(() => {
      const quota = trangThai(email, hienTai);
      if (quota.daDungAi >= quota.gioiHanAi) return false;
      tangLuot.run(email, ngay);
      return true;
    });
    return daDung ? () => traLuot.run(email, ngay) : null;
  }

  async function xuLy(email, request, tra, docJson, conPhien) {
    if (request.method === 'GET' && request.url === '/api/account/rewards') {
      return tra(200, trangThai(email));
    }
    if (request.method !== 'POST') return tra(405, { loi: 'Phương thức không hợp lệ.' });
    let duLieu;
    try { duLieu = await docJson(request); } catch {
      return tra(400, { loi: 'JSON không hợp lệ.' });
    }
    if (!conPhien()) return tra(401, { loi: 'Phiên đã hết hạn.' });
    if (request.url === '/api/account/rewards/complete') {
      if (typeof duLieu?.baiHoc !== 'string' || !Object.hasOwn(baiHoc, duLieu.baiHoc)) {
        return tra(404, { loi: 'Không tìm thấy bài học.' });
      }
      const ngay = ngayVietNam(gio());
      const thuong = giaoDich(() => {
        const cu = docThuong.get(email);
        if (cu && cu.ngay >= ngay) return 0;
        const chuoi = cu?.ngay === ngay - 1 ? cu.chuoi + 1 : 1;
        const xu = chuoi === 3 ? 10 : chuoi === 7 ? 20 : 0;
        luuNgay.run(email, ngay, chuoi, xu);
        return xu;
      });
      return tra(200, { ...trangThai(email), thuong });
    }
    if (request.url === '/api/account/rewards/redeem') {
      const vi = typeof duLieu?.vi === 'string' ? duLieu.vi.toLowerCase() : '';
      if (!diaChi.test(vi)) return tra(400, { loi: 'Địa chỉ ví không hợp lệ.' });
      if (trangThai(email).xu < giaPro) return tra(409, { loi: 'Bạn cần ít nhất 30 xu.' });
      const payload = '0x' + Buffer.from('FlutterAcademy: redeem 30 coins for 7 days Pro: ').toString('hex') +
        randomBytes(32).toString('hex');
      xoaYeuCauCu.run(email, gio());
      luuYeuCau.run(payload, email, vi, gio() + ngayMs);
      return tra(200, { payload });
    }
    if (request.url !== '/api/account/rewards/confirm') return tra(404, { loi: 'Sai địa chỉ.' });
    const hash = typeof duLieu?.hash === 'string' ? duLieu.hash.toLowerCase() : '';
    if (!maGiaoDich.test(hash)) return tra(400, { loi: 'Mã giao dịch không hợp lệ.' });
    const daXong = docGiaoDich.get(hash);
    if (daXong?.email === email) return tra(200, trangThai(email));
    if (daXong) return tra(409, { loi: 'Giao dịch đã được dùng.' });

    let tx, receipt;
    try {
      if (await rpc('eth_chainId') !== chainId) throw new Error('Chain ID');
      [tx, receipt] = await Promise.all([
        rpc('eth_getTransactionByHash', [hash]),
        rpc('eth_getTransactionReceipt', [hash]),
      ]);
    } catch {
      return tra(503, { loi: 'Chưa kết nối được mạng Hardhat cục bộ.' });
    }
    if (!conPhien()) return tra(401, { loi: 'Phiên đã hết hạn.' });
    if (!tx || !receipt) return tra(409, { loi: 'Giao dịch chưa được xác nhận. Hãy kiểm tra lại.' });
    const yeuCau = docYeuCau.get(tx.input ?? '', email);
    if (!yeuCau || yeuCau.het_han <= gio() || receipt.status !== '0x1' ||
        receipt.transactionHash?.toLowerCase() !== hash || tx.hash?.toLowerCase() !== hash ||
        tx.from?.toLowerCase() !== yeuCau.vi || tx.to?.toLowerCase() !== yeuCau.vi ||
        tx.value !== '0x0') {
      return tra(400, { loi: 'Giao dịch không khớp yêu cầu đổi Pro.' });
    }
    const ketQua = giaoDich(() => {
      const cu = docGiaoDich.get(hash);
      if (cu?.email === email) return true;
      if (cu || docYeuCau.get(yeuCau.payload, email)?.giao_dich) return false;
      const row = docThuong.get(email);
      if ((row?.xu ?? 0) < giaPro) return false;
      doiXu.run(giaPro, Math.max(row.pro_den, gio()) + 7 * ngayMs, email);
      xacNhan.run(hash, yeuCau.payload);
      return true;
    });
    return ketQua
      ? tra(200, trangThai(email))
      : tra(409, { loi: 'Yêu cầu đã dùng hoặc số xu không đủ.' });
  }
  return { xuLy, dungLuotAi };
}
