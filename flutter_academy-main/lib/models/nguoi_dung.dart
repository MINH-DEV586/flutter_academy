/// Hồ sơ người học.
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
