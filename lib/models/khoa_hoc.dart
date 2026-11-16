import 'bai_hoc.dart';

/// Mức độ khó của khoá học.
///
/// Dùng `enum` có trường thay cho chuỗi: trình biên dịch bắt lỗi gõ sai,
/// và `switch` trên enum thì Dart kiểm tra đủ nhánh giúp.
enum MucDo {
  coBan('Cơ bản'),
  trungCap('Trung cấp'),
  nangCao('Nâng cao');

  final String nhan;
  const MucDo(this.nhan);

  /// Đọc từ chuỗi đã lưu trong Hive. Giá trị lạ thì lùi về `coBan` chứ
  /// không ném lỗi — dữ liệu cũ trên máy người dùng không được làm sập ứng dụng.
  static MucDo tuTen(String? ten) =>
      MucDo.values.firstWhere((e) => e.name == ten, orElse: () => MucDo.coBan);
}

/// Một khoá học.
class KhoaHoc {
  final String ma;
  final String tieuDe;
  final String giangVien;
  final String moTaNgan;
  final String moTaDai;
  final String danhMuc;
  final MucDo mucDo;

  /// Điểm đánh giá 0–5, một chữ số thập phân.
  final double diemDanhGia;
  final int soLuotDanhGia;

  /// Giá tính bằng đồng. 0 nghĩa là miễn phí.
  final int gia;

  /// Tên tệp ảnh bìa trong `assets/images/`.
  final String anhBia;

  /// Khoá học nổi bật, hiện ở đầu trang chủ (mục `FeaturedSection` của sách).
  final bool noiBat;

  final List<BaiHoc> baiHoc;

  const KhoaHoc({
    required this.ma,
    required this.tieuDe,
    required this.giangVien,
    required this.moTaNgan,
    required this.moTaDai,
    required this.danhMuc,
    required this.mucDo,
    required this.diemDanhGia,
    required this.soLuotDanhGia,
    required this.gia,
    required this.anhBia,
    required this.baiHoc,
    this.noiBat = false,
  });

  bool get mienPhi => gia == 0;

  int get soBaiHoc => baiHoc.length;

  /// Tổng thời lượng, tính bằng giây.
  int get tongThoiLuongGiay =>
      baiHoc.fold(0, (tong, b) => tong + b.thoiLuongGiay);

  /// Tìm một bài học theo mã. Trả về null nếu không có — người dùng có thể
  /// dán một URL cũ hoặc sai, và ứng dụng phải xử lý được việc đó.
  BaiHoc? timBaiHoc(String maBai) {
    for (final b in baiHoc) {
      if (b.ma == maBai) return b;
    }
    return null;
  }

  /// Vị trí của bài học trong danh sách, -1 nếu không có.
  int viTriBaiHoc(String maBai) => baiHoc.indexWhere((b) => b.ma == maBai);

  Map<String, dynamic> sangMap() => {
        'ma': ma,
        'tieuDe': tieuDe,
        'giangVien': giangVien,
        'moTaNgan': moTaNgan,
        'moTaDai': moTaDai,
        'danhMuc': danhMuc,
        'mucDo': mucDo.name,
        'diemDanhGia': diemDanhGia,
        'soLuotDanhGia': soLuotDanhGia,
        'gia': gia,
        'anhBia': anhBia,
        'noiBat': noiBat,
        'baiHoc': baiHoc.map((b) => b.sangMap()).toList(),
      };

  factory KhoaHoc.tuMap(Map<dynamic, dynamic> m) => KhoaHoc(
        ma: m['ma'] as String,
        tieuDe: m['tieuDe'] as String,
        giangVien: m['giangVien'] as String,
        moTaNgan: m['moTaNgan'] as String,
        moTaDai: m['moTaDai'] as String,
        danhMuc: m['danhMuc'] as String,
        mucDo: MucDo.tuTen(m['mucDo'] as String?),
        diemDanhGia: (m['diemDanhGia'] as num).toDouble(),
        soLuotDanhGia: m['soLuotDanhGia'] as int,
        gia: m['gia'] as int,
        anhBia: m['anhBia'] as String,
        noiBat: m['noiBat'] as bool? ?? false,
        baiHoc: (m['baiHoc'] as List)
            .map((e) => BaiHoc.tuMap(e as Map))
            .toList(growable: false),
      );

  @override
  bool operator ==(Object other) => other is KhoaHoc && other.ma == ma;

  @override
  int get hashCode => ma.hashCode;

  @override
  String toString() => 'KhoaHoc($ma)';
}
