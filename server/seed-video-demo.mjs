import { once } from 'node:events';
import { mkdirSync, readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import { taoBamMatKhau } from './account.mjs';
import { docCauHinhTutor, taoMayChu } from './ai-tutor.mjs';
import { ngayVietNam } from './ngay-viet-nam.mjs';
import { giaoDich, taoChuoiThuong } from './streak-rewards.mjs';

const require = createRequire(new URL('../blockchain/package.json', import.meta.url));
const { Contract, ContractFactory, FetchRequest, JsonRpcProvider, formatEther, hexlify, isAddress, parseEther, toUtf8Bytes } = require('ethers');
const email = 'demo@example.com';
const khoaHoc = 'flutter-nhap-mon';
const baiDeQuay = `${khoaHoc}/b2`;
const kho = process.env.ACADEMY_DEMO_RUN === 'android-qa'
  ? new URL('../build/demo-android-qa/', import.meta.url)
  : process.env.ACADEMY_DEMO_RUN === 'video-20261127'
    ? new URL('../build/demo-video-20261127/', import.meta.url)
    : new URL('../build/demo-video/', import.meta.url);
const dbPath = fileURLToPath(new URL('accounts.sqlite', kho));
const rpcUrl = 'http://127.0.0.1:18545';
const port = 18785;
const chuaNhan = process.argv.includes('--chua-nhan');
const cauHinhTutor = docCauHinhTutor();

async function moBackend(depositAddress, rewardAddress) {
  const rpcVi = 'http://127.0.0.1:8545';
  const app = taoMayChu({
    ...cauHinhTutor,
    accountDb: dbPath,
    thuongBlockchain: { address: rewardAddress, rpcUrl, rpcDienThoai: rpcVi },
    cauHinhBlockchain: { contractAddress: depositAddress, rpcUrl, chainId: 31337, walletRpcUrl: rpcVi },
  });
  app.listen(port, '127.0.0.1');
  await once(app, 'listening');
  return app;
}

async function phucVuDuLieuHienTai() {
  const db = new DatabaseSync(dbPath, { readOnly: true });
  let cauHinh;
  try {
    cauHinh = db.prepare('SELECT reward_address, deposit_address FROM video_demo WHERE id = 1').get();
  } finally {
    db.close();
  }
  if (!cauHinh) throw new Error('Chưa có cấu hình backend demo đã lưu.');
  await moBackend(cauHinh.deposit_address, cauHinh.reward_address);
  console.log(`Backend demo đang chạy tại cổng ${port} với dữ liệu hiện tại.`);
}

function docHopDong(ten) {
  try {
    return require(`./artifacts/contracts/${ten}.sol/${ten}.json`);
  } catch (loi) {
    if (loi.code !== 'MODULE_NOT_FOUND') throw loi;
    throw new Error('Chạy npm --prefix blockchain run compile để tạo artifact hợp đồng.');
  }
}

function coBang(db, ten) {
  return !!db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?").get(ten);
}

function kiemTraCoSoDuLieu(db) {
  if (coBang(db, 'tai_khoan') && db.prepare('SELECT 1 FROM tai_khoan WHERE email != ?').get(email)) {
    throw new Error('Cơ sở dữ liệu quay chứa tài khoản khác. Giữ nguyên dữ liệu.');
  }
}

async function kiemTraDonCho(db, rpc, vi, hopDongCu, hienTai) {
  const phienCho = coBang(db, 'reward_wallet_sessions') && db.prepare(
    "SELECT 1 FROM reward_wallet_sessions WHERE email = ? AND status = 'signing' AND expires_ms > ?",
  ).get(email, hienTai);
  const napCho = coBang(db, 'deposit_orders') && db.prepare(
    "SELECT 1 FROM deposit_orders WHERE email = ? AND (status IN ('pending','signing','submitted','confirming') OR (status != 'completed' AND transaction_hash IS NOT NULL))",
  ).get(email);
  const doiCho = coBang(db, 'pro_redemptions') ? db.prepare(
    "SELECT id, status, tx_hash FROM pro_redemptions WHERE email = ? AND status != 'completed'",
  ).all(email) : [];
  const mintCho = coBang(db, 'reward_mints') && db.prepare(
    "SELECT 1 FROM reward_mints WHERE email = ? AND status IN ('claiming','submitted')",
  ).get(email);
  const [nonce, nonceCho] = await Promise.all([
    rpc.getTransactionCount(vi, 'latest'), rpc.getTransactionCount(vi, 'pending'),
  ]);
  if (phienCho || napCho || mintCho || nonce !== nonceCho ||
      doiCho.some((don) => don.status === 'confirming' || don.tx_hash)) {
    throw new Error('Tài khoản demo có phiên ví hoặc giao dịch đang chờ. Hãy đối soát trước khi gieo lại.');
  }
  for (const don of doiCho) {
    if (!hopDongCu || await hopDongCu.redeemed(don.id)) {
      throw new Error('Chưa đối soát được yêu cầu đổi Pro cũ. Giữ nguyên dữ liệu demo.');
    }
  }
}

async function taoTrangThai(db, rpc, chain, vi, ngay, cacNgay) {
  const thuong = docHopDong('FlutterAcademyRewards');
  const cu = coBang(db, 'video_demo') ? db.prepare('SELECT * FROM video_demo').get() : null;
  const mangCu = cu?.instance_id === chain.instanceId;
  const hopDongCu = mangCu && await rpc.getCode(cu.reward_address) !== '0x'
    ? new Contract(cu.reward_address, thuong.abi, rpc) : null;
  await kiemTraDonCho(db, rpc, vi, hopDongCu, Date.now());
  const viDaLuu = coBang(db, 'verified_reward_wallets')
    ? db.prepare('SELECT wallet FROM verified_reward_wallets WHERE email = ?').get(email)?.wallet
    : null;
  if (viDaLuu && viDaLuu !== vi) throw new Error('Địa chỉ ví khác với ví đã xác minh cho tài khoản demo.');

  const ngayCu = coBang(db, 'reward_days')
    ? db.prepare('SELECT day, day_count FROM reward_days WHERE email = ? ORDER BY day').all(email) : [];
  const mint = coBang(db, 'reward_mints')
    ? db.prepare('SELECT id, milestone, amount, status FROM reward_mints WHERE email = ?').all(email) : [];
  const coDonCu = coBang(db, 'pro_redemptions') && db.prepare('SELECT 1 FROM pro_redemptions WHERE email = ?').get(email);
  const coGoiCu = coBang(db, 'user_subscriptions') && db.prepare('SELECT 1 FROM user_subscriptions WHERE email = ?').get(email);
  const soDu = hopDongCu ? await hopDongCu.balanceOf(vi) : 0n;
  const dungMint = mint.length <= 1 && (!mint.length ||
    (mint[0].milestone === 3 && mint[0].amount === 10 &&
      (soDu === 10n ? await hopDongCu.awarded(mint[0].id) : mint[0].status === 'pending')));
  const dungChuoi = ngayCu.length <= 6 &&
    ngayCu.every((row, index) => row.day === cacNgay[index] && row.day_count === index + 1);
  const giuThuong = !process.argv.includes('--reset') &&
    !!hopDongCu && cu.day === ngay && dungChuoi && dungMint &&
    !coDonCu && !coGoiCu && (soDu === 0n || (!chuaNhan && soDu === 10n && mint.length === 1));
  if (!giuThuong && coBang(db, 'coin_transactions') && db.prepare(
    "SELECT 1 FROM coin_transactions WHERE email = ? AND type != 'REWARD'",
  ).get(email)) {
    throw new Error('Ví trong ứng dụng có giao dịch ngoài thưởng học tập. Hãy đối soát trước khi đặt lại.');
  }

  const signer = await rpc.getSigner(0);
  async function trienKhai(artifact) {
    const contract = await new ContractFactory(artifact.abi, artifact.bytecode, signer).deploy();
    await contract.waitForDeployment();
    return contract.getAddress();
  }
  const depositAddress = mangCu && await rpc.getCode(cu.deposit_address) !== '0x'
    ? cu.deposit_address : await trienKhai(docHopDong('FlutterAcademyDeposit'));
  const rewardAddress = giuThuong ? cu.reward_address : await trienKhai(thuong);
  return { rewardAddress, depositAddress, giuThuong };
}

async function chuanBi() {
  const matKhau = process.env.ACADEMY_DEMO_PASSWORD;
  const diaChiVi = process.env.ACADEMY_DEMO_WALLET?.toLowerCase();
  if (!matKhau || matKhau.length < 12 || matKhau.length > 128 || !isAddress(diaChiVi)) {
    throw new Error('Đặt ACADEMY_DEMO_PASSWORD (12–128 ký tự) và ACADEMY_DEMO_WALLET (địa chỉ ví Hardhat đã nhập vào MetaMask).');
  }
  mkdirSync(kho, { recursive: true });
  const db = new DatabaseSync(dbPath);
  db.exec('PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 3000;');
  const ketNoi = new FetchRequest(rpcUrl);
  ketNoi.timeout = 5_000;
  const rpc = new JsonRpcProvider(ketNoi, 31337, { staticNetwork: true, batchMaxCount: 1, cacheTimeout: -1 });
  let app;
  let giuMayChu = false;
  try {
    if (coBang(db, 'coin_chain_upgrade') && db.prepare('SELECT id FROM coin_chain_upgrade WHERE id = 1').get()) {
      throw new Error('Dữ liệu đã hợp nhất Coin. Dùng --serve-existing để khởi động lại backend.');
    }
    kiemTraCoSoDuLieu(db);
    const chain = await rpc.send('hardhat_metadata', []);
    if (chain.chainId !== 31337 || !chain.instanceId) throw new Error('Cần Hardhat Local 31337 tại cổng 18545.');
    const cacVi = (await rpc.send('eth_accounts', [])).map((vi) => vi.toLowerCase());
    if (!cacVi.slice(1).includes(diaChiVi)) throw new Error('Ví demo phải là một tài khoản thử Hardhat, khác ví deploy.');
    const eth = await rpc.getBalance(diaChiVi);
    if (eth < parseEther('0.05')) throw new Error('Ví demo cần ít nhất 0,05 ETH Hardhat để trả phí.');

    const bayGio = new Date();
    const { ngay, ngayTruoc } = ngayVietNam(bayGio);
    const thoiDiemGieo = Array.from({ length: 6 }, (_, i) => new Date(bayGio.getTime() - (6 - i) * 86_400_000));
    const cacNgay = thoiDiemGieo.map((moc) => ngayVietNam(moc).ngay);
    const { rewardAddress, depositAddress, giuThuong } = await taoTrangThai(db, rpc, chain, diaChiVi, ngay, cacNgay);
    app = await moBackend(depositAddress, rewardAddress);

    let sessionToken;
    async function gui(path, method = 'GET', body, choPhep) {
      const headers = { 'Content-Type': 'application/json' };
      if (sessionToken) headers.Authorization = `Bearer ${sessionToken}`;
      const res = await fetch(`http://127.0.0.1:${port}${path}`, {
        method, headers, body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(15_000),
      });
      const data = await res.json();
      if (!res.ok && res.status !== choPhep) throw new Error(`${path} HTTP ${res.status}: ${data.loi ?? 'Lỗi máy chủ.'}`);
      return { status: res.status, data };
    }
    const taiKhoan = { email, matKhau, hoTen: 'Flutter Academy Demo' };
    if (db.prepare('SELECT 1 FROM tai_khoan WHERE email = ?').get(email)) {
      const kq = await gui('/api/account/login', 'POST', taiKhoan, 401);
      sessionToken = kq.data.token;
      if (kq.status === 401) {
        const { salt, maBam } = await taoBamMatKhau(matKhau);
        giaoDich(db, () => {
          db.prepare('UPDATE tai_khoan SET salt = ?, mat_khau = ? WHERE email = ?').run(salt, maBam, email);
          db.prepare('DELETE FROM phien WHERE email = ?').run(email);
        });
      }
    } else {
      sessionToken = (await gui('/api/account/register', 'POST', taiKhoan)).data.token;
      await gui('/api/account/session', 'DELETE');
      sessionToken = undefined;
    }
    sessionToken ??= (await gui('/api/account/login', 'POST', taiKhoan)).data.token;
    if (!sessionToken) throw new Error('Chưa xác nhận được đăng nhập tài khoản demo.');

    giaoDich(db, () => {
      kiemTraCoSoDuLieu(db);
      if (!giuThuong) {
        for (const bang of ['reward_wallet_sessions', 'pro_redemptions', 'reward_mints', 'reward_completions', 'reward_days', 'user_subscriptions', 'streak_nguoi_dung']) {
          db.prepare(`DELETE FROM ${bang} WHERE email = ?`).run(email);
        }
        db.prepare("DELETE FROM coin_transactions WHERE email = ? AND type = 'REWARD'").run(email);
        db.prepare("UPDATE wallets SET coin_balance = 0, updated_at = datetime('now') WHERE email = ?").run(email);
      }
      db.prepare('DELETE FROM tutor_usage WHERE email = ? AND day = ?').run(email, ngay);
      db.exec(`CREATE TABLE IF NOT EXISTS video_demo (
        id INTEGER PRIMARY KEY CHECK (id = 1), day TEXT NOT NULL, instance_id TEXT NOT NULL,
        reward_address TEXT NOT NULL, deposit_address TEXT NOT NULL
      ) STRICT`);
      db.prepare('INSERT OR REPLACE INTO video_demo VALUES (1, ?, ?, ?, ?)').run(ngay, chain.instanceId, rewardAddress, depositAddress);
    });

    if (!db.prepare('SELECT connected FROM verified_reward_wallets WHERE email = ?').get(email)?.connected) {
      const { data: { path } } = await gui('/api/rewards/link', 'POST');
      const token = path.split('#')[1];
      const { data: { message } } = await gui('/meta/vi/session', 'POST', { action: 'open', token });
      const signature = await rpc.send('eth_sign', [diaChiVi, hexlify(toUtf8Bytes(message))]);
      await gui('/meta/vi/session', 'POST', { action: 'signed', token, address: diaChiVi, signature });
    }

    const bai = JSON.parse(readFileSync(new URL('../assets/bai_hoc_ai.json', import.meta.url), 'utf8'));
    let time;
    const chuoi = taoChuoiThuong(db, bai, () => time);
    for (const [index, moc] of thoiDiemGieo.entries()) {
      time = moc;
      const { status, body } = chuoi.ghiNhan(email, {
        eventId: `video-demo-${cacNgay[index]}-hoan-thanh`, lesson: `${khoaHoc}/b1`, from: false, to: true,
      });
      if (status !== 200) throw new Error(body.loi);
    }
    await gui('/api/account/enrollments', 'POST', { maKhoaHoc: khoaHoc });

    let { data: thuong } = await gui('/api/rewards');
    if (!chuaNhan && thuong.awards[0]?.status === 'pending') {
      thuong = (await gui('/api/rewards/claim', 'POST', { awardId: thuong.awards[0].id })).data;
    }
    const { data: pro } = await gui('/api/subscriptions/check-pro');
    const { data: vi } = await gui('/api/wallet');
    const [mint] = thuong.awards;
    const hopDong = new Contract(rewardAddress, docHopDong('FlutterAcademyRewards').abi, rpc);
    const receipt = mint?.txHash ? await rpc.getTransactionReceipt(mint.txHash) : null;
    const soCoin = chuaNhan ? 0 : 10;
    const mintDung = chuaNhan
      ? mint?.status === 'pending' && mint.txHash == null
      : mint?.status === 'issued' && receipt?.status === 1 &&
        receipt.to?.toLowerCase() === rewardAddress.toLowerCase() && await hopDong.awarded(mint.id);
    if (ngayVietNam(new Date()).ngay !== ngay || thuong.days !== 6 || thuong.lastDay !== ngayTruoc ||
        thuong.awards.length !== 1 || !mintDung || mint.milestone !== 3 || mint.amount !== 10 ||
        await hopDong.balanceOf(diaChiVi) !== BigInt(soCoin) ||
        !thuong.onChain?.connected || thuong.onChain.wallet !== diaChiVi || thuong.onChain.balance !== soCoin ||
        pro.isPro !== false || vi.coinBalance !== soCoin ||
        db.prepare('SELECT 1 FROM reward_days WHERE email = ? AND day = ?').get(email, ngay)) {
      throw new Error('Trạng thái demo chưa khớp giữa backend và Hardhat.');
    }
    await gui('/api/account/session', 'DELETE');
    console.log(JSON.stringify({
      email, ngay, cacNgay, chainId: chain.chainId, wallet: diaChiVi, eth: formatEther(eth),
      rewardContract: rewardAddress, depositContract: depositAddress, rewardTx: mint.txHash,
      coin: soCoin, mocBa: mint.status, coinTrongUngDung: vi.coinBalance, pro: false,
      tutor: {
        mode: cauHinhTutor.apiKey && !cauHinhTutor.demoTutor ? cauHinhTutor.nhaCungCap : 'Demo',
        remaining: cauHinhTutor.tutorFree,
      },
      baiDeQuay, port, giuThuong,
    }, null, 2));
    giuMayChu = !process.argv.includes('--prepare-only');
  } finally {
    db.close();
    rpc.destroy();
    if (!giuMayChu && app?.listening) await new Promise((resolve) => app.close(resolve));
  }
}

try {
  if (process.argv.includes('--serve-existing')) await phucVuDuLieuHienTai();
  else await chuanBi();
} catch (loi) {
  console.error(loi.shortMessage ?? loi.message);
  process.exitCode = 1;
}
