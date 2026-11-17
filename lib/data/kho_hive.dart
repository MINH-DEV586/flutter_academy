import 'package:hive_ce/hive_ce.dart';

import '../models/khoa_hoc.dart';
import '../models/tien_do.dart';
import 'du_lieu_mau.dart';
import 'kho_du_lieu.dart';

/// Tên các hộp Hive. Gom về một chỗ để không gõ sai chuỗi ở hai nơi.
class TenHop {
  TenHop._();
  // Danh mục YouTube dùng hộp riêng để trình duyệt tự nhận dữ liệu mới.
  static const String khoaHoc = 'khoa_hoc_youtube_v2';
  static const String tienDo = 'tien_do';
  static const String phien = 'phien_tai_khoan';
}

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
