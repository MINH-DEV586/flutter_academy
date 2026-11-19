/// Huy hiệu thành tích mở khoá theo các cột mốc Streak.
class HuyHieu {
  final String ma;
  final String tieuDe;
  final String moTa;
  final int mocNgay;
  final String bieuTuong;
  final String? ngayDatDuoc;

  const HuyHieu({
    required this.ma,
    required this.tieuDe,
    required this.moTa,
    required this.mocNgay,
    required this.bieuTuong,
    this.ngayDatDuoc,
  });

  bool get daDat => ngayDatDuoc != null;

  /// Danh sách toàn bộ các cột mốc huy hiệu Streak theo chuẩn của hệ thống.
  static const List<HuyHieu> tatCaMoc = [
    HuyHieu(
      ma: 'streak_3',
      tieuDe: 'Getting Started',
      moTa: 'Duy trì chuỗi học tập 3 ngày liên tiếp',
      mocNgay: 3,
      bieuTuong: '🌱',
    ),
    HuyHieu(
      ma: 'streak_7',
      tieuDe: 'Weekly Learner',
      moTa: 'Hoàn thành trọn vẹn chuỗi học tập 1 tuần (7 ngày)',
      mocNgay: 7,
      bieuTuong: '⚡',
    ),
    HuyHieu(
      ma: 'streak_14',
      tieuDe: 'Consistent Learner',
      moTa: 'Duy trì học tập kiên định suốt 2 tuần (14 ngày)',
      mocNgay: 14,
      bieuTuong: '🔥',
    ),
    HuyHieu(
      ma: 'streak_30',
      tieuDe: 'Monthly Champion',
      moTa: 'Nhà vô địch học tập của tháng (30 ngày liên tục)',
      mocNgay: 30,
      bieuTuong: '🏆',
    ),
    HuyHieu(
      ma: 'streak_60',
      tieuDe: 'Dedicated Learner',
      moTa: 'Học viên tận tâm và bền bỉ trong 60 ngày',
      mocNgay: 60,
      bieuTuong: '🎖️',
    ),
    HuyHieu(
      ma: 'streak_100',
      tieuDe: 'Streak Master',
      moTa: 'Bậc thầy chuỗi học tập với 100 ngày liên tiếp',
      mocNgay: 100,
      bieuTuong: '👑',
    ),
    HuyHieu(
      ma: 'streak_365',
      tieuDe: 'Legendary Learner',
      moTa: 'Huyền thoại học tập suốt 365 ngày trọn vẹn 1 năm',
      mocNgay: 365,
      bieuTuong: '🌟',
    ),
  ];

  /// Kiểm tra các huy hiệu mới được mở khoá khi chuỗi đạt `soNgayStreak`.
  static List<HuyHieu> kiemTraMoKhoa({
    required int soNgayStreak,
    required Set<String> cacMaDaDat,
    required String ngayHienTai,
  }) {
    final danhSachMoi = <HuyHieu>[];
    for (final h in tatCaMoc) {
      if (soNgayStreak >= h.mocNgay && !cacMaDaDat.contains(h.ma)) {
        danhSachMoi.add(
          HuyHieu(
            ma: h.ma,
            tieuDe: h.tieuDe,
            moTa: h.moTa,
            mocNgay: h.mocNgay,
            bieuTuong: h.bieuTuong,
            ngayDatDuoc: ngayHienTai,
          ),
        );
      }
    }
    return danhSachMoi;
  }

  Map<String, dynamic> sangMap() => {
        'ma': ma,
        'tieuDe': tieuDe,
        'moTa': moTa,
        'mocNgay': mocNgay,
        'bieuTuong': bieuTuong,
        'ngayDatDuoc': ngayDatDuoc,
      };

  factory HuyHieu.tuMap(Map<dynamic, dynamic> m) => HuyHieu(
        ma: m['ma'] as String,
        tieuDe: m['tieuDe'] as String,
        moTa: m['moTa'] as String,
        mocNgay: (m['mocNgay'] as num).toInt(),
        bieuTuong: m['bieuTuong'] as String,
        ngayDatDuoc: m['ngayDatDuoc'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HuyHieu && runtimeType == other.runtimeType && ma == other.ma;

  @override
  int get hashCode => ma.hashCode;

  @override
  String toString() => 'HuyHieu($ma: $tieuDe [$bieuTuong], dat: $ngayDatDuoc)';
}
