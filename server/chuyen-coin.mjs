import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { DatabaseSync } from 'node:sqlite';
import { taoSoCoinChung } from './coin-chung.mjs';
import { taoThuongOnChain } from './reward-chain.mjs';
import { giaoDich } from './streak-rewards.mjs';
import { taoThanhVien } from './subscription.mjs';

const require = createRequire(new URL('../blockchain/package.json', import.meta.url));
const { Contract, ContractFactory, FetchRequest, JsonRpcProvider, Wallet } = require('ethers');

async function doiSoat(db, rpc, cu, chuVi) {
  const block = await rpc.getBlockNumber();
  const tuyChon = { blockTag: block };
  const viDaXacMinh = new Map(db.prepare('SELECT email, wallet FROM verified_reward_wallets')
    .all().map(({ email, wallet }) => [wallet.toLowerCase(), email]));
  const cacVi = new Set([...viDaXacMinh.keys(), chuVi]);
  if (db.prepare(`SELECT 1 FROM reward_wallet_sessions AS s JOIN pro_redemptions AS p ON p.id = s.request_id
    WHERE lower(p.contract) = ? AND p.status != 'completed'
      AND s.status = 'signing' AND s.expires_ms > ?`).get(cu.target, Date.now())) {
    throw new Error('Còn phiên MetaMask đổi Pro trên hợp đồng cũ. Cần đối soát trước khi chuyển Coin.');
  }
  const soGiaoDich = (vi, moc) => rpc.getTransactionCount(vi, moc);
  for (const vi of cacVi) {
    if (await soGiaoDich(vi, 'latest') !== await soGiaoDich(vi, 'pending')) {
      throw new Error('Còn giao dịch Hardhat chưa được xác nhận. Giữ nguyên hợp đồng Coin đang dùng.');
    }
  }
  async function dangCho(hash) {
    return hash && await rpc.getTransaction(hash) && !await rpc.getTransactionReceipt(hash);
  }
  for (const don of db.prepare(`SELECT id, tx_hash FROM pro_redemptions
    WHERE chain = 31337 AND lower(contract) = ? AND status != 'completed'`).all(cu.target)) {
    if (await cu.redeemed(don.id) || await dangCho(don.tx_hash)) {
      throw new Error('Có yêu cầu đổi Pro cũ cần backend đối soát trước khi chuyển Coin.');
    }
  }
  const thuongDaCap = [];
  const thuongGuiLai = [];
  for (const thuong of db.prepare("SELECT id, email, amount, tx_hash FROM reward_mints WHERE status != 'issued'").all()) {
    if (await cu.awarded(thuong.id, tuyChon)) {
      const [log] = await cu.queryFilter(cu.filters.RewardIssued(thuong.id), 0, block);
      if (!log || log.args.amount !== BigInt(thuong.amount) ||
          viDaXacMinh.get(log.args.wallet.toLowerCase()) !== thuong.email) {
        throw new Error('Bản ghi thưởng cũ không khớp giao dịch Hardhat.');
      }
      thuongDaCap.push({ id: thuong.id, hash: log.transactionHash });
    } else if (await dangCho(thuong.tx_hash)) {
      throw new Error('Còn giao dịch cấp thưởng cũ chưa xác nhận.');
    } else if (thuong.tx_hash) {
      thuongGuiLai.push(thuong.id);
    }
  }
  const viDaNhan = new Set((await cu.queryFilter(cu.filters.RewardIssued(), 0, block))
    .map(({ args }) => args.wallet.toLowerCase()));
  const credits = [];
  for (const vi of viDaNhan) {
    const coin = Number(await cu.balanceOf(vi, tuyChon));
    if (!coin) continue;
    const email = viDaXacMinh.get(vi);
    if (!email || !Number.isSafeInteger(coin)) throw new Error('Có số dư Hardhat cũ chưa đối chiếu được với tài khoản.');
    credits.push({ email, coin, thamChieu: `hardhat:${cu.target}`, moTa: 'Chuyển số dư Coin từ hợp đồng cũ' });
  }
  for (const { email, coin } of db.prepare('SELECT email, coin_balance AS coin FROM wallets WHERE coin_balance > 0').all()) {
    credits.push({ email, coin, thamChieu: `sqlite:${cu.target}`, moTa: 'Chuyển số dư Coin trong ứng dụng' });
  }
  return { block, credits, viDaXacMinh, thuongDaCap, thuongGuiLai };
}

