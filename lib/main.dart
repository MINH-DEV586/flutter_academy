import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/kho_hive.dart';
import 'data/khoi_tao_hive.dart';
import 'data/kho_tai_khoan.dart';
import 'viewmodels/providers.dart';

/// Điểm vào của ứng dụng.
///
/// Ba việc, đúng thứ tự:
///
///   1. `ensureInitialized` — bắt buộc khi có việc bất đồng bộ trước
///      `runApp`, nếu không thì Flutter chưa sẵn sàng nhận lời gọi nền tảng.
///   2. Mở các hộp Hive.
///   3. Nối kho danh mục và tiến độ với Hive, kho tài khoản với backend.
///
/// Bước 3 chính là chỗ **lắp ghép** toàn bộ ứng dụng. Ngoài tệp này, không
/// có dòng mã nào biết rằng dữ liệu được lưu bằng Hive. Muốn đổi sang
/// Firebase hay Appwrite (Chương 9–10 của sách): sửa ba dòng ở đây.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hop = await khoiTaoHive();
  final khoTaiKhoan = KhoTaiKhoan(hop.phien);

  runApp(
    ProviderScope(
      overrides: [
        khoKhoaHocProvider.overrideWithValue(HiveKhoKhoaHoc(hop.khoaHoc)),
        khoTienDoProvider.overrideWithValue(HiveKhoTienDo(hop.tienDo)),
        khoNguoiDungProvider.overrideWithValue(khoTaiKhoan),
        khoDongBoChuoiHocProvider.overrideWithValue(khoTaiKhoan),
        khoChuoiHocProvider.overrideWithValue(
          HiveKhoChuoiHoc(
            hopChuoiHoc: hop.chuoiHoc,
            hopNhatKy: hop.nhatKyHoc,
          ),
        ),
      ],
      child: const UngDung(),
    ),
  );
}
