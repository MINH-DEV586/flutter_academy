import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/chuoi_hoc.dart';
import '../models/khoa_hoc.dart';
import '../models/nhat_ky_ngay.dart';
import '../models/tien_do.dart';
import 'du_lieu_mau.dart';
import 'kho_du_lieu.dart';

/// Tên các hộp Hive. Gom về một chỗ để không gõ sai chuỗi ở hai nơi.
class TenHop {
  TenHop._();
  // Danh mục YouTube dùng hộp riêng để trình duyệt tự nhận dữ liệu mới.
  static const String khoaHoc = 'khoa_hoc_youtube_v3';
  static const String tienDo = 'tien_do';
  static const String phien = 'phien_tai_khoan';
  static const String chuoiHoc = 'chuoi_hoc';
  static const String nhatKyHoc = 'nhat_ky_hoc';
}

/// Kho khoá học đọc từ hộp Hive.
///
/// Hộp được truyền vào qua hàm dựng chứ không tự gọi `Hive.box(...)` bên
/// trong. Nhờ vậy bài kiểm thử truyền vào một hộp tạm là xong, không phải
/// động tới trạng thái toàn cục.
class HiveKhoKhoaHoc implements KhoKhoaHoc {
  final Box<KhoaHoc> hop;

  HiveKhoKhoaHoc(this.hop);

  /// Nạp dữ liệu mẫu nếu hộp còn trống hoặc cập nhật danh mục mới.
  ///
  /// Mỗi phiên bản danh mục có hộp riêng, độc lập với tiến độ và phiên học.
  static Future<void> gieoNeuTrong(Box<KhoaHoc> hop) async {
    final danhSach = DuLieuMau.khoaHoc();
    for (final k in danhSach) {
      final hienTai = hop.get(k.ma);
      if (hienTai == null ||
          hienTai.laPro != k.laPro ||
          hienTai.baiHoc.length != k.baiHoc.length) {
        await hop.put(k.ma, k);
      }
    }
  }

  @override
  Future<List<KhoaHoc>> tatCa() async => hop.values.toList(growable: false);

  @override
  Future<KhoaHoc?> theoMa(String ma) async => hop.get(ma);
}

/// Kho tiến độ học.
class HiveKhoTienDo implements KhoTienDo {
  final Box<TienDo> hop;
  final String _phien;

  HiveKhoTienDo(this.hop, {String? email}) : _phien = _tienToHocVien(email);

  @override
  Future<TienDo> cua(String maKhoaHoc) async =>
      hop.get('$_phien$maKhoaHoc') ?? TienDo(maKhoaHoc: maKhoaHoc);

  @override
  Future<List<TienDo>> tatCa() async => [
    for (final key in hop.keys)
      if (key is String && key.startsWith(_phien)) ?hop.get(key),
  ];

  @override
  Future<void> luu(TienDo tienDo) =>
      hop.put('$_phien${tienDo.maKhoaHoc}', tienDo);

  @override
  Future<void> xoa(String maKhoaHoc) => hop.delete('$_phien$maKhoaHoc');
}

// Các khóa không có tiền tố là dữ liệu cũ không xác định được chủ sở hữu.
String _tienToHocVien(String? email) =>
    email == null ? 'v2:khach:' : 'v2:email:${sha256.convert(utf8.encode(email))}:';

/// Kho lưu trữ Chuỗi học tập và Nhật ký ngày bằng Hive.
class HiveKhoChuoiHoc implements KhoChuoiHoc {
  final Box<ChuoiHoc> hopChuoiHoc;
  final Box<NhatKyNgay> hopNhatKy;
  final String _phien;

  HiveKhoChuoiHoc({
    required this.hopChuoiHoc,
    required this.hopNhatKy,
    String? email,
  }) : _phien = _tienToHocVien(email);

  @override
  Future<ChuoiHoc> lay() async =>
      hopChuoiHoc.get('${_phien}hien_tai') ?? const ChuoiHoc();

  @override
  Future<void> luu(ChuoiHoc chuoiHoc) =>
      hopChuoiHoc.put('${_phien}hien_tai', chuoiHoc);

  @override
  Future<NhatKyNgay> layNhatKy(String ngay) async =>
      hopNhatKy.get('$_phien$ngay') ?? NhatKyNgay(ngay: ngay);

  @override
  Future<Map<String, NhatKyNgay>> nhatKyTrongThang(int nam, int thang) async {
    final prefix =
        '$_phien${nam.toString().padLeft(4, '0')}-${thang.toString().padLeft(2, '0')}-';
    final ketQua = <String, NhatKyNgay>{};
    for (final key in hopNhatKy.keys) {
      if (key is String && key.startsWith(prefix)) {
        final val = hopNhatKy.get(key);
        if (val != null) ketQua[val.ngay] = val;
      }
    }
    return ketQua;
  }

  @override
  Future<void> luuNhatKy(NhatKyNgay nhatKy) =>
      hopNhatKy.put('$_phien${nhatKy.ngay}', nhatKy);
}