async function chuyenCoin(path, rpcUrl, chiDoiSoat) {
  if (!path || !rpcUrl || !existsSync(path)) throw new Error('Cần truyền đường dẫn SQLite hiện có và RPC Hardhat.');
  const db = new DatabaseSync(path, { readOnly: chiDoiSoat });
  const ketNoi = new FetchRequest(rpcUrl);
  ketNoi.timeout = 8_000;
  const rpc = new JsonRpcProvider(ketNoi, 31337, { staticNetwork: true, batchMaxCount: 1, cacheTimeout: -1 });
  let thuong;
  try {
    const cauHinh = db.prepare('SELECT instance_id, reward_address FROM video_demo WHERE id = 1').get();
    const chain = await rpc.send('hardhat_metadata', []);
    if (chain.chainId !== 31337 || !chain.instanceId || chain.instanceId !== cauHinh?.instance_id) {
      throw new Error('Hardhat không khớp phiên đã lưu của backend.');
    }
    const oldAddress = cauHinh.reward_address.toLowerCase();
    const { abi, bytecode } = require('./artifacts/contracts/FlutterAcademyRewards.sol/FlutterAcademyRewards.json');
    const cu = new Contract(oldAddress, abi, rpc);
    const issuerKey = process.env.REWARD_ISSUER_PRIVATE_KEY;
    const signer = issuerKey ? new Wallet(issuerKey, rpc) : await rpc.getSigner(0);
    const chuVi = (await signer.getAddress()).toLowerCase();
    if ((await cu.owner()).toLowerCase() !== chuVi) throw new Error('Ví cấp Coin không khớp hợp đồng cũ.');

    const coNangCap = db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'coin_chain_upgrade'").get();
    let daChuyen = coNangCap && db.prepare('SELECT * FROM coin_chain_upgrade WHERE id = 1').get();
    if (daChuyen && (daChuyen.old_contract !== oldAddress || daChuyen.instance_id !== chain.instanceId ||
        await rpc.getCode(daChuyen.new_contract) === '0x')) {
      throw new Error('Thông tin hợp nhất đã lưu không khớp Hardhat hiện tại.');
    }
    const anhChup = daChuyen ? null : await doiSoat(db, rpc, cu, chuVi);
    if (chiDoiSoat) {
      console.log(JSON.stringify({
        oldContract: oldAddress, newContract: daChuyen?.new_contract,
        block: anhChup?.block, creditCount: anhChup?.credits.length ?? 0,
        totalLegacyCoin: anhChup?.credits.reduce((total, { coin }) => total + coin, 0),
      }));
      return;
    }
    db.exec('PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 3000;');
    const soCoin = taoSoCoinChung(db);
    if (!daChuyen) {
      const moi = await new ContractFactory(abi, bytecode, signer).deploy();
      await moi.waitForDeployment();
      const newAddress = (await moi.getAddress()).toLowerCase();
      giaoDich(db, () => {
        const daCap = db.prepare("UPDATE reward_mints SET status = 'issued', tx_hash = ? WHERE id = ?");
        const guiLai = db.prepare("UPDATE reward_mints SET tx_hash = NULL, status = 'claiming' WHERE id = ?");
        for (const { id, hash } of anhChup.thuongDaCap) daCap.run(hash, id);
        for (const id of anhChup.thuongGuiLai) guiLai.run(id);
        for (const credit of anhChup.credits) soCoin.ghiNhan({ ...credit, loai: 'MIGRATION' });
        db.prepare('INSERT INTO coin_chain_upgrade VALUES (1, ?, ?, ?, ?)')
          .run(oldAddress, newAddress, anhChup.block, chain.instanceId);
      });
      daChuyen = soCoin.nangCap();
    }
    const ngayGio = () => new Date();
    thuong = taoThuongOnChain(db, taoThanhVien(db, ngayGio, { coinChung: true }), ngayGio, {
      address: oldAddress, rpcUrl, issuerKey, soCoin,
    });
    let dangCho = 0;
    for (const { email } of db.prepare('SELECT DISTINCT c.email FROM coin_credits AS c WHERE c.status != ?').all('issued')) {
      const trangThai = await thuong.trangThai(email);
      dangCho += trangThai.creditPending;
    }
    console.log(JSON.stringify({ newContract: daChuyen.new_contract, snapshotBlock: daChuyen.snapshot_block, creditPending: dangCho }));
  } finally {
    thuong?.dong();
    rpc.destroy();
    db.close();
  }
}

try {
  const [, , path, rpcUrl, mode] = process.argv;
  await chuyenCoin(path, rpcUrl, mode === '--preflight');
} catch (loi) {
  console.error(loi.shortMessage ?? loi.message);
  process.exitCode = 1;
}
