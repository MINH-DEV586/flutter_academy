/// Tiến độ học của một khoá.
///
/// Chỉ lưu **mã các bài đã xong**, không lưu phần trăm. Phần trăm là thứ
/// tính được, mà đã tính được thì không lưu — lưu cả hai là mời gọi hai
/// nguồn sự thật lệch nhau.
class TienDo {
  final String maKhoaHoc;
  final Set<String> baiDaXong;

  /// Bài học đang xem dở, để nút "Học tiếp" biết nhảy về đâu.
  final String? baiDangXem;

  const TienDo({
    required this.maKhoaHoc,
    this.baiDaXong = const {},
    this.baiDangXem,
  });

  bool daXong(String maBai) => baiDaXong.contains(maBai);

  /// Tỉ lệ hoàn thành 0.0–1.0 so với `tongSoBai`.
  ///
  /// `tongSoBai` truyền từ ngoài vào chứ không lưu trong đối tượng này: khoá
  /// học có thể được bổ sung bài mới, lúc đó tiến độ cũ vẫn tính đúng.
  double tiLe(int tongSoBai) {
    if (tongSoBai <= 0) return 0;
    // Chỉ đếm những bài đã xong mà vẫn còn trong khoá học? Không — hàm này
    // không biết danh sách bài. Việc lọc do `donDep` lo, gọi khi nạp dữ liệu.
    final xong = baiDaXong.length;
    if (xong >= tongSoBai) return 1;
    return xong / tongSoBai;
  }

  int phanTram(int tongSoBai) => (tiLe(tongSoBai) * 100).round();

  bool hoanThanh(int tongSoBai) => tongSoBai > 0 && baiDaXong.length >= tongSoBai;

  /// Bỏ khỏi tiến độ những mã bài không còn tồn tại trong khoá học.
  ///
  /// Gọi khi nạp dữ liệu. Không có bước này thì một khoá học bị xoá bớt bài
  /// sẽ hiện tiến độ trên 100%.
  TienDo donDep(Iterable<String> maBaiHienCo) {
    final hienCo = maBaiHienCo.toSet();
    final loc = baiDaXong.where(hienCo.contains).toSet();
    final dangXem =
        baiDangXem != null && hienCo.contains(baiDangXem) ? baiDangXem : null;
    if (loc.length == baiDaXong.length && dangXem == baiDangXem) return this;
    return TienDo(
      maKhoaHoc: maKhoaHoc,
      baiDaXong: loc,
      baiDangXem: dangXem,
    );
  }

  /// Bật/tắt trạng thái hoàn thành của một bài.
  TienDo daoTrangThai(String maBai) {
    final moi = Set<String>.from(baiDaXong);
    if (!moi.remove(maBai)) moi.add(maBai);
    return TienDo(
      maKhoaHoc: maKhoaHoc,
      baiDaXong: moi,
      baiDangXem: baiDangXem,
    );
  }

  TienDo danhDauDangXem(String maBai) => TienDo(
        maKhoaHoc: maKhoaHoc,
        baiDaXong: baiDaXong,
        baiDangXem: maBai,
      );

  Map<String, dynamic> sangMap() => {
        'maKhoaHoc': maKhoaHoc,
        'baiDaXong': baiDaXong.toList(),
        'baiDangXem': baiDangXem,
      };

  factory TienDo.tuMap(Map<dynamic, dynamic> m) => TienDo(
        maKhoaHoc: m['maKhoaHoc'] as String,
        baiDaXong: (m['baiDaXong'] as List).map((e) => e as String).toSet(),
        baiDangXem: m['baiDangXem'] as String?,
      );

  @override
  String toString() => 'TienDo($maKhoaHoc: ${baiDaXong.length} bài)';
}
