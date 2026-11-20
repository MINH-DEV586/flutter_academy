import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_vi_coin.dart';
import '../data/metamask_interop.dart';
import '../models/vi_coin.dart';
import 'providers.dart';

/// ViewModel quản lý Ví Coin, kết nối MetaMask, nạp Coin và nhận thưởng.
class ViCoinVM extends AsyncNotifier<ViCoin?> {
  KhoViCoin get _kho => ref.read(khoViCoinProvider);

  @override
  Future<ViCoin?> build() async {
    final daDangNhap = ref.watch(daDangNhapProvider);
    if (!daDangNhap) return null;
    try {
      return await _kho.layThongTinVi();
    } catch (_) {
      return null;
    }
  }

  /// Làm mới thông tin ví.
  Future<void> lamMoi() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _kho.layThongTinVi());
  }

  /// Kết nối MetaMask và liên kết với tài khoản.
  Future<String?> ketNoiMetaMask() async {
    if (!MetaMaskService.isInstalled) {
      return 'Trình duyệt chưa cài đặt MetaMask. Vui lòng cài extension MetaMask.';
    }

    final diaChi = await MetaMaskService.requestAccounts();
    if (diaChi == null) {
      return 'Người dùng đã từ chối kết nối ví.';
    }

    final isSep = await MetaMaskService.isSepolia();
    if (!isSep) {
      final switched = await MetaMaskService.switchToSepolia();
      if (!switched) {
        return 'Vui lòng chuyển mạng sang Ethereum Sepolia Testnet.';
      }
    }

    try {
      await _kho.lienKetMetaMask(diaChi);
      await lamMoi();
      return null; // Thành công
    } catch (e) {
      return 'Lỗi liên kết ví với máy chủ: $e';
    }
  }

  /// Hủy liên kết MetaMask.
  Future<void> huyLienKetMetaMask() async {
    try {
      await _kho.lienKetMetaMask(null);
      await lamMoi();
    } catch (_) {}
  }

  /// Nhận thưởng Coin (bài học, quiz, streak).
  Future<int?> nhanThuong({
    required String loai,
    required String referenceId,
    String? moTa,
  }) async {
    try {
      final res = await _kho.nhanThuong(
        type: loai,
        referenceId: referenceId,
        description: moTa,
      );
      await lamMoi();
      return (res['coinNhan'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Nạp Coin qua MetaMask:
  /// 1. Tạo đơn nạp backend
  /// 2. Gọi Smart Contract qua MetaMask
  /// 3. Gửi txHash lên backend
  /// 4. Yêu cầu xác minh & cập nhật số dư
  Future<String?> napCoin({
    required String packageId,
    required String ethAmount,
  }) async {
    if (!MetaMaskService.isInstalled) {
      return 'Vui lòng cài đặt MetaMask.';
    }

    final account = await MetaMaskService.getAccount();
    if (account == null) {
      return 'Chưa kết nối ví MetaMask.';
    }

    // 1. Tạo đơn nạp
    Map<String, dynamic> don;
    try {
      don = await _kho.taoDonNap(
        packageId: packageId,
        walletAddress: account,
      );
    } catch (e) {
      return 'Lỗi tạo đơn nạp: $e';
    }

    final orderId = don['orderId'] as String;
    final serverContract = (don['contractAddress'] as String?)?.trim();
    // Ưu tiên địa chỉ contract từ backend; nếu backend chưa trả về thì fallback về địa chỉ mặc định
    const defaultContract = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
    final contractAddress = (serverContract != null && serverContract.isNotEmpty)
        ? serverContract
        : defaultContract;

    final contractPkgId = MetaMaskService.getContractPackageId(packageId);

    // 2. Gửi giao dịch qua MetaMask
    final txHash = await MetaMaskService.sendDeposit(
      contractAddress: contractAddress,
      orderId: orderId,
      packageId: contractPkgId,
      ethAmount: ethAmount,
    );

    if (txHash == null) {
      return 'Giao dịch bị huỷ hoặc xảy ra lỗi.';
    }
    if (txHash == 'USER_REJECTED') {
      return 'Bạn đã từ chối xác nhận giao dịch trên MetaMask.';
    }
    if (txHash == 'INSUFFICIENT_FUNDS') {
      return 'Số dư Sepolia ETH trong ví không đủ trả phí Gas hoặc tiền nạp.';
    }

    // 3. Gửi txHash lên backend
    try {
      await _kho.guiTxHash(orderId: orderId, txHash: txHash);
    } catch (e) {
      return 'Lỗi gửi mã giao dịch lên máy chủ: $e';
    }

    // 4. Xác minh giao dịch
    try {
      final kq = await _kho.xacMinhDonNap(orderId);
      if (kq['ok'] == true) {
        await lamMoi();
        return null; // Thành công!
      }
      return kq['loi'] as String? ?? 'Đang chờ xác nhận từ Blockchain...';
    } catch (_) {
      return 'Giao dịch đã gửi ($txHash). Hệ thống sẽ tự động xác minh.';
    }
  }
}
