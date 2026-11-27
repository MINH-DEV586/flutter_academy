import { createHash, randomBytes } from 'node:crypto';
import { createRequire } from 'node:module';
import { giaoDich } from './streak-rewards.mjs';
import { GOI_PRO_THUONG } from './subscription.mjs';

const require = createRequire(new URL('../blockchain/package.json', import.meta.url));
const chainId = 31337;
const chainHex = '0x7a69';
const bytes32 = (s) => typeof s === 'string' && /^0x[\da-f]{64}$/i.test(s);
const randomId = () => '0x' + randomBytes(32).toString('hex');
const hash = (s) => createHash('sha256').update(s).digest('hex');
const abi = [
  'function owner() view returns (address)',
  'function balanceOf(address) view returns (uint256)',
  'function issue(bytes32,address,uint256)',
  'function awarded(bytes32) view returns (bool)',
  'function redeem(bytes32)',
  'function priceOf(bytes32) view returns (uint256)',
  'function redeemPackage(bytes32,bytes32)',
  'event RewardIssued(bytes32 indexed rewardId,address indexed wallet,uint256 amount)',
  'event ProRedeemed(bytes32 indexed requestId,address indexed wallet,bytes32 packageId,uint256 amount)',
];

class LoiVi extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function taoThuongOnChain(db, thanhVien, dongHo, cauHinh = {}) {
  const {
    address, rpcUrl = 'http://127.0.0.1:8545', issuerKey, soCoin,
    confirmations = 1, rpcDienThoai = 'http://127.0.0.1:8545',
  } = cauHinh;
  if (!address) return null;

  const { AbiCoder, Contract, FetchRequest, JsonRpcProvider, Wallet, id, isAddress, keccak256, verifyMessage } =
    require('ethers');
  const rpc = new FetchRequest(rpcUrl);
  rpc.timeout = 8_000;
  const provider = new JsonRpcProvider(rpc, chainId, { staticNetwork: true, batchMaxCount: 1, cacheTimeout: -1 });
  const nangCap = soCoin?.nangCap();
  if (nangCap && nangCap.old_contract.toLowerCase() !== address.toLowerCase()) {
    throw new Error('Cấu hình ví Coin không khớp hợp đồng trước khi hợp nhất.');
  }
  const contractAddress = (nangCap?.new_contract ?? address).toLowerCase();
  const contract = new Contract(contractAddress, abi, provider);

