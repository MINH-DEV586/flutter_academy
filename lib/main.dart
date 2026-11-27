import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/kho_gia_su_ai.dart';
import 'data/kho_hive.dart';
import 'data/kho_thanh_vien.dart';
import 'data/kho_thuong_chuoi.dart';
import 'data/kho_vi_coin.dart';
import 'data/khoi_tao_hive.dart';
import 'data/kho_tai_khoan.dart';
import 'viewmodels/providers.dart';
import 'viewmodels/gia_su_ai_vm.dart';
import 'viewmodels/thuong_chuoi_vm.dart';

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
        khoTienDoProvider.overrideWith(
          (ref) =>
              HiveKhoTienDo(hop.tienDo, email: ref.watch(emailHocVienProvider)),
        ),
        khoNguoiDungProvider.overrideWithValue(khoTaiKhoan),
        khoGiaSuAiProvider.overrideWithValue(
          HttpKhoGiaSuAi(hop.giaSuAi, hop.phien),
        ),
        khoThuongChuoiProvider.overrideWithValue(
          HttpKhoThuongChuoi(hop.thuongDangCho, hop.phien),
        ),
        khoDongBoChuoiHocProvider.overrideWithValue(khoTaiKhoan),
        khoNhatKyDemoProvider.overrideWithValue(khoTaiKhoan),
        khoChuoiHocProvider.overrideWith(
          (ref) => HiveKhoChuoiHoc(
            hopChuoiHoc: hop.chuoiHoc,
            hopNhatKy: hop.nhatKyHoc,
            email: ref.watch(emailHocVienProvider),
          ),
        ),
        khoViCoinProvider.overrideWithValue(HttpKhoViCoin(hop.phien)),
        khoThanhVienProvider.overrideWithValue(HttpKhoThanhVien(hop.phien)),
      ],
      child: const UngDung(),
    ),
  );
}
