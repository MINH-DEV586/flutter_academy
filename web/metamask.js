/**
 * MetaMask helper cho Flutter Academy Web.
 *
 * Cung cấp các hàm JavaScript để Flutter (qua dart:js_interop) giao tiếp
 * với MetaMask trên trình duyệt.
 *
 * Sử dụng EIP-1193 Provider (window.ethereum).
 */
(function () {
  'use strict';

  // ── Hằng số ────────────────────────────────────────────────────────────
  const SEPOLIA_CHAIN_ID = '0xaa36a7'; // 11155111
  const HARDHAT_CHAIN_ID = '0x7a69';   // 31337 (Hardhat Local)

  // Function selector cho deposit(bytes32,uint256)
  // = keccak256("deposit(bytes32,uint256)") lấy 4 bytes đầu
  const DEPOSIT_SELECTOR = '0x1de26e16';

  // ── Tiện ích ───────────────────────────────────────────────────────────
  function padHex(hex, bytes) {
    var clean = hex.startsWith('0x') ? hex.slice(2) : hex;
    return clean.padStart(bytes * 2, '0');
  }

  function numberToHex(n) {
    return '0x' + BigInt(n).toString(16);
  }

  function ethToWei(ethStr) {
    // Chuyển ETH string (vd: "0.005") sang wei hex
    var parts = ethStr.split('.');
    var whole = parts[0] || '0';
    var frac = (parts[1] || '').padEnd(18, '0').slice(0, 18);
    var weiStr = whole + frac;
    // Bỏ leading zeros
    weiStr = weiStr.replace(/^0+/, '') || '0';
    return '0x' + BigInt(weiStr).toString(16);
  }

  // ── API chính ──────────────────────────────────────────────────────────
  window.FlutterMetaMask = {
    /**
     * Kiểm tra MetaMask đã được cài đặt chưa.
     * @returns {boolean}
     */
    isInstalled: function () {
      return typeof window.ethereum !== 'undefined' && !!window.ethereum.isMetaMask;
    },

    /**
     * Yêu cầu kết nối ví MetaMask.
     * @returns {Promise<string|null>} Địa chỉ ví hoặc null.
     */
    requestAccounts: async function () {
      try {
        var accounts = await window.ethereum.request({
          method: 'eth_requestAccounts',
        });
        return accounts && accounts.length > 0 ? accounts[0] : null;
      } catch (e) {
        console.error('MetaMask requestAccounts:', e);
        return null;
      }
    },

    /**
     * Lấy địa chỉ ví hiện tại (không yêu cầu kết nối).
     * @returns {Promise<string|null>}
     */
    getAccount: async function () {
      try {
        var accounts = await window.ethereum.request({
          method: 'eth_accounts',
        });
        return accounts && accounts.length > 0 ? accounts[0] : null;
      } catch (e) {
        return null;
      }
    },

    /**
     * Lấy chain ID hiện tại.
     * @returns {Promise<string>} Hex chain ID.
     */
    getChainId: async function () {
      try {
        return await window.ethereum.request({ method: 'eth_chainId' });
      } catch (e) {
        return '';
      }
    },

    /**
     * Kiểm tra mạng hợp lệ (Hardhat Local 31337 hoặc Sepolia 11155111).
     * @returns {Promise<boolean>}
     */
    isSepolia: async function () {
      var chainId = await this.getChainId();
      return chainId === SEPOLIA_CHAIN_ID || chainId === HARDHAT_CHAIN_ID;
    },

    /**
     * Yêu cầu chuyển sang Sepolia.
     * @returns {Promise<boolean>}
     */
    switchToSepolia: async function () {
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: SEPOLIA_CHAIN_ID }],
        });
        return true;
      } catch (e) {
        // Nếu chưa thêm mạng Sepolia
        if (e.code === 4902) {
          try {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [
                {
                  chainId: SEPOLIA_CHAIN_ID,
                  chainName: 'Ethereum Sepolia Testnet',
                  nativeCurrency: { name: 'Sepolia ETH', symbol: 'ETH', decimals: 18 },
                  rpcUrls: ['https://rpc.sepolia.org'],
                  blockExplorerUrls: ['https://sepolia.etherscan.io'],
                },
              ],
            });
            return true;
          } catch (addErr) {
            console.error('MetaMask addChain:', addErr);
            return false;
          }
        }
        console.error('MetaMask switchChain:', e);
        return false;
      }
    },

    /**
     * Gửi giao dịch nạp Coin qua Smart Contract.
     *
     * @param {string} contractAddress - Địa chỉ Smart Contract.
     * @param {string} orderId - bytes32 hex orderId.
     * @param {number} packageId - ID gói nạp (1-5 trên contract).
     * @param {string} ethAmount - Số ETH phải trả (vd: "0.005").
     * @returns {Promise<string|null>} Transaction hash hoặc null.
     */
    sendDeposit: async function (contractAddress, orderId, packageId, ethAmount) {
      try {
        // Kiểm tra mạng
        var isSep = await this.isSepolia();
        if (!isSep) {
          var switched = await this.switchToSepolia();
          if (!switched) return null;
        }

        // Encode ABI: deposit(bytes32 orderId, uint256 packageId)
        var data =
          DEPOSIT_SELECTOR +
          padHex(orderId, 32) +
          padHex(numberToHex(packageId), 32);

        var accounts = await window.ethereum.request({
          method: 'eth_requestAccounts',
        });
        if (!accounts || accounts.length === 0) return null;

        var txHash = await window.ethereum.request({
          method: 'eth_sendTransaction',
          params: [
            {
              from: accounts[0],
              to: contractAddress,
              value: ethToWei(ethAmount),
              data: data,
            },
          ],
        });
        return txHash;
      } catch (e) {
        console.error('MetaMask sendDeposit:', e);
        // Trả về thông tin lỗi dạng chuỗi để Flutter xử lý
        if (e.code === 4001) return 'USER_REJECTED';
        if (e.code === -32603) return 'INSUFFICIENT_FUNDS';
        return null;
      }
    },

    /**
     * Lấy số dư ETH.
     * @param {string} address
     * @returns {Promise<string>} Số dư ETH dạng chuỗi.
     */
    getBalance: async function (address) {
      try {
        var balanceHex = await window.ethereum.request({
          method: 'eth_getBalance',
          params: [address, 'latest'],
        });
        // Chuyển từ wei hex sang ETH
        var weiBI = BigInt(balanceHex);
        var eth = Number(weiBI) / 1e18;
        return eth.toFixed(6);
      } catch (e) {
        return '0';
      }
    },

    /**
     * Đăng ký lắng nghe sự kiện đổi tài khoản.
     * @param {function} callback - Hàm gọi lại khi tài khoản đổi.
     */
    onAccountsChanged: function (callback) {
      if (!window.ethereum) return;
      window.ethereum.on('accountsChanged', function (accounts) {
        callback(accounts && accounts.length > 0 ? accounts[0] : null);
      });
    },

    /**
     * Đăng ký lắng nghe sự kiện đổi mạng.
     * @param {function} callback - Hàm gọi lại khi mạng đổi.
     */
    onChainChanged: function (callback) {
      if (!window.ethereum) return;
      window.ethereum.on('chainChanged', function (chainId) {
        callback(chainId);
      });
    },

    // Map packageId trong Flutter (pkg_50...) sang packageId contract (1-5)
    packageIdMap: {
      pkg_50: 1,
      pkg_100: 2,
      pkg_250: 3,
      pkg_500: 4,
      pkg_1000: 5,
    },

    /**
     * Tiện ích: lấy packageId contract từ packageId Flutter.
     */
    getContractPackageId: function (flutterPkgId) {
      return this.packageIdMap[flutterPkgId] || 0;
    },
  };
})();