  db.exec(`
    CREATE TABLE IF NOT EXISTS verified_reward_wallets (
      email TEXT PRIMARY KEY REFERENCES tai_khoan(email),
      wallet TEXT UNIQUE NOT NULL,
      connected INTEGER NOT NULL DEFAULT 1
    ) STRICT;
    CREATE TABLE IF NOT EXISTS pro_redemptions (
      id TEXT PRIMARY KEY, salt TEXT NOT NULL, email TEXT NOT NULL REFERENCES tai_khoan(email),
      wallet TEXT NOT NULL, chain INTEGER NOT NULL, contract TEXT NOT NULL,
      package_id TEXT NOT NULL, amount INTEGER NOT NULL, start_block INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'signing', tx_hash TEXT, expires_at TEXT
    ) STRICT;
    CREATE UNIQUE INDEX IF NOT EXISTS idx_pro_active_package
      ON pro_redemptions(email, chain, contract, package_id) WHERE status != 'completed';
    DROP INDEX IF EXISTS idx_pro_active;
    CREATE UNIQUE INDEX IF NOT EXISTS idx_pro_tx
      ON pro_redemptions(chain, tx_hash) WHERE status = 'completed';
    CREATE TABLE IF NOT EXISTS reward_wallet_sessions (
      token_hash TEXT PRIMARY KEY, email TEXT NOT NULL REFERENCES tai_khoan(email),
      operation TEXT NOT NULL, request_id TEXT, message TEXT,
      expires_ms INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'signing'
    ) STRICT;
  `);
  if (!db.prepare('PRAGMA table_info(verified_reward_wallets)').all().some((col) => col.name === 'connected')) {
    db.exec('ALTER TABLE verified_reward_wallets ADD COLUMN connected INTEGER NOT NULL DEFAULT 1');
  }
  const vi = db.prepare('SELECT wallet, connected FROM verified_reward_wallets WHERE email = ?');
  const chuVi = db.prepare('SELECT email FROM verified_reward_wallets WHERE wallet = ?');
  const themVi = db.prepare('INSERT OR IGNORE INTO verified_reward_wallets (email, wallet) VALUES (?, ?)');
  const datKetNoi = db.prepare('UPDATE verified_reward_wallets SET connected = ? WHERE email = ?');
  const session = db.prepare('SELECT * FROM reward_wallet_sessions WHERE token_hash = ?');
  const latestLink = db.prepare("SELECT status, expires_ms FROM reward_wallet_sessions WHERE email = ? AND operation = 'link' ORDER BY rowid DESC LIMIT 1");
  const themSession = db.prepare('INSERT INTO reward_wallet_sessions (token_hash,email,operation,request_id,message,expires_ms) VALUES (?,?,?,?,?,?)');
  const huyLink = db.prepare("UPDATE reward_wallet_sessions SET status = 'expired' WHERE email = ? AND operation = 'link' AND status != 'completed'");
  const huyPhienVi = db.prepare("UPDATE reward_wallet_sessions SET status = 'expired' WHERE email = ? AND status != 'completed'");
  const doiSession = db.prepare('UPDATE reward_wallet_sessions SET status = ? WHERE token_hash = ?');
  const yeuCau = db.prepare('SELECT * FROM pro_redemptions WHERE id = ?');
  const dangDoi = db.prepare("SELECT * FROM pro_redemptions WHERE email = ? AND chain = ? AND contract = ? AND package_id = ? AND status != 'completed'");
  const cacDonDangDoi = db.prepare("SELECT * FROM pro_redemptions WHERE email = ? AND chain = ? AND contract = ? AND status != 'completed'");
  const ganNhat = db.prepare('SELECT * FROM pro_redemptions WHERE email = ? AND chain = ? AND contract = ? ORDER BY rowid DESC LIMIT 1');
  const themYeuCau = db.prepare(`INSERT INTO pro_redemptions
    (id,salt,email,wallet,chain,contract,package_id,amount,start_block) VALUES (?,?,?,?,?,?,?,?,?)`);
  const capNhatYeuCau = db.prepare("UPDATE pro_redemptions SET status = ?, tx_hash = ? WHERE id = ? AND status != 'completed'");
  const danhDauDoiThatBai = db.prepare(`
    UPDATE pro_redemptions SET status = 'failed'
    WHERE id = ? AND tx_hash = ? AND status = 'confirming'`);
  const daCap = db.prepare("UPDATE pro_redemptions SET status = 'completed', tx_hash = ?, expires_at = ? WHERE id = ?");
  const choMint = db.prepare("SELECT * FROM reward_mints WHERE email = ? AND status != 'issued' ORDER BY rowid");
  const timMint = db.prepare('SELECT status FROM reward_mints WHERE id = ? AND email = ?');
  const yeuCauMint = db.prepare("UPDATE reward_mints SET status = 'claiming' WHERE id = ? AND email = ? AND status = 'pending'");
  const capNhatMint = db.prepare("UPDATE reward_mints SET status = ?, tx_hash = ? WHERE id = ? AND status != 'issued'");
  let capThuong = Promise.resolve();

  async function kiemTraMang() {
    const [actual, code, metadata] = await Promise.all([
      provider.send('eth_chainId', []), provider.getCode(contractAddress),
      nangCap ? provider.send('hardhat_metadata', []) : null,
    ]);
    if (actual !== chainHex || code === '0x') {
      throw new LoiVi(503, 'Chưa tìm thấy hợp đồng Coin trên Hardhat 31337.');
    }
    if (nangCap && metadata?.instanceId !== nangCap.instance_id) {
      throw new LoiVi(503, 'Hardhat đang chạy khác phiên đã đối soát Coin.');
    }
  }

