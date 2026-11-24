import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { createRequire } from 'node:module';
import { giaoDich } from './streak-rewards.mjs';

const require = createRequire(new URL('../blockchain/package.json', import.meta.url));
export const diaChiHopLe = (value) => typeof value === 'string' && /^0x[\da-f]{40}$/i.test(value);
const hashHopLe = (value) => typeof value === 'string' && /^0x[\da-f]{64}$/i.test(value);
const bam = (value) => createHash('sha256').update(value).digest('hex');
const bang = (a, b) => typeof a === 'string' && typeof b === 'string' && a.toLowerCase() === b.toLowerCase();

export class LoiNapCoin extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function taoDonNapCoin(db, goiNap, capCoin, {
  rpcUrl, contractAddress, depositEventTopic, requiredConfirmations, chainId,
  walletRpcUrl = chainId === 31337 ? 'http://127.0.0.1:8545' : 'https://rpc.sepolia.org',
  goiRpcFetch = fetch,
}) {
  const { Interface, parseEther } = require('ethers');
  const abi = new Interface([
    'function deposit(bytes32 orderId, uint256 packageId) payable',
    'event Deposit(bytes32 indexed orderId,address indexed buyer,uint256 packageId,uint256 amountPaid,uint256 coinAmount,uint256 timestamp)',
  ]);
  const topic = abi.getEvent('Deposit').topicHash;
  const cot = new Set(db.prepare('PRAGMA table_info(deposit_orders)').all().map(({ name }) => name));
  for (const [ten, kieu] of Object.entries({
    chain_id: 'INTEGER', contract_address: 'TEXT', start_block: 'INTEGER', token_hash: 'TEXT', token_expires: 'INTEGER',
  })) {
    if (!cot.has(ten)) db.exec(`ALTER TABLE deposit_orders ADD COLUMN ${ten} ${kieu}`);
  }
  db.exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_deposit_token ON deposit_orders(token_hash)');
  const lay = db.prepare('SELECT * FROM deposit_orders WHERE id = ?');
  const theoToken = db.prepare('SELECT * FROM deposit_orders WHERE token_hash = ?');
  const ganNhat = db.prepare('SELECT * FROM deposit_orders WHERE email = ? ORDER BY rowid DESC LIMIT 1');
  const dangCho = db.prepare(`SELECT * FROM deposit_orders WHERE email = ? AND status != 'completed'
    AND (transaction_hash IS NOT NULL OR (start_block IS NOT NULL AND wallet_address IS NOT NULL)) ORDER BY rowid DESC`);
  const them = db.prepare(`INSERT INTO deposit_orders
    (id,email,wallet_address,package_id,eth_amount,coin_amount,status,chain_id,contract_address,start_block)
    VALUES (?,?,?,?,?,?,?,?,?,?)`);
  const ganToken = db.prepare('UPDATE deposit_orders SET token_hash = ?, token_expires = ? WHERE id = ?');
  const batDauKy = db.prepare("UPDATE deposit_orders SET wallet_address = ?, status = 'signing' WHERE id = ?");
  const capNhat = db.prepare('UPDATE deposit_orders SET status = ?, transaction_hash = ?, confirmed_at = ? WHERE id = ?');
  const daDung = db.prepare('SELECT order_id FROM blockchain_transactions WHERE transaction_hash = ?');
  const daGui = db.prepare('SELECT id FROM deposit_orders WHERE transaction_hash = ? AND id != ?');
  const luuBlockchain = db.prepare(`INSERT INTO blockchain_transactions
    (id,transaction_hash,block_number,from_address,to_address,contract_address,event_name,order_id,status,confirmations)
    VALUES (?,?,?,?,?,?,'Deposit',?,'confirmed',?) ON CONFLICT(transaction_hash) DO UPDATE SET
    status='confirmed', block_number=excluded.block_number, confirmations=excluded.confirmations`);

  async function rpc(method, params = []) {
    const res = await goiRpcFetch(rpcUrl, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
      signal: AbortSignal.timeout(7_000),
    });
    if (!res.ok) throw new LoiNapCoin(503, 'Chưa kết nối được mạng thanh toán. Hãy thử lại.');
    const json = await res.json();
    if (json.error || !Object.hasOwn(json, 'result')) {
      throw new LoiNapCoin(503, 'Mạng thanh toán chưa trả được dữ liệu. Hãy thử lại.');
    }
    return json.result;
  }

  async function kiemTraMang() {
    if (![31337, 11155111].includes(chainId) || !diaChiHopLe(contractAddress) ||
        (depositEventTopic && !bang(depositEventTopic, topic))) {
      throw new LoiNapCoin(503, 'Máy chủ chưa cấu hình hợp đồng nạp trên mạng thử nghiệm.');
    }
    if (Number(await rpc('eth_chainId')) !== chainId) {
      throw new LoiNapCoin(503, 'Mạng thanh toán khác với cấu hình. Hãy thử lại sau.');
    }
  }

  function thongTin(don) {
    if (!don) return null;
    return {
      orderId: don.id, email: don.email, walletAddress: don.wallet_address, packageId: don.package_id,
      ethAmount: don.eth_amount, coinAmount: don.coin_amount, transactionHash: don.transaction_hash,
      status: don.status, createdAt: don.created_at, confirmedAt: don.confirmed_at,
      chainId: don.chain_id ?? chainId, contractAddress: don.contract_address ?? contractAddress,
    };
  }

  function cuaToi(email, id) {
    const don = lay.get(id);
    if (!don || don.email !== email) throw new LoiNapCoin(404, 'Không tìm thấy đơn nạp.');
    return don;
  }

  function thuocMang(don) {
    return (don.chain_id ?? chainId) === chainId && bang(don.contract_address ?? contractAddress, contractAddress);
  }

  function guiHash(don, txHash) {
    if (!hashHopLe(txHash)) throw new LoiNapCoin(400, 'Mã giao dịch không hợp lệ.');
    txHash = txHash.toLowerCase();
    return giaoDich(db, () => {
      const hienTai = lay.get(don.id);
      if (hienTai.status === 'completed' || hienTai.transaction_hash === txHash) return thongTin(hienTai);
      if (hienTai.transaction_hash || daGui.get(txHash, don.id) ||
          (daDung.get(txHash) && daDung.get(txHash).order_id !== don.id)) {
        throw new LoiNapCoin(409, 'Đơn hoặc giao dịch đã được gửi. Hãy kiểm tra trạng thái.');
      }
      capNhat.run('submitted', txHash, null, don.id);
      return thongTin(lay.get(don.id));
    });
  }

  async function doiSoat(don) {
    if (don.status === 'completed' || (!don.transaction_hash && (don.start_block == null || !don.wallet_address))) return thongTin(don);
    if (!thuocMang(don)) throw new LoiNapCoin(409, 'Đơn nạp thuộc một mạng hoặc hợp đồng khác.');
    await kiemTraMang();
    let hash = don.transaction_hash;
    if (!hash) {
      const logs = await rpc('eth_getLogs', [{
        address: contractAddress, topics: [topic, don.id, '0x' + don.wallet_address.slice(2).padStart(64, '0')],
        fromBlock: '0x' + don.start_block.toString(16), toBlock: 'latest',
      }]);
      hash = logs.find((log) => !log.removed)?.transactionHash;
      if (!hash) return thongTin(lay.get(don.id));
    }
    const [receipt, giaoDichVi] = await Promise.all([
      rpc('eth_getTransactionReceipt', [hash]), rpc('eth_getTransactionByHash', [hash]),
    ]);
    if (!receipt) return thongTin(lay.get(don.id));
    if (!giaoDichVi) throw new LoiNapCoin(503, 'Mạng thanh toán chưa trả đủ dữ liệu giao dịch. Hãy thử lại.');
    const goi = goiNap.find((muc) => muc.id === don.package_id);
    const diaChi = don.wallet_address ?? receipt.from;
    const log = receipt.logs.find((muc) => !muc.removed && bang(muc.address, contractAddress) &&
      bang(muc.topics[0], topic) && bang(muc.topics[1], don.id));
    let ketQua;
    try { if (log) ketQua = abi.decodeEventLog('Deposit', log.data, log.topics); } catch { /* Event sai cấu trúc. */ }
    const hopLe = goi && ketQua && receipt.status === '0x1' && bang(receipt.transactionHash, hash) &&
      bang(giaoDichVi.hash, hash) && bang(giaoDichVi.blockHash, receipt.blockHash) &&
      (giaoDichVi.chainId == null || Number(giaoDichVi.chainId) === chainId) &&
      diaChiHopLe(diaChi) && bang(receipt.from, diaChi) && bang(giaoDichVi.from, diaChi) && bang(ketQua.buyer, diaChi) &&
      bang(receipt.to, contractAddress) && bang(giaoDichVi.to, contractAddress) &&
      bang(giaoDichVi.input, abi.encodeFunctionData('deposit', [don.id, goi.maHopDong])) &&
      ketQua.packageId === BigInt(goi.maHopDong) && ketQua.coinAmount === BigInt(don.coin_amount) &&
      ketQua.amountPaid === BigInt(giaoDichVi.value) && ketQua.amountPaid >= parseEther(don.eth_amount);
    const block = Number(receipt.blockNumber);
    const confirmations = hopLe ? Number(await rpc('eth_blockNumber')) - block : 0;
    return giaoDich(db, () => {
      const hienTai = lay.get(don.id);
      if (hienTai.status === 'completed') return thongTin(hienTai);
      if (hienTai.transaction_hash !== don.transaction_hash && !bang(hienTai.transaction_hash, hash)) return thongTin(hienTai);
      const cu = daDung.get(hash);
      if (!hopLe || (cu && cu.order_id !== don.id)) {
        capNhat.run('failed', null, null, don.id);
      } else if (confirmations < requiredConfirmations) {
        capNhat.run('confirming', hash, null, don.id);
      } else {
        luuBlockchain.run(randomUUID(), hash, block, diaChi, receipt.to, contractAddress, don.id, confirmations);
        capCoin(don, hash, diaChi);
        capNhat.run('completed', hash, new Date().toISOString(), don.id);
      }
      return thongTin(lay.get(don.id));
    });
  }

  async function batDau(email, goi, { walletAddress = null, checkout = false, orderId } = {}) {
    let khoiDiem = null;
    if (checkout) {
      const cu = orderId ? cuaToi(email, orderId) : ganNhat.get(email);
      if (cu && cu.status !== 'completed' && cu.package_id === goi.id) {
        const trangThai = await doiSoat(cu);
        if (trangThai.status === 'completed') return trangThai;
      }
      await kiemTraMang();
      const [block, code] = await Promise.all([rpc('eth_blockNumber'), rpc('eth_getCode', [contractAddress, 'latest'])]);
      if (!code || code === '0x') throw new LoiNapCoin(503, 'Hợp đồng nạp chưa sẵn sàng trên mạng thử nghiệm.');
      khoiDiem = Number(block);
    }
    return giaoDich(db, () => {
      let don = orderId ? cuaToi(email, orderId) : checkout ? ganNhat.get(email) : null;
      if (!checkout || !don || (!orderId && (don.package_id !== goi.id || don.status === 'completed'))) {
        const id = '0x' + randomBytes(32).toString('hex');
        them.run(id, email, walletAddress, goi.id, goi.ethAmount, goi.coinAmount,
          checkout ? 'signing' : 'pending', chainId, contractAddress, khoiDiem);
        don = lay.get(id);
      }
      if (don.package_id !== goi.id || !thuocMang(don)) throw new LoiNapCoin(409, 'Thông tin đơn nạp đã thay đổi.');
      const thongTinDon = thongTin(don);
      if (!checkout || ['completed', 'submitted', 'confirming'].includes(don.status)) return thongTinDon;
      if (don.start_block == null) {
        db.prepare('UPDATE deposit_orders SET start_block = ? WHERE id = ?').run(khoiDiem, don.id);
      }
      const token = 'nap_' + randomBytes(32).toString('hex');
      ganToken.run(bam(token), Date.now() + 10 * 60_000, don.id);
      return { ...thongTinDon, path: `/meta/vi#${token}` };
    });
  }

  async function trangVi({ token, action, address, txHash, status }) {
    const don = /^nap_[\da-f]{64}$/.test(token) ? theoToken.get(bam(token)) : null;
    if (!don || don.token_expires <= Date.now() || ['completed', 'submitted', 'confirming'].includes(don.status)) {
      throw new LoiNapCoin(410, 'Phiên thanh toán đã dùng hoặc hết hạn. Mở lại từ Flutter Academy.');
    }
    if (!thuocMang(don)) throw new LoiNapCoin(409, 'Đơn nạp thuộc mạng hoặc hợp đồng khác.');
    if (action === 'open') return {
      operation: 'deposit', wallet: don.wallet_address, rpcUrl: walletRpcUrl,
      chainId: '0x' + chainId.toString(16), networkName: chainId === 31337 ? 'Hardhat Local' : 'Sepolia',
      to: contractAddress, coinAmount: don.coin_amount, ethAmount: don.eth_amount,
      value: '0x' + parseEther(don.eth_amount).toString(16),
      data: abi.encodeFunctionData('deposit', [don.id, goiNap.find((muc) => muc.id === don.package_id).maHopDong]),
    };
    if (action === 'prepare') {
      if (!diaChiHopLe(address) || (don.wallet_address && !bang(don.wallet_address, address))) {
        throw new LoiNapCoin(409, 'Chọn tài khoản ví đã dùng cho đơn nạp này.');
      }
      const kq = await doiSoat(don);
      if (['completed', 'submitted', 'confirming'].includes(kq.status)) throw new LoiNapCoin(409, 'Giao dịch đã được gửi. Hãy kiểm tra trong ứng dụng.');
      return giaoDich(db, () => {
        const hienTai = lay.get(don.id);
        if (hienTai.token_hash !== don.token_hash || hienTai.token_expires <= Date.now() ||
            ['completed', 'submitted', 'confirming'].includes(hienTai.status) ||
            (hienTai.wallet_address && !bang(hienTai.wallet_address, address))) {
          throw new LoiNapCoin(409, 'Phiên thanh toán đã thay đổi. Mở lại từ ứng dụng.');
        }
        batDauKy.run(address.toLowerCase(), don.id);
        return { ok: true };
      });
    }
    if (action === 'signed' && don.wallet_address) return guiHash(don, txHash);
    if (action === 'result' && ['rejected', 'failed'].includes(status)) {
      capNhat.run(status, null, null, don.id);
      return { ok: true };
    }
    throw new LoiNapCoin(400, 'Kết quả thanh toán không hợp lệ.');
  }

  async function kiemTraGanNhat(email) {
    // Đối soát cả đơn cũ có thể đang chờ khi học viên đã chọn gói khác.
    for (const don of dangCho.all(email)) {
      if (thuocMang(don)) await doiSoat(don);
    }
    return thongTin(ganNhat.get(email));
  }

  return { cuaToi, thongTin, batDau, guiHash, doiSoat, trangVi, kiemTraGanNhat };
}
