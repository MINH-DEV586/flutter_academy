// MetaMask Mobile có thể tạo lại WebView khi cấp quyền. Giữ fragment
// đến khi phiên đã dùng hoặc hết hạn để tải lại vẫn mở được thử thách.
const token = location.hash.slice(1);
window.addEventListener('hashchange', () => {
  if (location.hash) location.reload();
});

function xoaPhien() {
  if (location.hash) history.replaceState(null, '', location.pathname);
}
const title = document.getElementById('title');
const status = document.getElementById('status');
const confirm = document.getElementById('confirm');

async function session(action, data = {}) {
  const response = await fetch('/meta/vi/session', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, action, ...data }),
    signal: AbortSignal.timeout(10_000),
  });
  const result = await response.json();
  if (response.status === 401 || response.status === 410 || (response.ok && action === 'signed')) {
    xoaPhien();
  }
  if (!response.ok) {
    const error = new Error(result.loi ?? 'Chưa xử lý được yêu cầu.');
    error.maHttp = response.status;
    throw error;
  }
  return result;
}

async function chonMang(ethereum, config) {
  if (await ethereum.request({ method: 'eth_chainId' }) === config.chainId) return;
  try {
    await ethereum.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: config.chainId }] });
  } catch (error) {
    if (error.code !== 4902 && error.data?.originalError?.code !== 4902) throw error;
    await ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [{
        chainId: config.chainId, chainName: config.networkName ?? 'Hardhat Local',
        rpcUrls: [config.rpcUrl], nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
      }],
    });
  }
  if (await ethereum.request({ method: 'eth_chainId' }) !== config.chainId) {
    await ethereum.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: config.chainId }] });
  }
  if (await ethereum.request({ method: 'eth_chainId' }) !== config.chainId) {
    throw new Error('Ví chưa chuyển sang mạng thử nghiệm.');
  }
}

async function khoiTao() {
  const config = await session('open');
  const link = config.operation === 'link';
  const nap = config.operation === 'deposit';
  const mang = config.networkName ?? 'Hardhat Local';
  title.textContent = nap ? `Nạp ${config.coinAmount} Coin` : link ? 'Xác minh ví thưởng' :
    `Đổi ${config.coinAmount} Coin thưởng lấy ${config.proDays} ngày Pro`;
  status.textContent = link
    ? 'Chọn tài khoản Hardhat rồi ký xác minh quyền sở hữu ví.'
    : nap
    ? `Thanh toán ${config.ethAmount} ETH thử nghiệm và phí mạng trên ${mang}.`
    : 'Chọn ví đã xác minh và xác nhận giao dịch trên Hardhat Local.';
  confirm.disabled = false;
  let canXinLaiQuyen = false;
  confirm.addEventListener('click', async () => {
    // MetaMask Mobile có thể gắn provider sau khi giao diện đã tải xong.
    const ethereum = window.ethereum;
    if (!ethereum?.isMetaMask) {
      status.textContent = 'Mở đường dẫn gốc trong trình duyệt MetaMask hoặc dùng trình duyệt có tiện ích MetaMask rồi thử lại.';
      return;
    }
    confirm.disabled = true;
    let daGui = false;
    let buoc = 'kết nối tài khoản';
    status.textContent = 'Đang chờ xác nhận trong ví…';
    try {
      await ethereum.request({ method: 'eth_requestAccounts' });
      buoc = 'chuyển mạng';
      await chonMang(ethereum, config);
      if (canXinLaiQuyen) {
        buoc = 'cấp quyền tài khoản';
        await ethereum.request({ method: 'wallet_requestPermissions', params: [{ eth_accounts: {} }] });
        await chonMang(ethereum, config);
        canXinLaiQuyen = false;
      }
      buoc = 'đọc tài khoản';
      const [address] = await ethereum.request({ method: 'eth_accounts' });
      if (typeof address !== 'string' || !/^0x[\da-f]{40}$/i.test(address) ||
          (config.wallet && config.wallet.toLowerCase() !== address.toLowerCase())) {
        await session('result', { status: 'failed' });
        status.textContent = 'Chọn đúng tài khoản ví đã xác minh rồi thử lại.';
        confirm.disabled = false;
        return;
      }
      if (link) {
        buoc = 'ký xác minh';
        const bytes = new TextEncoder().encode(config.message);
        const message = '0x' + Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
        const signature = await ethereum.request({ method: 'personal_sign', params: [message, address] });
        await session('signed', { address, signature });
        status.textContent = 'Đã xác minh. Quay về Flutter Academy để nhận Coin đang chờ.';
      } else {
        if (nap) {
          await session('prepare', { address });
          const [dangChon] = await ethereum.request({ method: 'eth_accounts' });
          if (dangChon?.toLowerCase() !== address.toLowerCase() ||
              await ethereum.request({ method: 'eth_chainId' }) !== config.chainId) {
            throw new Error('Tài khoản hoặc mạng đã thay đổi.');
          }
        }
        buoc = 'ký giao dịch';
        const txHash = await ethereum.request({
          method: 'eth_sendTransaction',
          params: [{ from: address, to: config.to, data: config.data, ...(nap ? { value: config.value } : {}) }],
        });
        daGui = true;
        await session('signed', { txHash });
        status.textContent = 'Đã gửi giao dịch. Quay về Flutter Academy để kiểm tra xác nhận.';
      }
    } catch (error) {
      if (daGui) {
        status.textContent = 'Ví đã gửi giao dịch. Quay về Flutter Academy để đối soát.';
        return;
      }
      const rejected = error.code === 4001;
      if (error.code === -32602 && /must provide (?:an|a permitted) Ethereum address/i.test(error.message)) {
        canXinLaiQuyen = true;
      }
      const maLoi = Number.isInteger(error.code) ? ` (MetaMask ${error.code})` : '';
      await session('result', { status: rejected ? 'rejected' : 'failed' }).catch(() => {});
      status.textContent = rejected
        ? 'Bạn đã từ chối trong ví. Có thể xác nhận lại.'
        : canXinLaiQuyen
        ? `MetaMask chưa cấp quyền tài khoản trên ${mang}. Bấm xác nhận lại và chọn đúng tài khoản cùng mạng thử nghiệm.`
        : error.maHttp
        ? error.message
        : buoc === 'chuyển mạng'
        ? `Chưa chuyển được sang ${mang}. Kiểm tra mạng trong MetaMask${maLoi}.`
        : `Lỗi khi ${buoc}${maLoi}. Kiểm tra tài khoản ví và mạng rồi thử lại.`;
      confirm.disabled = false;
    }
  });
}

khoiTao().catch((error) => { status.textContent = error.message; });
