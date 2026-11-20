/// Mọi địa chỉ URL của ứng dụng, gom về một chỗ.
///
/// Trên web, URL là một phần của giao diện: người dùng gửi link cho nhau,
/// bấm nút Back, mở tab mới, lưu bookmark. Rải chuỗi `'/khoa-hoc/'` khắp các
/// màn hình là cách chắc chắn nhất để một hôm nào đó có hai đường dẫn lệch
/// nhau một dấu gạch chéo.
///
/// Tệp này **không import Flutter cũng không import go_router**, nên toàn bộ
/// hàm ở đây kiểm thử được bằng `flutter test` trong vài mili giây.
library;

import '../models/bo_loc.dart';

class DuongDan {
  DuongDan._();

  static const String trangChu = '/';
  static const String danhSach = '/khoa-hoc';
  static const String cuaToi = '/cua-toi';
  static const String hoSo = '/ho-so';
  static const String dangNhap = '/dang-nhap';
  static const String thongKe = '/thong-ke';
  static const String bangXepHang = '/bang-xep-hang';
  static const String viCoin = '/vi-coin';
  static const String napCoin = '/vi-coin/nap';
  static const String lichSuGiaoDich = '/vi-coin/lich-su';
  static const String nangCapPro = '/nang-cap-pro';

  /// Đoạn con trong cấu hình go_router. Không có dấu `/` đầu vì là route con.
  static const String doanMaKhoaHoc = ':ma';
  static const String doanBaiHoc = 'bai/:maBai';
  static const String doanLuyenTap = 'luyen-tap';

  /// Tên tham số đường dẫn. Dùng hằng số để không gõ lệch giữa nơi khai báo
  /// route và nơi đọc `state.pathParameters[...]`.
  static const String thamSoMa = 'ma';
  static const String thamSoMaBai = 'maBai';

  /// Tham số truy vấn ghi lại trang người dùng định vào trước khi bị chặn.
  static const String thamSoTiep = 'tiep';

  /// `/khoa-hoc/dieu-huong-url`
  static String chiTiet(String maKhoaHoc) => '$danhSach/$maKhoaHoc';

  /// `/khoa-hoc/dieu-huong-url/bai/b3`
  static String baiHoc(String maKhoaHoc, String maBai) =>
      '${chiTiet(maKhoaHoc)}/bai/$maBai';

  static String luyenTap(String maKhoaHoc) =>
      '${chiTiet(maKhoaHoc)}/$doanLuyenTap';

  /// `/khoa-hoc?q=web&sap=danh-gia`
  ///
  /// Giá trị được mã hoá phần trăm, nếu không thì từ khoá có dấu cách hay
  /// tiếng Việt sẽ tạo ra URL hỏng.
  static String danhSachVoiLoc(BoLoc loc) => themThamSo(danhSach, loc.sangThamSo());

  /// `/dang-nhap?tiep=%2Fcua-toi`
  static String dangNhapRoiVe(String diaChiDinhVao) =>
      themThamSo(dangNhap, {thamSoTiep: diaChiDinhVao});

  /// Ghép chuỗi truy vấn vào một đường dẫn.
  ///
  /// Bảng rỗng thì trả về đường dẫn trơn, không có dấu `?` thừa — `/khoa-hoc`
  /// và `/khoa-hoc?` là hai chuỗi khác nhau, và chuỗi thứ hai trông như lỗi.
  static String themThamSo(String duongDan, Map<String, String> thamSo) {
    if (thamSo.isEmpty) return duongDan;
    final phan = thamSo.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$duongDan?$phan';
  }

  /// Những trang chỉ xem được khi đã đăng nhập.
  ///
  /// So khớp cả đường dẫn con: `/ho-so/doi-mat-khau` cũng phải được bảo vệ.
  /// Dùng `==` hoặc `startsWith('$goc/')` chứ không dùng `startsWith(goc)`
  /// trơn, nếu không thì `/ho-so-cong-khai` cũng bị chặn oan.
  static const List<String> canDangNhap = [
    cuaToi,
    hoSo,
    viCoin,
    napCoin,
    lichSuGiaoDich,
    nangCapPro,
  ];

  /// Bốn mục của thanh điều hướng, theo đúng thứ tự hiển thị.
  static const List<String> tabChinh = [trangChu, danhSach, cuaToi, hoSo];

  /// Mục nào đang được chọn, ứng với đường dẫn hiện tại.
  ///
  /// Trả về -1 khi đang ở một trang không nằm trong thanh điều hướng (trang
  /// đăng nhập, trang 404) — lúc đó không sáng mục nào cả.
  ///
  /// Chú ý thứ tự duyệt: `/` là tiền tố của **mọi** đường dẫn nên phải xét
  /// cuối cùng, nếu không thì trang nào cũng ra "Trang chủ". Đây là lỗi kinh
  /// điển khi tự viết phần chọn tab.
  static int chiSoTab(String duongDan) {
    for (var i = 0; i < tabChinh.length; i++) {
      final goc = tabChinh[i];
      if (goc == trangChu) continue;
      if (duongDan == goc || duongDan.startsWith('$goc/')) return i;
    }
    return duongDan == trangChu ? tabChinh.indexOf(trangChu) : -1;
  }

  static bool phaiDangNhap(String duongDan) {
    for (final goc in canDangNhap) {
      if (duongDan == goc || duongDan.startsWith('$goc/')) return true;
    }
    return false;
  }
}
