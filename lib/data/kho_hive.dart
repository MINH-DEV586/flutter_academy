import 'package:hive_ce/hive_ce.dart';

import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../models/tien_do.dart';
import 'du_lieu_mau.dart';
import 'kho_du_lieu.dart';

/// Tên các hộp Hive. Gom về một chỗ để không gõ sai chuỗi ở hai nơi.
class TenHop {
  TenHop._();
  // Danh mục YouTube dùng hộp riêng để trình duyệt tự nhận dữ liệu mới.
  static const String khoaHoc = 'khoa_hoc_youtube_v1';
  static const String tienDo = 'tien_do';
  static const String phien = 'phien';
}

/// Khoá trong hộp `phien`.
const String _khoaNguoiDung = 'nguoi_dung';

/// Kho khoá học đọc từ hộp Hive.
///
/// Hộp được truyền vào qua hàm dựng chứ không tự gọi `Hive.box(...)` bên
/// trong. Nhờ vậy bài kiểm thử truyền vào một hộp tạm là xong, không phải
/// động tới trạng thái toàn cục.
class HiveKhoKhoaHoc implements KhoKhoaHoc {
  final Box<KhoaHoc> hop;

  HiveKhoKhoaHoc(this.hop);

  /// Nạp dữ liệu mẫu nếu hộp còn trống.
  ///
  /// Mỗi phiên bản danh mục có hộp riêng, độc lập với tiến độ và phiên học.
  static Future<void> gieoNeuTrong(Box<KhoaHoc> hop) async {
    if (hop.isNotEmpty) return;
    await hop.putAll({
      for (final k in DuLieuMau.khoaHoc()) k.ma: k,
    });
  }

  @override
  Future<List<KhoaHoc>> tatCa() async => hop.values.toList(growable: false);

  @override
  Future<KhoaHoc?> theoMa(String ma) async => hop.get(ma);
}

/// Kho tiến độ học.
class HiveKhoTienDo implements KhoTienDo {
  final Box<TienDo> hop;

  HiveKhoTienDo(this.hop);

  @override
  Future<TienDo> cua(String maKhoaHoc) async =>
      hop.get(maKhoaHoc) ?? TienDo(maKhoaHoc: maKhoaHoc);

  @override
  Future<List<TienDo>> tatCa() async => hop.values.toList(growable: false);

  @override
  Future<void> luu(TienDo tienDo) => hop.put(tienDo.maKhoaHoc, tienDo);

  @override
  Future<void> xoa(String maKhoaHoc) => hop.delete(maKhoaHoc);
}

/// Kho phiên đăng nhập.
///
/// Không có mật khẩu, không có máy chủ: "đăng nhập" là ghi một bản ghi
/// `NguoiDung` xuống Hive. Phần còn lại của ứng dụng — kể cả `redirect` của
/// go_router — không biết và không cần biết điều đó.
class HiveKhoNguoiDung implements KhoNguoiDung {
  final Box<NguoiDung> hop;

  HiveKhoNguoiDung(this.hop);

  @override
  Future<NguoiDung?> hienTai() async => hop.get(_khoaNguoiDung);

  @override
  Future<void> dangNhap(NguoiDung nguoiDung) =>
      hop.put(_khoaNguoiDung, nguoiDung);

  @override
  Future<void> dangXuat() => hop.delete(_khoaNguoiDung);
}