  async function dongBoMint(email, wallet) {
    const mints = [
      ...choMint.all(email).map((mint) => ({ mint, credit: false })),
      ...(soCoin?.dangCho(email) ?? []).map((mint) => ({ mint, credit: true })),
    ];
    for (const { mint: moi, credit } of mints) {
      const capNhat = credit ? soCoin.capNhat : capNhatMint;
      let txHash = moi.tx_hash;
      if (await contract.awarded(moi.id)) {
        const [log] = await contract.queryFilter(contract.filters.RewardIssued(moi.id, wallet));
        if (!log || log.args.amount !== BigInt(moi.amount)) {
          throw new LoiVi(503, 'Chưa đối soát được sự kiện cấp Coin.');
        }
        txHash = log.transactionHash;
      } else {
        if (txHash) {
          const [receipt, tx] = await Promise.all([
            provider.getTransactionReceipt(txHash), provider.getTransaction(txHash),
          ]);
          if ((!receipt && tx) || receipt?.status === 1) continue;
        }
        if (moi.status === 'pending' && !txHash) continue;
        const signer = issuerKey ? new Wallet(issuerKey, provider) : await provider.getSigner(0);
        if ((await contract.owner()).toLowerCase() !== (await signer.getAddress()).toLowerCase()) {
          throw new LoiVi(503, 'Máy chủ chưa có quyền cấp Coin trên hợp đồng.');
        }
        const tx = await contract.connect(signer).issue(moi.id, wallet, moi.amount);
        txHash = tx.hash;
        capNhat.run('submitted', txHash, moi.id);
      }
      const receipt = await provider.getTransactionReceipt(txHash);
      if (receipt?.status !== 1 || receipt.to?.toLowerCase() !== contractAddress ||
          (await provider.getBlockNumber()) - receipt.blockNumber + 1 < confirmations) continue;
      if (credit) {
        const soDu = Number(await contract.balanceOf(wallet, { blockTag: receipt.blockNumber }));
        soCoin.hoanTat(moi, txHash, soDu);
      } else {
        capNhat.run('issued', txHash, moi.id);
      }
    }
  }

  function batDauNhan(email, awardId) {
    if (!bytes32(awardId)) throw new LoiVi(400, 'Mã phần thưởng không hợp lệ.');
    const mint = timMint.get(awardId, email);
    if (!mint) throw new LoiVi(404, 'Không tìm thấy phần thưởng của tài khoản.');
    if (mint.status === 'issued') return;
    if (vi.get(email)?.connected !== 1) {
      throw new LoiVi(409, 'Xác minh ví MetaMask để nhận Coin.');
    }
    yeuCauMint.run(awardId, email);
  }

  async function dongBoDoi(don) {
    if (!don || don.status === 'completed') return;
    const goi = thanhVien.timGoiCoin(don.package_id);
    if (don.chain !== chainId || don.contract !== contractAddress ||
        !goi || don.amount !== goi.amount) {
      throw new LoiVi(409, 'Đơn đổi thuộc hợp đồng hoặc mạng khác.');
    }
    const [log] = await contract.queryFilter(
      contract.filters.ProRedeemed(don.id, don.wallet), don.start_block,
    );
    if (!log) {
      if (don.tx_hash) {
        const receipt = await provider.getTransactionReceipt(don.tx_hash);
        // Nếu RPC chưa thấy hash, cho ký lại cùng mã yêu cầu. Hợp đồng
        // chỉ tiêu Coin một lần kể cả khi giao dịch cũ xuất hiện trở lại.
        if (receipt || !await provider.getTransaction(don.tx_hash)) {
          danhDauDoiThatBai.run(don.id, don.tx_hash);
        }
      }
      return;
    }

    const [receipt, block] = await Promise.all([
      provider.getTransactionReceipt(log.transactionHash), provider.getBlockNumber(),
    ]);
    if (log.args.packageId !== id(don.package_id) || log.args.amount !== BigInt(don.amount) ||
        receipt?.status !== 1 || receipt.to?.toLowerCase() !== contractAddress ||
        receipt.from?.toLowerCase() !== don.wallet ||
        receipt.blockHash !== log.blockHash) {
      capNhatYeuCau.run('failed', log.transactionHash, don.id);
      return;
    }
    if (block - receipt.blockNumber + 1 < confirmations) {
      capNhatYeuCau.run('confirming', log.transactionHash, don.id);
      return;
    }
    giaoDich(db, () => {
      if (yeuCau.get(don.id).status === 'completed') return;
      const expiresAt = thanhVien.capProBlockchain(don.email, don.id, don.package_id);
      daCap.run(log.transactionHash, expiresAt, don.id);
    });
  }

