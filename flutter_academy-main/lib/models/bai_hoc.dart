/// Một bài học nằm trong khoá học.
///
/// Lớp bất biến (`final` hết) + `copyVoi` là khuôn mẫu dùng cho mọi model
/// trong dự án: đối tượng không tự đổi, muốn đổi thì tạo bản mới. Nhờ vậy
/// Riverpod so sánh trạng thái cũ/mới đáng tin cậy và widget không dựng lại
/// thừa.
class BaiHoc {
  final String ma;
  final String tieuDe;

  /// Thời lượng tính bằng giây. Dùng giây chứ không dùng phút vì phép cộng
  /// tổng thời lượng khoá học phải chính xác, không được làm tròn từng bài.
  final int thoiLuongGiay;

  /// Bài học xem thử được khi chưa ghi danh.
  final bool xemThu;

  const BaiHoc({
    required this.ma,
    required this.tieuDe,
    required this.thoiLuongGiay,
    this.xemThu = false,
  });

  BaiHoc copyVoi({
    String? ma,
    String? tieuDe,
    int? thoiLuongGiay,
    bool? xemThu,
  }) {
    return BaiHoc(
      ma: ma ?? this.ma,
      tieuDe: tieuDe ?? this.tieuDe,
      thoiLuongGiay: thoiLuongGiay ?? this.thoiLuongGiay,
      xemThu: xemThu ?? this.xemThu,
    );
  }

  Map<String, dynamic> sangMap() => {
        'ma': ma,
        'tieuDe': tieuDe,
        'thoiLuongGiay': thoiLuongGiay,
        'xemThu': xemThu,
      };

  factory BaiHoc.tuMap(Map<dynamic, dynamic> m) => BaiHoc(
        ma: m['ma'] as String,
        tieuDe: m['tieuDe'] as String,
        thoiLuongGiay: m['thoiLuongGiay'] as int,
        xemThu: m['xemThu'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) => other is BaiHoc && other.ma == ma;

  @override
  int get hashCode => ma.hashCode;

  @override
  String toString() => 'BaiHoc($ma)';
}
