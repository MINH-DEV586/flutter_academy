/// Gói thành viên Pro.
class GoiPro {
  final String id;
  final String name;
  final int durationDays;
  final int coinPrice;
  final String description;
  final List<String> benefits;

  const GoiPro({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.coinPrice,
    required this.description,
    this.benefits = const [],
  });

  factory GoiPro.tuMap(Map<String, dynamic> m) => GoiPro(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        durationDays: (m['durationDays'] as num?)?.toInt() ?? 30,
        coinPrice: (m['coinPrice'] as num?)?.toInt() ?? 0,
        description: m['description'] as String? ?? '',
        benefits: (m['benefits'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );

  Map<String, dynamic> sangMap() => {
        'id': id,
        'name': name,
        'durationDays': durationDays,
        'coinPrice': coinPrice,
        'description': description,
        'benefits': benefits,
      };
}

/// Lịch sử đăng ký gói Pro của người dùng.
class LichSuThanhVien {
  final String id;
  final String packageId;
  final String packageName;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String status;
  final DateTime createdAt;

  const LichSuThanhVien({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  factory LichSuThanhVien.tuMap(Map<String, dynamic> m) => LichSuThanhVien(
        id: m['id'] as String? ?? '',
        packageId: m['packageId'] as String? ?? '',
        packageName: m['packageName'] as String? ?? '',
        startedAt: DateTime.tryParse(m['startedAt'] as String? ?? '') ?? DateTime.now(),
        expiresAt: DateTime.tryParse(m['expiresAt'] as String? ?? '') ?? DateTime.now(),
        status: m['status'] as String? ?? 'active',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  bool get laHieuLuc =>
      status == 'active' && expiresAt.isAfter(DateTime.now());
}

/// Trạng thái gói thành viên của người dùng hiện tại.
class TrangThaiThanhVien {
  final bool isPro;
  final DateTime? expiresAt;
  final String? packageId;
  final DateTime? startedAt;
  final List<LichSuThanhVien> history;

  const TrangThaiThanhVien({
    this.isPro = false,
    this.expiresAt,
    this.packageId,
    this.startedAt,
    this.history = const [],
  });

  bool get daHetHan {
    if (!isPro || expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get soNgayConLai {
    if (!isPro || expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory TrangThaiThanhVien.tuMap(Map<String, dynamic> m) =>
      TrangThaiThanhVien(
        isPro: m['isPro'] as bool? ?? false,
        expiresAt: m['expiresAt'] != null
            ? DateTime.tryParse(m['expiresAt'] as String)
            : null,
        packageId: m['packageId'] as String?,
        startedAt: m['startedAt'] != null
            ? DateTime.tryParse(m['startedAt'] as String)
            : null,
        history: (m['history'] as List?)
                ?.map((e) => LichSuThanhVien.tuMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