  async function trangThai(email) {
    const wallet = vi.get(email)?.wallet ?? null;
    let balance = null;
    let chainError = null;
    if (wallet) {
      try {
        await kiemTraMang();
        const luot = capThuong.then(() => dongBoMint(email, wallet));
        capThuong = luot.catch(() => {});
        await luot;
        for (const don of cacDonDangDoi.all(email, chainId, contractAddress)) await dongBoDoi(don);
        balance = Number(await contract.balanceOf(wallet));
      } catch (loi) {
        chainError = loi instanceof LoiVi ? loi.message : 'Chưa đọc được Hardhat. Hãy kiểm tra RPC rồi thử lại.';
      }
    }
    const don = ganNhat.get(email, chainId, contractAddress);
    const link = latestLink.get(email);
    const connected = vi.get(email)?.connected === 1;
    return {
      chainId, wallet, balance, chainError, connected, proOffer: GOI_PRO_THUONG,
      creditPending: soCoin?.coinCho(email) ?? 0,
      linkStatus: !connected && link && link.expires_ms > dongHo().getTime() && link.status !== 'expired' ? link.status : null,
      redemption: don ? { status: don.status, txHash: don.tx_hash, expiresAt: don.expires_at } : null,
    };
  }

  async function batDau(email, operation, packageId = GOI_PRO_THUONG.id) {
    const viHienTai = vi.get(email);
    const wallet = viHienTai?.wallet;
    let don = null;
    if (operation === 'link' && viHienTai?.connected === 1) throw new LoiVi(409, 'Tài khoản đã kết nối ví thưởng.');
    if (operation === 'redeem') {
      if (viHienTai?.connected !== 1) throw new LoiVi(409, 'Kết nối ví MetaMask để đổi Pro.');
      const goi = typeof packageId === 'string' ? thanhVien.timGoiCoin(packageId) : null;
      if (!goi) throw new LoiVi(404, 'Gói Pro không tồn tại.');
      await kiemTraMang();
      if (goi.id !== GOI_PRO_THUONG.id && await contract.priceOf(id(goi.id)) !== BigInt(goi.amount)) {
        throw new LoiVi(409, 'Giá gói Pro chưa khớp với hợp đồng.');
      }
      don = dangDoi.get(email, chainId, contractAddress, goi.id);
      if (don) {
        await dongBoDoi(don);
        don = yeuCau.get(don.id);
        if (don.status === 'confirming' || don.status === 'completed') {
          throw new LoiVi(409, 'Đơn đã gửi. Hãy tải lại trạng thái.');
        }
      } else {
        if (await contract.balanceOf(wallet) < BigInt(goi.amount)) {
          throw new LoiVi(409, `Ví MetaMask cần ${goi.amount} Coin.`);
        }
        const block = await provider.getBlockNumber();
        don = giaoDich(db, () => {
          const cu = dangDoi.get(email, chainId, contractAddress, goi.id);
          if (cu) return cu;
          const salt = randomId();
          const request = keccak256(AbiCoder.defaultAbiCoder().encode(['address', 'bytes32'], [wallet, salt]));
          themYeuCau.run(request, salt, email, wallet, chainId, contractAddress, goi.id, goi.amount, block);
          return yeuCau.get(request);
        });
      }
    }
    const token = randomId();
    const expires = dongHo().getTime() + 10 * 60_000;
    const message = operation === 'link'
      ? `Flutter Academy\nXác minh ví thưởng Hardhat 31337\nTài khoản ${email}\nMã ${hash(token)}\nHết hạn ${new Date(expires).toISOString()}`
      : null;
    giaoDich(db, () => {
      if (operation === 'link') huyLink.run(email);
      if (don) {
        if (vi.get(email)?.connected !== 1) throw new LoiVi(409, 'Kết nối ví MetaMask để đổi Pro.');
        if (['confirming', 'completed'].includes(yeuCau.get(don.id).status)) {
          throw new LoiVi(409, 'Đơn đã gửi. Hãy tải lại trạng thái.');
        }
        capNhatYeuCau.run('signing', null, don.id);
      }
      themSession.run(hash(token), email, operation, don?.id ?? null, message, expires);
    });
    return { path: `/meta/vi#${token}` };
  }

