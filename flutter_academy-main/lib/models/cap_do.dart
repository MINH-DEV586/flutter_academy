/// Đại diện cho cấp độ (Level) của học viên dựa trên điểm kinh nghiệm (XP).
class CapDo {
  final int capHienTai;
  final int xpCuaCap;
  final int xpCanThiet;
  final String danhHieu;

  const CapDo({
    required this.capHienTai,
    required this.xpCuaCap,
    required this.xpCanThiet,
    required this.danhHieu,
  });

  /// Tỉ lệ phần trăm kinh nghiệm trong cấp hiện tại (0.0 - 1.0).
  double get tiLeTienDo {
    if (xpCanThiet <= 0) return 1.0;
    return (xpCuaCap / xpCanThiet).clamp(0.0, 1.0);
  }

  /// Tính cấp độ và thông tin liên quan từ tổng điểm kinh nghiệm (XP).
  ///
  /// Mức tăng XP mỗi cấp:
  /// - Cấp 1: 0 - 99 XP (cần 100 XP) -> Tập sự
  /// - Cấp 2: 100 - 249 XP (cần 150 XP) -> Nhập môn
  /// - Cấp 3: 250 - 449 XP (cần 200 XP) -> Chăm chỉ
  /// - Cấp 4: 450 - 699 XP (cần 250 XP) -> Tiến bộ
  /// - Cấp 5: 700 - 999 XP (cần 300 XP) -> Thành thạo
  /// - Cấp 6 - 10: Tăng dần (+50 XP mỗi cấp) -> Thực chiến
  /// - Cấp 11 - 20: -> Chuyên gia
  /// - Cấp 21+: -> Bậc thầy
  factory CapDo.tuTongXp(int tongXp) {
    var conLai = tongXp < 0 ? 0 : tongXp;
    var cap = 1;

    while (true) {
      final can = _xpYeuCauChoCap(cap);
      if (conLai < can) {
        return CapDo(
          capHienTai: cap,
          xpCuaCap: conLai,
          xpCanThiet: can,
          danhHieu: _layDanhHieu(cap),
        );
      }
      conLai -= can;
      cap++;
    }
  }

  /// Lượng XP cần thiết để vượt qua cấp `cap`.
  static int _xpYeuCauChoCap(int cap) {
    if (cap <= 1) return 100;
    return 100 + (cap - 1) * 50;
  }

  static String _layDanhHieu(int cap) {
    if (cap <= 1) return 'Tập sự';
    if (cap <= 2) return 'Nhập môn';
    if (cap <= 3) return 'Chăm chỉ';
    if (cap <= 4) return 'Tiến bộ';
    if (cap <= 5) return 'Thành thạo';
    if (cap <= 10) return 'Thực chiến';
    if (cap <= 20) return 'Chuyên gia';
    return 'Bậc thầy';
  }

  /// Kiểm tra xem khi tăng từ `xpCu` lên `xpMoi` có thăng cấp (Level Up) không.
  static bool kiemTraLenCap(int xpCu, int xpMoi) {
    if (xpMoi <= xpCu) return false;
    final capCu = CapDo.tuTongXp(xpCu).capHienTai;
    final capMoi = CapDo.tuTongXp(xpMoi).capHienTai;
    return capMoi > capCu;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapDo &&
          runtimeType == other.runtimeType &&
          capHienTai == other.capHienTai &&
          xpCuaCap == other.xpCuaCap &&
          xpCanThiet == other.xpCanThiet &&
          danhHieu == other.danhHieu;

  @override
  int get hashCode => Object.hash(capHienTai, xpCuaCap, xpCanThiet, danhHieu);

  @override
  String toString() =>
      'CapDo(Lv.$capHienTai - $danhHieu: $xpCuaCap/$xpCanThiet XP)';
}
