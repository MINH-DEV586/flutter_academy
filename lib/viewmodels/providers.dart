import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../models/che_do_giao_dien.dart';
import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../models/tien_do.dart';
import 'chu_de_vm.dart';
import 'phien_vm.dart';
import 'tien_do_vm.dart';

// ---------------------------------------------------------------------------
// Tầng kho dữ liệu
// ---------------------------------------------------------------------------

/// Ba provider này **luôn được ghi đè** trong `main()` (và trong kiểm thử).
///
/// Vì sao không tự tạo kho ngay tại đây: kho Hive cần hộp đã mở, mà mở hộp là
/// việc bất đồng bộ phải làm trước `runApp`. Để provider ném lỗi khi chưa ghi
/// đè là cố ý — quên ghi đè thì sập ngay lúc chạy thử chứ không âm thầm dùng
/// dữ liệu rỗng.
///
/// Đây cũng chính là cơ chế để kiểm thử: `ProviderScope(overrides: [...])`
/// thay ba dòng này bằng kho giả lập trong bộ nhớ.
final khoKhoaHocProvider = Provider<KhoKhoaHoc>(
  (ref) => throw UnimplementedError('Chưa ghi đè khoKhoaHocProvider'),
);

final khoTienDoProvider = Provider<KhoTienDo>(
  (ref) => throw UnimplementedError('Chưa ghi đè khoTienDoProvider'),
);

final khoNguoiDungProvider = Provider<KhoNguoiDung>(
  (ref) => throw UnimplementedError('Chưa ghi đè khoNguoiDungProvider'),
);

// ---------------------------------------------------------------------------
// Khoá học
// ---------------------------------------------------------------------------

/// Toàn bộ khoá học, đọc một lần từ kho.
final danhSachKhoaHocProvider = FutureProvider<List<KhoaHoc>>(
  (ref) => ref.watch(khoKhoaHocProvider).tatCa(),
);

// KHÔNG có provider nào giữ bộ lọc.
//
// Điều này là cố ý, và là điểm khác biệt lớn nhất giữa một ứng dụng web và
// một ứng dụng di động. Bộ lọc của trang danh sách sống trong THANH ĐỊA CHỈ
// (`/khoa-hoc?danh-muc=Web&sap=danh-gia`), không sống trong bộ nhớ. Thêm một
// provider giữ bản sao của nó là tạo ra nguồn sự thật thứ hai, và hai nguồn
// thì sớm muộn cũng lệch nhau — thường là sau khi người dùng bấm nút Back.
//
// Xem `screens/danh_sach_screen.dart` để thấy luồng dữ liệu đầy đủ.

