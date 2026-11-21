import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/bai_hoc_screen.dart';
import '../screens/chi_tiet_screen.dart';
import '../screens/cua_toi_screen.dart';
import '../screens/dang_nhap_screen.dart';
import '../screens/danh_sach_screen.dart';
import '../screens/ho_so_screen.dart';
import '../screens/khong_tim_thay_screen.dart';
import '../screens/lich_su_giao_dich_screen.dart';
import '../screens/luyen_tap_screen.dart';
import '../screens/nang_cap_pro_screen.dart';
import '../screens/nap_coin_screen.dart';
import '../screens/thong_ke_screen.dart';
import '../screens/trang_chu_screen.dart';
import '../screens/vi_coin_screen.dart';
import '../viewmodels/providers.dart';
import '../widgets/khung_ung_dung.dart';
import 'duong_dan.dart';

/// Navigator gốc. Trang nào muốn chiếm trọn màn hình (không có thanh điều
/// hướng) thì khai `parentNavigatorKey: _khoaGoc`.
final GlobalKey<NavigatorState> _khoaGoc =
    GlobalKey<NavigatorState>(debugLabel: 'goc');

/// Navigator bên trong khung. Mọi trang thường nằm ở đây.
final GlobalKey<NavigatorState> _khoaKhung =
    GlobalKey<NavigatorState>(debugLabel: 'khung');

