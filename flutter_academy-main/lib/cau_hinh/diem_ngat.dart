import 'package:flutter/widgets.dart';

/// Ba khổ màn hình mà toàn bộ giao diện dựa vào.
///
/// Sách gọi là *responsive* (co giãn theo bề rộng) và *adaptive* (đổi hẳn
/// cách bố trí). Chương 3 của sách rải `MediaQuery.of(context).size.width`
/// khắp nơi; ở đây gom về một chỗ để:
///
///   * đổi ngưỡng một lần là cả ứng dụng đổi theo;
///   * hàm `tu()` là hàm thuần nên kiểm thử được bằng `flutter test`
///     mà không cần dựng widget nào.
enum Kho {
  /// Điện thoại: một cột.
  dienThoai,

  /// Máy tính bảng: hai cột, thanh điều hướng dạng `NavigationRail` thu gọn.
  mayTinhBang,

  /// Màn hình rộng: nhiều cột, thanh điều hướng mở rộng.
  manHinhRong;

  bool get laDienThoai => this == Kho.dienThoai;
  bool get laMayTinhBang => this == Kho.mayTinhBang;
  bool get laManHinhRong => this == Kho.manHinhRong;

  /// Từ máy tính bảng trở lên thì có chỗ cho thanh điều hướng bên trái.
  bool get coThanhBen => this != Kho.dienThoai;
}

class DiemNgat {
  DiemNgat._();

  /// Dưới ngưỡng này là điện thoại.
  static const double mayTinhBang = 720;

  /// Từ ngưỡng này trở lên là màn hình rộng.
  static const double manHinhRong = 1200;

  /// Bề rộng tối đa của phần nội dung. Trên màn 4K mà chữ chạy hết bề ngang
  /// thì mắt phải quét quá xa — mọi trang web nghiêm túc đều chặn lại.
  static const double rongToiDaNoiDung = 1180;

  /// Quy đổi bề rộng (pixel logic) sang khổ màn hình.
  ///
  /// Hàm thuần, không đụng tới `BuildContext` — đó là lý do kiểm thử được.
  static Kho tu(double rong) {
    if (rong < mayTinhBang) return Kho.dienThoai;
    if (rong < manHinhRong) return Kho.mayTinhBang;
    return Kho.manHinhRong;
  }

  /// Số cột của lưới thẻ khoá học theo bề rộng khả dụng.
  ///
  /// Không dùng thẳng `Kho` vì lưới nằm bên trong phần nội dung, bề rộng
  /// của nó nhỏ hơn bề rộng cửa sổ khi có thanh điều hướng bên trái.
  static int soCotLuoi(double rongKhaDung) {
    if (rongKhaDung < 560) return 1;
    if (rongKhaDung < 900) return 2;
    if (rongKhaDung < 1240) return 3;
    return 4;
  }
}

/// Đọc khổ màn hình từ `BuildContext`.
///
/// Tách phần "lấy số đo" (ở đây) khỏi phần "quyết định" (`DiemNgat.tu`)
/// chính là cách làm cho logic bố cục kiểm thử được.
extension KhoCuaContext on BuildContext {
  Kho get kho => DiemNgat.tu(MediaQuery.sizeOf(this).width);
}
