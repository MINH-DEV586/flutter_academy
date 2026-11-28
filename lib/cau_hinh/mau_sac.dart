import 'package:material_ui/material_ui.dart';

/// Bảng màu và chủ đề của toàn ứng dụng.
///
/// Một `ColorScheme.fromSeed` duy nhất sinh ra cả bộ màu sáng lẫn tối, nên
/// không có mã màu nào rải rác trong các màn hình. Muốn đổi nhận diện: sửa
/// `mauGoc` là xong.
class ChuDe {
  ChuDe._();

  /// Màu chủ đạo EdTech hiện đại: Xanh Navy hoàng gia có chiều sâu.
  static const Color mauGoc = Color(0xFF1E40AF);
  static const Color mauPhu = Color(0xFF0284C7);
  static const Color mauVangPro = Color(0xFFF59E0B);
  static const Color mauXanhLuc = Color(0xFF10B981);

  /// Màu nền của ảnh bìa khoá học, chọn theo danh mục.
  /// Dùng chung với script Python sinh ảnh (`cong-cu/sinh_anh_bia.py`).
  static const Map<String, Color> mauDanhMuc = {
    'Nhập môn': Color(0xFF1E40AF),
    'Giao diện': Color(0xFF7C3AED),
    'Dữ liệu': Color(0xFF059669),
    'Kiến trúc': Color(0xFFEA580C),
    'Web': Color(0xFF0284C7),
    'Nâng cao': Color(0xFFBE123C),
  };

  static ThemeData sang() => _dung(Brightness.light);
  static ThemeData toi() => _dung(Brightness.dark);

  static ThemeData _dung(Brightness doSang) {
    final laToi = doSang == Brightness.dark;
    final bo = ColorScheme.fromSeed(
      seedColor: mauGoc,
      brightness: doSang,
      surface: laToi ? const Color(0xFF1E293B) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: bo,
      scaffoldBackgroundColor:
          laToi ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor:
            laToi ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: laToi ? const Color(0xFF1E293B) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: laToi ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: laToi ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            laToi ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: laToi ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: laToi ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: mauGoc,
            width: 1.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(
          color: laToi ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
