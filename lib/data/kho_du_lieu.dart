/// Ba giao diện kho dữ liệu — **tầng ranh giới của toàn dự án**.
///
/// Mọi thứ ở trên (ViewModel, màn hình) chỉ biết ba lớp trừu tượng này. Mọi
/// thứ ở dưới (Hive, và sau này có thể là Firebase hay Appwrite) chỉ việc
/// cài đặt chúng.
///
/// Đây là lý do Chương 9 (Appwrite) và Chương 10 (Firebase) của sách không
/// được dựng lại thành hai bản ứng dụng riêng: chúng chỉ là **hai cách cài
/// đặt khác của chính ba giao diện này**. Muốn đổi sang máy chủ, viết thêm
/// `FirebaseKhoKhoaHoc implements KhoKhoaHoc` rồi đổi một dòng trong
/// `viewmodels/providers.dart`. Không màn hình nào phải sửa.
///
/// Toàn bộ phương thức đều `Future` dù bản Hive trả về gần như tức thì. Cố ý
/// như vậy: nếu khai báo đồng bộ thì bản chạy trên mạng sau này sẽ không
/// khớp giao diện, và lúc đó phải sửa cả ứng dụng.
library;

import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../models/tien_do.dart';
import '../models/thuong_hoc.dart';



abstract interface class KhoKhoaHoc {
  Future<List<KhoaHoc>> tatCa();

  /// Trả về null khi không có khoá học nào mang mã đó — người dùng có thể
  /// dán một URL cũ.
  Future<KhoaHoc?> theoMa(String ma);
}

abstract interface class KhoTienDo {
  /// Tiến độ của một khoá. Chưa học bao giờ thì trả về tiến độ rỗng chứ
  /// không trả về null — người gọi không phải kiểm tra null ở mọi chỗ.
  Future<TienDo> cua(String maKhoaHoc);

  /// Toàn bộ tiến độ đã lưu, dùng cho trang "Khoá học của tôi".
  Future<List<TienDo>> tatCa();

  Future<void> luu(TienDo tienDo);

  Future<void> xoa(String maKhoaHoc);
}

abstract interface class KhoNguoiDung {
  /// Người đang đăng nhập, null nếu chưa.
  Future<NguoiDung?> hienTai();

  Future<NguoiDung> dangNhap({required String email, required String matKhau});

  Future<NguoiDung> dangKy({
    required String email,
    required String hoTen,
    required String matKhau,
  });

  Future<void> dangXuat();

  Future<Set<String>> khoaDaDangKy();

  Future<void> dangKyKhoaHoc(String maKhoaHoc);

  Future<ThuongHoc> thuongHoc();
  Future<ThuongHoc> ghiNhanNgayHoc(String baiHoc);
  Future<String> yeuCauDoiPro(String vi);
  Future<ThuongHoc> xacNhanDoiPro(String hash);
  Future<String> hoiAi({
    required String baiHoc,
    required String cauHoi,
    required String mucDo,
  });
}

class LoiTaiKhoan implements Exception {
  const LoiTaiKhoan(this.thongBao);

  final String thongBao;
}
