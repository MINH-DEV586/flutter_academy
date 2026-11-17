import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../models/nguoi_dung.dart';
import 'providers.dart';

/// Phiên đăng nhập. `null` nghĩa là khách vãng lai.
class PhienVM extends AsyncNotifier<NguoiDung?> {
  KhoNguoiDung get _kho => ref.read(khoNguoiDungProvider);

  @override
  Future<NguoiDung?> build() => _kho.hienTai();

  Future<String?> dangNhap({
    required String email,
    required String matKhau,
    String? hoTen,
  }) async {
    final e = email.trim();
    final t = hoTen?.trim();
    if (!hopLeEmail(e)) return 'Email chưa đúng định dạng.';
    if (t != null && t.length < 2) return 'Họ tên phải có ít nhất 2 ký tự.';

    try {
      final nd = t == null
          ? await _kho.dangNhap(email: e, matKhau: matKhau)
          : await _kho.dangKy(email: e, hoTen: t, matKhau: matKhau);
      state = AsyncData(nd);
      return null;
    } on LoiTaiKhoan catch (loi) {
      return loi.thongBao;
    } catch (_) {
      return 'Không kết nối được máy chủ tài khoản. Vui lòng thử lại.';
    }
  }

  Future<bool> dangXuat() async {
    try {
      await _kho.dangXuat();
      state = const AsyncData(null);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Kiểm tra định dạng email.
///
/// Cố ý **không** dùng biểu thức chính quy "chuẩn RFC 5322" dài 400 ký tự:
/// nó vừa khó đọc vừa vẫn sai. Kiểm tra lỏng ở phía giao diện, còn muốn chắc
/// chắn thì chỉ có cách gửi thư xác nhận.
///
/// Hàm thuần, đặt ngoài lớp để `test/phien_test.dart` gọi thẳng.
bool hopLeEmail(String s) {
  final t = s.trim();
  if (t.length < 5 || t.contains(' ')) return false;
  final cheo = t.indexOf('@');
  if (cheo <= 0 || cheo != t.lastIndexOf('@')) return false;
  final mien = t.substring(cheo + 1);
  final cham = mien.indexOf('.');
  // Phải có dấu chấm, không đứng ngay sau @ và không đứng cuối.
  return cham > 0 && cham < mien.length - 1;
}
