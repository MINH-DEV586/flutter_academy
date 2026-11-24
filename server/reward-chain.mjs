import { createHash, randomBytes } from 'node:crypto';
import { createRequire } from 'node:module';
import { giaoDich } from './streak-rewards.mjs';
import { GOI_PRO_THUONG } from './subscription.mjs';

const require = createRequire(new URL('../blockchain/package.json', import.meta.url));
const chainId = 31337;
const chainHex = '0x7a69';
const price = GOI_PRO_THUONG.amount;
const bytes32 = (s) => typeof s === 'string' && /^0x[\da-f]{64}$/i.test(s);
const randomId = () => '0x' + randomBytes(32).toString('hex');
const hash = (s) => createHash('sha256').update(s).digest('hex');
const abi = [
  'function owner() view returns (address)',
  'function balanceOf(address) view returns (uint256)',
  'function issue(bytes32,address,uint256)',
  'function awarded(bytes32) view returns (bool)',
  'function redeem(bytes32)',
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
    address, rpcUrl = 'http://127.0.0.1:8545', issuerKey,
    confirmations = 1, rpcDienThoai = 'http://127.0.0.1:8545',
  } = cauHinh;
  if (!address) return null;

  const { AbiCoder, Contract, FetchRequest, JsonRpcProvider, Wallet, id, isAddress, keccak256, verifyMessage } =
    require('ethers');
  const rpc = new FetchRequest(rpcUrl);
  rpc.timeout = 8_000;
  const provider = new JsonRpcProvider(rpc, chainId, { staticNetwork: true, batchMaxCount: 1, cacheTimeout: -1 });
  const contract = new Contract(address, abi, provider);
  const contractAddress = address.toLowerCase();
  const packageTopic = id(GOI_PRO_THUONG.id);

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
    CREATE UNIQUE INDEX IF NOT EXISTS idx_pro_active
      ON pro_redemptions(email) WHERE status != 'completed';
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
  const dangDoi = db.prepare("SELECT * FROM pro_redemptions WHERE email = ? AND status != 'completed'");
  const ganNhat = db.prepare('SELECT * FROM pro_redemptions WHERE email = ? ORDER BY rowid DESC LIMIT 1');
  const themYeuCau = db.prepare(`INSERT INTO pro_redemptions
    (id,salt,email,wallet,chain,contract,package_id,amount,start_block) VALUES (?,?,?,?,?,?,?,?,?)`);
  const capNhatYeuCau = db.prepare("UPDATE pro_redemptions SET status = ?, tx_hash = ? WHERE id = ? AND status != 'completed'");
  const danhDauDoiThatBai = db.prepare(`
    UPDATE pro_redemptions SET status = 'failed'
    WHERE id = ? AND tx_hash = ? AND status = 'confirming'`);
  const daCap = db.prepare("UPDATE pro_redemptions SET status = 'completed', tx_hash = ?, expires_at = ? WHERE id = ?");
  const choMint = db.prepare("SELECT * FROM reward_mints WHERE email = ? AND status != 'issued' ORDER BY rowid");
  const capNhatMint = db.prepare("UPDATE reward_mints SET status = ?, tx_hash = ? WHERE id = ? AND status != 'issued'");
  let capThuong = Promise.resolve();

  async function kiemTraMang() {
    const [actual, code] = await Promise.all([
      provider.send('eth_chainId', []), provider.getCode(contractAddress),
    ]);
    if (actual !== chainHex || code === '0x') {
      throw new LoiVi(503, 'Chưa tìm thấy hợp đồng thưởng trên Hardhat 31337.');
    }
  }

  async function dongBoMint(email, wallet) {
    for (const moi of choMint.all(email)) {
      if (await contract.awarded(moi.id)) {
        const [log] = await contract.queryFilter(contract.filters.RewardIssued(moi.id, wallet));
        if (log && log.args.amount === BigInt(moi.amount)) capNhatMint.run('issued', log.transactionHash, moi.id);
        continue;
      }
      if (moi.tx_hash) {
        const [receipt, tx] = await Promise.all([
          provider.getTransactionReceipt(moi.tx_hash), provider.getTransaction(moi.tx_hash),
        ]);
        if (!receipt && tx) continue;
        if (receipt?.status === 1) continue;
      }
      const signer = issuerKey ? new Wallet(issuerKey, provider) : await provider.getSigner(0);
      if ((await contract.owner()).toLowerCase() !== (await signer.getAddress()).toLowerCase()) {
        throw new LoiVi(503, 'Máy chủ chưa có quyền cấp Coin trên hợp đồng thưởng.');
      }
      const tx = await contract.connect(signer).issue(moi.id, wallet, moi.amount);
      capNhatMint.run('submitted', tx.hash, moi.id);
      const receipt = await provider.getTransactionReceipt(tx.hash);
      if (receipt?.status === 1) capNhatMint.run('issued', tx.hash, moi.id);
    }
  }

  async function dongBoDoi(don) {
    if (!don || don.status === 'completed') return;
    if (don.chain !== chainId || don.contract !== contractAddress ||
        don.package_id !== GOI_PRO_THUONG.id || don.amount !== price) {
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
    if (log.args.packageId !== packageTopic || log.args.amount !== BigInt(price) ||
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
      const expiresAt = thanhVien.capProBlockchain(don.email, don.id);
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
        await dongBoDoi(dangDoi.get(email));
        balance = Number(await contract.balanceOf(wallet));
      } catch (loi) {
        chainError = loi instanceof LoiVi ? loi.message : 'Chưa đọc được Hardhat. Hãy kiểm tra RPC rồi thử lại.';
      }
    }
    const don = ganNhat.get(email);
    const link = latestLink.get(email);
    const connected = vi.get(email)?.connected === 1;
    return {
      chainId, wallet, balance, chainError, connected, proOffer: GOI_PRO_THUONG,
      linkStatus: !connected && link && link.expires_ms > dongHo().getTime() && link.status !== 'expired' ? link.status : null,
      redemption: don ? { status: don.status, txHash: don.tx_hash, expiresAt: don.expires_at } : null,
    };
  }

  async function batDau(email, operation) {
    const viHienTai = vi.get(email);
    const wallet = viHienTai?.wallet;
    let don = null;
    if (operation === 'link' && viHienTai?.connected === 1) throw new LoiVi(409, 'Tài khoản đã kết nối ví thưởng.');
    if (operation === 'redeem') {
      if (viHienTai?.connected !== 1) throw new LoiVi(409, 'Kết nối ví MetaMask để đổi Pro.');
      await kiemTraMang();
      don = dangDoi.get(email);
      if (don) {
        await dongBoDoi(don);
        don = yeuCau.get(don.id);
        if (don.status === 'confirming' || don.status === 'completed') {
          throw new LoiVi(409, 'Đơn đã gửi. Hãy tải lại trạng thái.');
        }
      } else {
        if (await contract.balanceOf(wallet) < BigInt(price)) {
          throw new LoiVi(409, 'Ví MetaMask cần 30 Coin thưởng.');
        }
        const block = await provider.getBlockNumber();
        don = giaoDich(db, () => {
          const cu = dangDoi.get(email);
          if (cu) return cu;
          const salt = randomId();
          const request = keccak256(AbiCoder.defaultAbiCoder().encode(['address', 'bytes32'], [wallet, salt]));
          themYeuCau.run(request, salt, email, wallet, chainId, contractAddress, GOI_PRO_THUONG.id, price, block);
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
    if (action === 'open') {
      return {
        operation: phien.operation, message: phien.message, chainId: chainHex, rpcUrl: rpcDienThoai,
        ...(don ? { coinAmount: GOI_PRO_THUONG.amount, proDays: GOI_PRO_THUONG.days } : {}),
        wallet: don?.wallet ?? vi.get(phien.email)?.wallet, to: don?.contract,
        data: don ? contract.interface.encodeFunctionData('redeem', [don.salt]) : null,
      };
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

  return { trangThai, batDau, ngatKetNoi, trangVi, dong: () => provider.destroy() };
}
