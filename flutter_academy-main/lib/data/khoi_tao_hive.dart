import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/chuoi_hoc.dart';
import '../models/khoa_hoc.dart';
import '../models/nhat_ky_ngay.dart';
import '../models/tien_do.dart';
import 'bo_chuyen_doi.dart';
import 'kho_hive.dart';

/// Gói gọn các hộp Hive đã mở, để `main()` chỉ phải truyền một đối tượng.
class HopDaMo {
  final Box<KhoaHoc> khoaHoc;
  final Box<TienDo> tienDo;
  final Box<String> phien;
  final Box<ChuoiHoc> chuoiHoc;
  final Box<NhatKyNgay> nhatKyHoc;

  const HopDaMo({
    required this.khoaHoc,
    required this.tienDo,
    required this.phien,
    required this.chuoiHoc,
    required this.nhatKyHoc,
  });
}

/// Khởi tạo Hive và mở toàn bộ hộp. Gọi trong `main()` trước `runApp`.
///
/// Trên web, `Hive.initFlutter()` bỏ qua đường dẫn thư mục và dùng IndexedDB
/// của trình duyệt — cùng một dòng mã chạy được cả sáu nền tảng.
///
/// Mở hộp **trước** `runApp` thay vì mở dần trong lúc chạy: ứng dụng chỉ có
/// một trạng thái khởi động duy nhất, không màn hình nào phải tự hỏi "hộp đã
/// mở chưa". Các hộp này rất nhỏ nên thời gian mở không đáng kể.
Future<HopDaMo> khoiTaoHive() async {
  await Hive.initFlutter();
  dangKyBoChuyenDoi();

  final khoaHoc = await Hive.openBox<KhoaHoc>(TenHop.khoaHoc);
  final tienDo = await Hive.openBox<TienDo>(TenHop.tienDo);
  final phien = await Hive.openBox<String>(TenHop.phien);
  final chuoiHoc = await Hive.openBox<ChuoiHoc>(TenHop.chuoiHoc);
  final nhatKyHoc = await Hive.openBox<NhatKyNgay>(TenHop.nhatKyHoc);

  await HiveKhoKhoaHoc.gieoNeuTrong(khoaHoc);

  return HopDaMo(
    khoaHoc: khoaHoc,
    tienDo: tienDo,
    phien: phien,
    chuoiHoc: chuoiHoc,
    nhatKyHoc: nhatKyHoc,
  );
}
