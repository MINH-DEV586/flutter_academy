/// Nhật ký hoạt động học tập chi tiết của một ngày cụ thể (YYYY-MM-DD).
///
/// Dùng để:
/// - Hiển thị trạng thái trên Lịch học theo tháng (đã học, chưa học, dùng Freeze).
/// - Xem chi tiết ngày: thời gian học, số bài hoàn thành, các khoá học tham gia,
///   XP nhận được và hoạt động đã giúp duy trì chuỗi.
class NhatKyNgay {
  final String ngay; // Định dạng YYYY-MM-DD
  final int thoiGianHocGiay;
  final Set<String> baiDaHoanThanh;
  final Set<String> khoaHocDaThamGia;
  final int xpNhanDuoc;
  final bool dungFreeze;
  final String? hoatDongDuyTri;

  const NhatKyNgay({
    required this.ngay,
    this.thoiGianHocGiay = 0,
    this.baiDaHoanThanh = const {},
    this.khoaHocDaThamGia = const {},
    this.xpNhanDuoc = 0,
    this.dungFreeze = false,
    this.hoatDongDuyTri,
  });

  /// Thời gian học quy đổi ra phút.
  int get thoiGianHocPhut => (thoiGianHocGiay / 60).round();

  /// Đạt điều kiện tính ngày học hợp lệ (tối thiểu 10 phút = 600 giây,
  /// hoặc hoàn thành ít nhất 1 bài học/bài kiểm tra, hoặc dùng Freeze).
  bool get datDieuKienStreak =>
      dungFreeze || thoiGianHocGiay >= 600 || baiDaHoanThanh.isNotEmpty;

  /// Ghi nhận thêm hoạt động học trong ngày.
  NhatKyNgay ghiNhanThem({
    int giayCongThem = 0,
    String? maBaiMoi,
    String? maKhoaHocMoi,
    int xpCongThem = 0,
    String? moTaHoatDong,
  }) {
    final baiMoi = Set<String>.from(baiDaHoanThanh);
    if (maBaiMoi != null) baiMoi.add(maBaiMoi);

    final khoaMoi = Set<String>.from(khoaHocDaThamGia);
    if (maKhoaHocMoi != null) khoaMoi.add(maKhoaHocMoi);

    final thoiGianMoi = thoiGianHocGiay + giayCongThem;
    final xpMoi = xpNhanDuoc + xpCongThem;

    String? hoatDong = hoatDongDuyTri;
    if (moTaHoatDong != null) {
      hoatDong = moTaHoatDong;
    } else if (baiMoi.isNotEmpty) {
      hoatDong = 'Hoàn thành ${baiMoi.length} bài học/kiểm tra';
    } else if (thoiGianMoi >= 600) {
      hoatDong = 'Học video ${(thoiGianMoi / 60).round()} phút';
    }

    return NhatKyNgay(
      ngay: ngay,
      thoiGianHocGiay: thoiGianMoi,
      baiDaHoanThanh: baiMoi,
      khoaHocDaThamGia: khoaMoi,
      xpNhanDuoc: xpMoi,
      dungFreeze: dungFreeze,
      hoatDongDuyTri: hoatDong,
    );
  }

  /// Đánh dấu ngày này được bảo vệ bởi Khiên Freeze.
  NhatKyNgay danhDauDungFreeze() => NhatKyNgay(
        ngay: ngay,
        thoiGianHocGiay: thoiGianHocGiay,
        baiDaHoanThanh: baiDaHoanThanh,
        khoaHocDaThamGia: khoaHocDaThamGia,
        xpNhanDuoc: xpNhanDuoc,
        dungFreeze: true,
        hoatDongDuyTri: 'Được bảo vệ bởi Khiên Freeze 🛡️',
      );

  Map<String, dynamic> sangMap() => {
        'ngay': ngay,
        'thoiGianHocGiay': thoiGianHocGiay,
        'baiDaHoanThanh': baiDaHoanThanh.toList(),
        'khoaHocDaThamGia': khoaHocDaThamGia.toList(),
        'xpNhanDuoc': xpNhanDuoc,
        'dungFreeze': dungFreeze,
        'hoatDongDuyTri': hoatDongDuyTri,
      };

  factory NhatKyNgay.tuMap(Map<dynamic, dynamic> m) => NhatKyNgay(
        ngay: m['ngay'] as String,
        thoiGianHocGiay: (m['thoiGianHocGiay'] as num?)?.toInt() ?? 0,
        baiDaHoanThanh: ((m['baiDaHoanThanh'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        khoaHocDaThamGia: ((m['khoaHocDaThamGia'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        xpNhanDuoc: (m['xpNhanDuoc'] as num?)?.toInt() ?? 0,
        dungFreeze: m['dungFreeze'] as bool? ?? false,
        hoatDongDuyTri: m['hoatDongDuyTri'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NhatKyNgay &&
          runtimeType == other.runtimeType &&
          ngay == other.ngay &&
          thoiGianHocGiay == other.thoiGianHocGiay &&
          baiDaHoanThanh.length == other.baiDaHoanThanh.length &&
          baiDaHoanThanh.containsAll(other.baiDaHoanThanh) &&
          khoaHocDaThamGia.length == other.khoaHocDaThamGia.length &&
          khoaHocDaThamGia.containsAll(other.khoaHocDaThamGia) &&
          xpNhanDuoc == other.xpNhanDuoc &&
          dungFreeze == other.dungFreeze &&
          hoatDongDuyTri == other.hoatDongDuyTri;

  @override
  int get hashCode => Object.hash(
        ngay,
        thoiGianHocGiay,
        Object.hashAll(baiDaHoanThanh),
        Object.hashAll(khoaHocDaThamGia),
        xpNhanDuoc,
        dungFreeze,
        hoatDongDuyTri,
      );

  @override
  String toString() =>
      'NhatKyNgay($ngay: ${thoiGianHocPhut}p, ${baiDaHoanThanh.length} bài, +${xpNhanDuoc}XP, freeze: $dungFreeze)';
}
