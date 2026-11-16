/// Hồ sơ người học.
///
/// Dự án này **không có máy chủ**: "đăng nhập" chỉ là ghi hồ sơ xuống Hive.
/// Lý do giữ nguyên bước đăng nhập dù không có máy chủ: toàn bộ phần điều
/// hướng có bảo vệ (`redirect` của go_router) và phần trạng thái phiên đều
/// cần một khái niệm "đã đăng nhập hay chưa". Khi thay bằng Firebase hay
/// Appwrite thì chỉ đổi phần cài đặt của `KhoNguoiDung`, mọi lớp khác giữ
/// nguyên — xem README mục "Thay kho cục bộ bằng máy chủ".
class NguoiDung {
  final String email;
  final String hoTen;

  /// Hai chữ cái đầu, dùng cho ảnh đại diện vẽ bằng chữ.
  String get chuVietTat {
    final phan = hoTen.trim().split(RegExp(r'\s+'));
    if (phan.isEmpty || phan.first.isEmpty) return '?';
    if (phan.length == 1) return phan.first.chuDau();
    return '${phan[phan.length - 2].chuDau()}'
        '${phan.last.chuDau()}';
  }

  const NguoiDung({required this.email, required this.hoTen});

  Map<String, dynamic> sangMap() => {'email': email, 'hoTen': hoTen};

  factory NguoiDung.tuMap(Map<dynamic, dynamic> m) => NguoiDung(
        email: m['email'] as String,
        hoTen: m['hoTen'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is NguoiDung && other.email == email && other.hoTen == hoTen;

  @override
  int get hashCode => Object.hash(email, hoTen);
}

extension on String {
  /// Ký tự đầu, viết hoa. Chuỗi rỗng trả về chuỗi rỗng.
  String chuDau() => isEmpty ? '' : substring(0, 1).toUpperCase();
}
