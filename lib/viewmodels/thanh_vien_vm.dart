import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_thanh_vien.dart';
import '../models/goi_pro.dart';
import 'providers.dart';

/// ViewModel quản lý gói thành viên Pro và kiểm tra quyền truy cập.
class ThanhVienVM extends AsyncNotifier<TrangThaiThanhVien> {
  KhoThanhVien get _kho => ref.read(khoThanhVienProvider);

  @override
  Future<TrangThaiThanhVien> build() async {
    final daDangNhap = ref.watch(daDangNhapProvider);
    if (!daDangNhap) return const TrangThaiThanhVien();
    try {
      return await _kho.layTrangThaiThanhVien();
    } catch (_) {
      return const TrangThaiThanhVien();
    }
  }

  /// Mua gói thành viên Pro bằng Coin.
  Future<String?> muaGoiPro(String packageId) async {
    try {
      await _kho.muaGoiPro(packageId);
      state = AsyncData(await _kho.layTrangThaiThanhVien());
      ref.invalidate(viCoinProvider);
      return null; // Thành công
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Làm mới trạng thái Pro.
  Future<void> lamMoi() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _kho.layTrangThaiThanhVien());
  }
}
