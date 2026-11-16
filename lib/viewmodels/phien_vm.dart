import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../models/nguoi_dung.dart';
import 'providers.dart';

/// Phiên đăng nhập. `null` nghĩa là khách vãng lai.
///
/// Không có mật khẩu và không có máy chủ — xem chú thích ở `NguoiDung`. Điều
/// đáng học ở đây không phải cách xác thực mà là **hình dạng của trạng thái
/// phiên**: một `AsyncValue<NguoiDung?>` mà cả giao diện lẫn `redirect` của
/// go_router cùng đọc, nên không bao giờ có chuyện thanh địa chỉ và màn hình
/// nói hai điều khác nhau.
class PhienVM extends AsyncNotifier<NguoiDung?> {
  KhoNguoiDung get _kho => ref.read(khoNguoiDungProvider);

  @override
  Future<NguoiDung?> build() => _kho.hienTai();

  /// "Đăng nhập": ghi hồ sơ xuống Hive.
  ///
  /// Trả về thông báo lỗi, hoặc null nếu thành công. Không ném ngoại lệ:
  /// màn hình gọi hàm này cần hiển thị lỗi ngay dưới ô nhập, mà bắt ngoại lệ
  /// để làm việc đó thì rườm rà hơn là đọc một giá trị trả về.
  Future<String?> dangNhap({required String email, required String hoTen}) async {
    final e = email.trim();
    final t = hoTen.trim();
    if (!hopLeEmail(e)) return 'Email chưa đúng định dạng.';
    if (t.length < 2) return 'Họ tên phải có ít nhất 2 ký tự.';

    state = const AsyncLoading();
    try {
      final nd = NguoiDung(email: e, hoTen: t);
      await _kho.dangNhap(nd);
      state = AsyncData(nd);
      return null;
    } catch (loi, vet) {
      state = AsyncError(loi, vet);
      return 'Không lưu được hồ sơ. Vui lòng thử lại.';
    }
  }

  Future<void> dangXuat() async {
    await _kho.dangXuat();
    state = const AsyncData(null);
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
