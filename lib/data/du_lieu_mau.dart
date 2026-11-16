import '../models/bai_hoc.dart';
import '../models/khoa_hoc.dart';

/// Danh mục miễn phí được tuyển chọn từ các video YouTube công khai.
class DuLieuMau {
  DuLieuMau._();

  static List<KhoaHoc> khoaHoc() => const [
    KhoaHoc(
      ma: 'flutter-nhap-mon',
      tieuDe: 'Bắt đầu với Flutter',
      giangVien: 'Flutter',
      moTaNgan: 'Tạo ứng dụng, viết widget và dựng giao diện với Flutter.',
      moTaDai: 'Bốn video tiếng Anh trong lộ trình Flutter chính thức. Bắt đầu bằng một dự án mới, chia giao diện thành widget, dựng bố cục và dùng DevTools để kiểm tra cây widget.',
      danhMuc: 'Nhập môn',
      mucDo: MucDo.coBan,
      diemDanhGia: 0,
      soLuotDanhGia: 0,
      gia: 0,
      anhBia: 'bia_widget_nhap_mon.png',
      noiBat: true,
      baiHoc: [
        BaiHoc(
          ma: 'b1',
          tieuDe: 'Tạo ứng dụng Flutter đầu tiên',
          thoiLuongGiay: 156,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b2',
          tieuDe: 'Cấu tạo của widget',
          thoiLuongGiay: 172,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b3',
          tieuDe: 'Bố cục và constraints',
          thoiLuongGiay: 289,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b4',
          tieuDe: 'Kiểm tra giao diện với DevTools',
          thoiLuongGiay: 250,
          xemThu: true,
        ),
      ],
    ),
    KhoaHoc(
      ma: 'trang-thai-flutter',
      tieuDe: 'Quản lý trạng thái trong Flutter',
      giangVien: 'Flutter',
      moTaNgan: 'Từ setState đến ChangeNotifier và ValueListenableBuilder.',
      moTaDai: 'Ba video tiếng Anh của Flutter về cập nhật giao diện và quản lý trạng thái. Thực hành với bộ đếm, mô hình có thể phát thông báo và widget lắng nghe giá trị.',
      danhMuc: 'Kiến trúc',
      mucDo: MucDo.trungCap,
      diemDanhGia: 0,
      soLuotDanhGia: 0,
      gia: 0,
      anhBia: 'bia_kien_truc_mvvm.png',
      noiBat: true,
      baiHoc: [
        BaiHoc(
          ma: 'b1',
          tieuDe: 'StatefulWidget và setState',
          thoiLuongGiay: 214,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b2',
          tieuDe: 'Phát thông báo bằng ChangeNotifier',
          thoiLuongGiay: 107,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b3',
          tieuDe: 'Dựng lại giao diện với ValueListenableBuilder',
          thoiLuongGiay: 117,
          xemThu: true,
        ),
      ],
    ),
    KhoaHoc(
      ma: 'dieu-huong-url',
      tieuDe: 'Điều hướng theo URL với go_router',
      giangVien: 'Flutter và cộng đồng',
      moTaNgan: 'Khai báo tuyến, truyền tham số và giữ thanh điều hướng với ShellRoute.',
      moTaDai: 'Ba video tiếng Anh từ kênh Flutter, Prof. Dr. Ute Trapp và Mehmet Artun. Bắt đầu với go_router, rồi xem ví dụ về URL, tham số và điều hướng lồng nhau.',
      danhMuc: 'Web',
      mucDo: MucDo.trungCap,
      diemDanhGia: 0,
      soLuotDanhGia: 0,
      gia: 0,
      anhBia: 'bia_dieu_huong_url.png',
      noiBat: true,
      baiHoc: [
        BaiHoc(
          ma: 'b1',
          tieuDe: 'Navigator 1.0, 2.0 và vì sao có go_router',
          thoiLuongGiay: 108,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b2',
          tieuDe: 'GoRoute, tham số đường dẫn và tham số truy vấn',
          thoiLuongGiay: 533,
          xemThu: true,
        ),
        BaiHoc(
          ma: 'b3',
          tieuDe: 'ShellRoute: khung chung cho nhiều trang',
          thoiLuongGiay: 1804,
          xemThu: true,
        ),
      ],
    ),
  ];
}
