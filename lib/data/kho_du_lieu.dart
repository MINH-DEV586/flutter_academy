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

import '../models/chuoi_hoc.dart';
import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../models/nhat_ky_ngay.dart';
import '../models/tien_do.dart';



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
}

abstract interface class KhoChuoiHoc {
  /// Lấy thông tin chuỗi học tập hiện tại. Trả về mặc định nếu chưa có.
  Future<ChuoiHoc> lay();

  /// Lưu trạng thái chuỗi học tập.
  Future<void> luu(ChuoiHoc chuoiHoc);

  /// Lấy nhật ký của một ngày cụ thể.
  Future<NhatKyNgay> layNhatKy(String ngay);

  /// Lấy danh sách nhật ký các ngày trong một tháng để vẽ lịch.
  Future<Map<String, NhatKyNgay>> nhatKyTrongThang(int nam, int thang);

  /// Lưu nhật ký một ngày.
  Future<void> luuNhatKy(NhatKyNgay nhatKy);
}

class LoiTaiKhoan implements Exception {
  const LoiTaiKhoan(this.thongBao);

  final String thongBao;
}
