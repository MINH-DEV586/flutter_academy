import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cau_hinh/may_chu.dart';
import '../data/kho_vi_coin.dart';
import '../models/don_nap_coin.dart';
import '../data/metamask_interop.dart';
import '../models/vi_coin.dart';
import 'providers.dart';
import 'thuong_chuoi_vm.dart';

/// ViewModel quản lý Ví Coin, kết nối MetaMask, nạp Coin và nhận thưởng.
class ViCoinVM extends AsyncNotifier<ViCoin?> {
  KhoViCoin get _kho => ref.read(khoViCoinProvider);

  @override
  Future<ViCoin?> build() async {
    final daDangNhap = ref.watch(daDangNhapProvider);
    if (!daDangNhap) return null;
    return _kho.layThongTinVi();
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

    try {
      await _kho.lienKetMetaMask(diaChi);
      await lamMoi();
      return null; // Thành công
    } catch (e) {
      return 'Lỗi liên kết ví với máy chủ: $e';
    }
  }

  /// Hủy liên kết MetaMask.
  Future<String?> huyLienKetMetaMask() async {
    try {
      await _kho.lienKetMetaMask(null);
      await lamMoi();
      return null;
    } catch (_) {
      return 'Không thể ngắt liên kết ví. Hãy kiểm tra kết nối và thử lại.';
    }
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
      ref.invalidate(trangThaiThuongProvider);
      return (res['coinNhan'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<Uri?> taoPhienNap(String packageId, {String? orderId}) async {
    final email = ref.read(phienProvider).asData?.value?.email;
    final don = await _kho.taoDonNap(packageId: packageId, orderId: orderId);
    if (!ref.mounted || ref.read(phienProvider).asData?.value?.email != email) {
      return null;
    }
    ref.invalidate(donNapGanNhatProvider);
    final path = don['path'] as String?;
    if (path == null) return null;
    final uri = Uri.parse(path);
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.path != '/meta/vi' ||
        !RegExp(r'^nap_[a-f0-9]{64}$').hasMatch(uri.fragment)) {
      throw const FormatException('Đường dẫn thanh toán không hợp lệ.');
    }
    return Uri.parse(MayChu.api).resolveUri(uri);
  }
}

final donNapGanNhatProvider = FutureProvider.autoDispose<DonNapCoin?>((
  ref,
) async {
  final email = ref.watch(phienProvider).asData?.value?.email;
  if (email == null) return null;
  final don = await ref.watch(khoViCoinProvider).layDonNapGanNhat();
  if (ref.mounted && ref.read(phienProvider).asData?.value?.email == email) {
    ref.invalidate(viCoinProvider);
    ref.invalidate(lichSuGiaoDichProvider);
    ref.invalidate(trangThaiThuongProvider);
  }
  return don;
}, retry: (_, _) => null);