/// Cấu hình điều hướng của toàn ứng dụng.
///
/// ## Vì sao dùng go_router thay vì Navigator 2.0 như sách
///
/// Chương 5 của sách tự viết `RouterDelegate`, `RouteInformationParser` và
/// `RouteInformationProvider` — khoảng 200 dòng mã khuôn mẫu chỉ để có URL
/// hoạt động đúng. Đến 2026, `go_router` là gói điều hướng chính thức của
/// nhóm Flutter (publisher flutter.dev) và đã được tuyên bố hoàn thiện tính
/// năng. Dạy lại 200 dòng khuôn mẫu đó không còn là đầu tư tốt cho sinh viên.
///
/// Phần *khái niệm* của chương thì vẫn nguyên giá trị và được giữ lại: URL là
/// nguồn sự thật, trạng thái phải suy ra được từ đường dẫn, và điều hướng là
/// **khai báo** chứ không phải ra lệnh.
final boDinhTuyenProvider = Provider<GoRouter>((ref) {
  final langNghe = _LangNghePhien(ref);
  ref.onDispose(langNghe.dispose);

  return GoRouter(
    navigatorKey: _khoaGoc,
    initialLocation: DuongDan.trangChu,

    // Không có dòng này thì đăng nhập xong URL vẫn đứng yên: go_router chỉ
    // chạy lại `redirect` khi có điều hướng, hoặc khi listenable này báo đổi.
    refreshListenable: langNghe,

    redirect: (context, state) => _chuyenHuong(ref, state),

    // `errorBuilder` bắt mọi đường dẫn không khớp route nào — trên web đây là
    // tình huống thường gặp chứ không phải hiếm, vì người dùng gõ tay được.
    errorBuilder: (context, state) =>
        KhongTimThayScreen(diaChi: state.uri.toString()),

    routes: [
      ShellRoute(
        navigatorKey: _khoaKhung,
        builder: (context, state, child) => KhungUngDung(
          diaChiHienTai: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: DuongDan.trangChu,
            builder: (context, state) => const TrangChuScreen(),
          ),
          GoRoute(
            path: DuongDan.danhSach,
            // Bộ lọc nằm trong tham số truy vấn, không nằm trong trạng thái
            // widget. Nhờ vậy dán link kèm bộ lọc cho người khác vẫn đúng.
            builder: (context, state) => DanhSachScreen(
              thamSo: state.uri.queryParameters,
            ),
            routes: [
              GoRoute(
                path: DuongDan.doanMaKhoaHoc,
                builder: (context, state) => ChiTietScreen(
                  maKhoaHoc: state.pathParameters[DuongDan.thamSoMa] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: DuongDan.doanLuyenTap,
                    builder: (context, state) => LuyenTapScreen(
                      maKhoaHoc: state.pathParameters[DuongDan.thamSoMa] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: DuongDan.doanBaiHoc,
                    // Trang học chiếm trọn màn hình: đặt ở navigator gốc để
                    // thoát khỏi khung có thanh điều hướng.
                    parentNavigatorKey: _khoaGoc,
                    builder: (context, state) => BaiHocScreen(
                      maKhoaHoc: state.pathParameters[DuongDan.thamSoMa] ?? '',
                      maBaiHoc:
                          state.pathParameters[DuongDan.thamSoMaBai] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: DuongDan.cuaToi,
            builder: (context, state) => const CuaToiScreen(),
          ),
          GoRoute(
            path: DuongDan.hoSo,
            builder: (context, state) => const HoSoScreen(),
          ),
          GoRoute(
            path: DuongDan.thongKe,
            builder: (context, state) => const ThongKeScreen(),
          ),
          GoRoute(
            path: DuongDan.viCoin,
            builder: (context, state) => const ViCoinScreen(),
          ),
          GoRoute(
            path: DuongDan.napCoin,
            builder: (context, state) => const NapCoinScreen(),
          ),
          GoRoute(
            path: DuongDan.nangCapPro,
            builder: (context, state) => const NangCapProScreen(),
          ),
          GoRoute(
            path: DuongDan.lichSuGiaoDich,
            builder: (context, state) => const LichSuGiaoDichScreen(),
          ),
          GoRoute(
            path: DuongDan.dangNhap,
            builder: (context, state) => DangNhapScreen(
              diaChiTiep: state.uri.queryParameters[DuongDan.thamSoTiep],
            ),
          ),
        ],
      ),
    ],
  );
});

/// Luật chuyển hướng. Tách thành hàm riêng cho dễ đọc và dễ đối chiếu với
/// `test/duong_dan_test.dart`.
String? _chuyenHuong(Ref ref, GoRouterState state) {
  // Chưa xác minh xong phiên với backend thì chưa quyết định gì cả. Bỏ bước này thì
  // người đã đăng nhập sẽ thấy màn hình đăng nhập loé lên một nhịp.
  if (!ref.read(phienDaTaiProvider)) return null;

  final daDangNhap = ref.read(daDangNhapProvider);
  final dich = state.matchedLocation;

  if (!daDangNhap && DuongDan.phaiDangNhap(dich)) {
    return DuongDan.dangNhapRoiVe(state.uri.toString());
  }

  if (daDangNhap && dich == DuongDan.dangNhap) {
    return diaChiVeSauDangNhap(
      state.uri.queryParameters[DuongDan.thamSoTiep],
    );
  }

  return null;
}

/// Nơi cần quay về sau khi đăng nhập xong.
///
/// **Chỉ chấp nhận đường dẫn nội bộ** (bắt đầu bằng đúng một dấu `/`).
/// Không có chốt này thì ai đó gửi link
/// `…/dang-nhap?tiep=https://trang-gia-mao` là người dùng đăng nhập xong bị
/// ném thẳng sang trang khác. Lỗ hổng này có tên riêng: *open redirect*.
String diaChiVeSauDangNhap(String? tiep) {
  if (tiep == null || tiep.isEmpty) return DuongDan.trangChu;
  if (!tiep.startsWith('/')) return DuongDan.trangChu;
  // `//trang-khac` bị trình duyệt hiểu là URL tuyệt đối theo cùng giao thức.
  if (tiep.startsWith('//')) return DuongDan.trangChu;
  return tiep;
}

/// Cầu nối giữa Riverpod và go_router.
///
/// go_router cần một `Listenable`; Riverpod cung cấp `ref.listen`. Lớp bé
/// này ghép hai thứ lại: mỗi lần phiên đăng nhập đổi thì báo cho router chạy
/// lại `redirect`.
class _LangNghePhien extends ChangeNotifier {
  _LangNghePhien(Ref ref) {
    ref.listen(phienProvider, (truoc, sau) => notifyListeners());
  }
}
