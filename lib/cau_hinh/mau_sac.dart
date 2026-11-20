import 'package:material_ui/material_ui.dart';

/// Bảng màu và chủ đề của toàn ứng dụng.
///
/// Một `ColorScheme.fromSeed` duy nhất sinh ra cả bộ màu sáng lẫn tối, nên
/// không có mã màu nào rải rác trong các màn hình. Muốn đổi nhận diện: sửa
/// `mauGoc` là xong.
class ChuDe {
  ChuDe._();

  static const Color mauGoc = Color(0xFF1B5E9B);

  /// Màu nền của ảnh bìa khoá học, chọn theo danh mục.
  /// Dùng chung với script Python sinh ảnh (`cong-cu/sinh_anh_bia.py`).
  static const Map<String, Color> mauDanhMuc = {
    'Nhập môn': Color(0xFF1B5E9B),
    'Giao diện': Color(0xFF7B3F9E),
    'Dữ liệu': Color(0xFF0E7C66),
    'Kiến trúc': Color(0xFFB54A17),
    'Web': Color(0xFF1C6FA8),
    'Nâng cao': Color(0xFF8A2846),
  };

  static ThemeData sang() => _dung(Brightness.light);
  static ThemeData toi() => _dung(Brightness.dark);

  static ThemeData _dung(Brightness doSang) {
    final bo = ColorScheme.fromSeed(seedColor: mauGoc, brightness: doSang);
    return ThemeData(
      useMaterial3: true,
      colorScheme: bo,
      scaffoldBackgroundColor: bo.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: bo.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: bo.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bo.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