  function ngatKetNoi(email) {
    giaoDich(db, () => {
      datKetNoi.run(0, email);
      huyPhienVi.run(email);
    });
    return { ok: true };
  }

  function trangVi({ token, action, address: wallet, signature, txHash, status } = {}) {
    if (!bytes32(token)) throw new LoiVi(401, 'Mã phiên ví không hợp lệ.');
    const khoa = hash(token);
    const phien = session.get(khoa);
    if (!phien || phien.expires_ms <= dongHo().getTime() || ['completed', 'expired'].includes(phien.status)) {
      throw new LoiVi(410, 'Phiên ví đã hết hạn hoặc đã dùng. Mở lại từ Flutter Academy.');
    }
    const don = phien.request_id ? yeuCau.get(phien.request_id) : null;
    if (don && don.contract !== contractAddress) {
      throw new LoiVi(410, 'Phiên thuộc hợp đồng Coin cũ. Mở lại từ ứng dụng.');
    }
    const goi = don ? thanhVien.timGoiCoin(don.package_id) : null;
    if (don && !goi) throw new LoiVi(404, 'Gói Pro không tồn tại.');
    if (action === 'open') {
      return {
        operation: phien.operation, message: phien.message, chainId: chainHex, rpcUrl: rpcDienThoai,
        ...(don ? { coinAmount: don.amount, proDays: goi.days } : {}),
        wallet: don?.wallet ?? vi.get(phien.email)?.wallet, to: don?.contract,
        data: !don ? null : don.package_id === GOI_PRO_THUONG.id
          ? contract.interface.encodeFunctionData('redeem', [don.salt])
          : contract.interface.encodeFunctionData('redeemPackage', [don.salt, id(don.package_id)]),
      };
    }
    if (action === 'prepare' && don) {
      if (don.status === 'completed' || don.status === 'confirming' ||
          vi.get(phien.email)?.connected !== 1 || wallet?.toLowerCase() !== don.wallet) {
        throw new LoiVi(409, 'Kiểm tra lại đơn đổi Pro và ví đã xác minh.');
      }
      return kiemTraMang().then(async () => ({
        nonce: await provider.send('eth_getTransactionCount', [don.wallet, 'pending']),
      }));
    }
    if (action === 'result' && ['rejected', 'failed'].includes(status)) {
      doiSession.run(status, khoa);
      if (don && !don.tx_hash) capNhatYeuCau.run(status, null, don.id);
      return { ok: true };
    }
    if (action === 'signed' && phien.operation === 'link') {
      let daKy;
      try {
        if (!isAddress(wallet)) throw new Error();
        daKy = verifyMessage(phien.message, signature).toLowerCase();
      } catch {
        throw new LoiVi(400, 'Chữ ký MetaMask không hợp lệ.');
      }
      if (daKy !== wallet.toLowerCase()) throw new LoiVi(400, 'Chữ ký không khớp địa chỉ ví.');
      giaoDich(db, () => {
        if (chuVi.get(daKy)?.email && chuVi.get(daKy).email !== phien.email) {
          throw new LoiVi(409, 'Ví đã xác minh cho tài khoản khác.');
        }
        const daLienKet = vi.get(phien.email)?.wallet;
        if (daLienKet && daLienKet !== daKy) throw new LoiVi(409, 'Tài khoản đã có ví thưởng.');
        themVi.run(phien.email, daKy);
        datKetNoi.run(1, phien.email);
        doiSession.run('completed', khoa);
      });
      return { ok: true };
    }
    if (action === 'signed' && don && bytes32(txHash)) {
      capNhatYeuCau.run('confirming', txHash.toLowerCase(), don.id);
      doiSession.run('completed', khoa);
      return { ok: true };
    }
    throw new LoiVi(400, 'Kết quả ví không hợp lệ.');
  }

  return { trangThai, batDau, batDauNhan, ngatKetNoi, trangVi, xemVi: (email) => vi.get(email), dong: () => provider.destroy() };
}