/// Các khoá học nổi bật trên trang chủ (mục `FeaturedSection` của sách).
final khoaHocNoiBatProvider = Provider<AsyncValue<List<KhoaHoc>>>((ref) {
  final nguon = ref.watch(danhSachKhoaHocProvider);
  return switch (nguon) {
    AsyncData(:final value) =>
      AsyncData(value.where((k) => k.noiBat).toList(growable: false)),
    AsyncError(:final error, :final stackTrace) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

/// Danh sách danh mục có thật trong dữ liệu, dùng cho thanh lọc.
final danhMucProvider = Provider<List<String>>((ref) {
  final nguon = ref.watch(danhSachKhoaHocProvider);
  return switch (nguon) {
    AsyncData(:final value) => rutDanhMuc(value),
    _ => const <String>[],
  };
});

/// Rút danh sách danh mục, không trùng, giữ thứ tự xuất hiện.
///
/// Hàm thuần đặt ở ngoài để kiểm thử được mà không cần dựng `ProviderScope`.
List<String> rutDanhMuc(List<KhoaHoc> ds) {
  final thay = <String>{};
  final ra = <String>[];
  for (final k in ds) {
    if (thay.add(k.danhMuc)) ra.add(k.danhMuc);
  }
  return ra;
}

/// Tìm một khoá học theo mã trong danh sách đã tải.
///
/// Không dùng `Provider.family` vì toàn bộ khoá học đã nằm sẵn trong bộ nhớ:
/// thêm một họ provider chỉ để tra bảng là thêm phức tạp mà không được gì.
KhoaHoc? timKhoaHoc(List<KhoaHoc> ds, String ma) {
  for (final k in ds) {
    if (k.ma == ma) return k;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Tiến độ và phiên
// ---------------------------------------------------------------------------

final tienDoProvider =
    AsyncNotifierProvider<TienDoVM, Map<String, TienDo>>(TienDoVM.new);

final phienProvider = AsyncNotifierProvider<PhienVM, NguoiDung?>(
  PhienVM.new,
  retry: (_, _) => null,
);

/// Đã đăng nhập hay chưa. Lúc chưa tải xong thì coi như chưa — `redirect`
/// của go_router cần một câu trả lời đồng bộ, không chờ được.
final daDangNhapProvider = Provider<bool>((ref) {
  final p = ref.watch(phienProvider);
  return switch (p) {
    AsyncData(:final value) => value != null,
    _ => false,
  };
});

/// Đã tải xong phiên chưa. Dùng để hoãn `redirect` trong khoảnh khắc đầu
/// tiên: nếu chuyển hướng ngay khi chưa biết người dùng là ai, người đã đăng
/// nhập sẽ thấy màn hình đăng nhập loé lên một nhịp rồi mới biến mất.
final phienDaTaiProvider = Provider<bool>((ref) {
  final p = ref.watch(phienProvider);
  return switch (p) {
    AsyncData() => true,
    AsyncError() => true,
    _ => false,
  };
});

// ---------------------------------------------------------------------------
// Ghép khoá học với tiến độ
// ---------------------------------------------------------------------------

/// Phần trăm đã học của từng khoá, chỉ gồm những khoá đã bắt đầu.
///
/// Provider dẫn xuất thuần: ghép danh sách khoá học với bảng tiến độ. Widget
/// nào cần con số này chỉ việc `ref.watch`, không phải tự tính lại — và nhờ
/// vậy không có hai chỗ tính ra hai kết quả khác nhau.
final phanTramTienDoProvider = Provider<Map<String, int>>((ref) {
  final ds = ref.watch(danhSachKhoaHocProvider);
  final td = ref.watch(tienDoProvider);
  if (ds case AsyncData(value: final khoaHoc)) {
    if (td case AsyncData(value: final bang)) {
      return tinhPhanTram(khoaHoc, bang);
    }
  }
  return const {};
});

/// Tính phần trăm hoàn thành cho từng khoá học đã có tiến độ.
///
/// Hàm thuần, tách ra để kiểm thử. Ba luật ở đây đều đã từng bị làm sai
/// trong thực tế:
///
///   1. Tiến độ của khoá học **không còn tồn tại** thì bỏ qua, không tính.
///   2. Tiến độ ghi nhớ bài đã bị xoá khỏi khoá học thì phải lọc ra, nếu
///      không sẽ ra 120%.
///   3. Khoá học chưa có bài nào thì là 0%, không phải chia cho 0.
Map<String, int> tinhPhanTram(
  List<KhoaHoc> danhSach,
  Map<String, TienDo> bangTienDo,
) {
  final ra = <String, int>{};
  for (final k in danhSach) {
    final td = bangTienDo[k.ma];
    if (td == null) continue;
    final sach = td.donDep(k.baiHoc.map((b) => b.ma));
    ra[k.ma] = sach.phanTram(k.soBaiHoc);
  }
  return ra;
}

/// Những khoá học người dùng đã bắt đầu, xếp khoá chưa xong lên trước.
final khoaHocDangHocProvider = Provider<AsyncValue<List<KhoaHoc>>>((ref) {
  final ds = ref.watch(danhSachKhoaHocProvider);
  final phanTram = ref.watch(phanTramTienDoProvider);
  return switch (ds) {
    AsyncData(:final value) => AsyncData(locDangHoc(value, phanTram)),
    AsyncError(:final error, :final stackTrace) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

/// Lọc và sắp xếp danh sách "Khoá học của tôi".
///
/// Thứ tự: đang học dở trước (phần trăm cao hơn thì gần xong hơn, xếp trên),
/// rồi mới tới khoá đã hoàn thành.
List<KhoaHoc> locDangHoc(List<KhoaHoc> danhSach, Map<String, int> phanTram) {
  final ra = danhSach.where((k) => phanTram.containsKey(k.ma)).toList();
  ra.sort((a, b) {
    final pa = phanTram[a.ma] ?? 0;
    final pb = phanTram[b.ma] ?? 0;
    final xongA = pa >= 100 ? 1 : 0;
    final xongB = pb >= 100 ? 1 : 0;
    if (xongA != xongB) return xongA - xongB;
    final theoPhanTram = pb.compareTo(pa);
    if (theoPhanTram != 0) return theoPhanTram;
    return a.tieuDe.compareTo(b.tieuDe);
  });
  return ra;
}

// ---------------------------------------------------------------------------
// Giao diện
// ---------------------------------------------------------------------------

/// Chế độ sáng/tối. Ví dụ cho `Notifier` đồng bộ.
final chuDeProvider =
    NotifierProvider<ChuDeVM, CheDoGiaoDien>(ChuDeVM.new);
