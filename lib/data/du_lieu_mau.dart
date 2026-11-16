import '../models/bai_hoc.dart';
import '../models/khoa_hoc.dart';

/// Dữ liệu khởi tạo, nạp vào Hive ở lần chạy đầu tiên.
///
/// Dự án không có máy chủ nên đây đóng vai trò "cơ sở dữ liệu gốc". Khi thay
/// bằng Firebase hay Appwrite, chỉ cần một lớp `KhoKhoaHoc` khác — tệp này
/// biến mất mà không ảnh hưởng đến bất cứ màn hình nào.
class DuLieuMau {
  DuLieuMau._();

  /// Danh sách danh mục, theo thứ tự hiện trên thanh lọc.
  static const List<String> danhMuc = [
    'Nhập môn',
    'Giao diện',
    'Dữ liệu',
    'Kiến trúc',
    'Web',
    'Nâng cao',
  ];

  static List<BaiHoc> _bai(List<(String, String, int)> ds) => [
        for (var i = 0; i < ds.length; i++)
          BaiHoc(
            ma: ds[i].$1,
            tieuDe: ds[i].$2,
            thoiLuongGiay: ds[i].$3,
            // Bài đầu tiên của mọi khoá học đều xem thử được.
            xemThu: i == 0,
          ),
      ];

  static List<KhoaHoc> khoaHoc() => [
        KhoaHoc(
          ma: 'dart-co-ban',
          tieuDe: 'Dart từ số không',
          giangVien: 'Võ Thái Anh',
          moTaNgan:
              'Cú pháp, kiểu dữ liệu, null safety và lập trình hướng đối tượng.',
          moTaDai:
              'Khoá học mở đầu cho người chưa từng viết Dart. Bắt đầu từ biến '
              'và hàm, đi qua null safety — thứ khiến người quen Java hay '
              'JavaScript bỡ ngỡ nhất — rồi tới lớp, kế thừa, mixin và '
              'generic. Mỗi bài đều có một đoạn mã chạy được ngay trên '
              'DartPad, không cần cài đặt gì.',
          danhMuc: 'Nhập môn',
          mucDo: MucDo.coBan,
          diemDanhGia: 4.8,
          soLuotDanhGia: 2140,
          gia: 0,
          anhBia: 'bia_dart_co_ban.png',
          noiBat: true,
          baiHoc: _bai(const [
            ('b1', 'Cài đặt SDK và chạy dòng lệnh đầu tiên', 720),
            ('b2', 'Biến, kiểu và suy luận kiểu', 960),
            ('b3', 'Null safety: dấu ? và dấu !', 1380),
            ('b4', 'Hàm, tham số tuỳ chọn và tham số tên', 840),
            ('b5', 'Lớp, hàm dựng và hàm dựng factory', 1500),
            ('b6', 'Mixin, generic và enum có trường', 1260),
          ]),
        ),
        KhoaHoc(
          ma: 'widget-nhap-mon',
          tieuDe: 'Widget: viên gạch của Flutter',
          giangVien: 'Võ Thái Anh',
          moTaNgan:
              'Cây widget, StatelessWidget, StatefulWidget và vòng đời.',
          moTaDai:
              'Mọi thứ trong Flutter đều là widget — câu nói quen thuộc này '
              'chỉ hữu ích khi hiểu ba cây song song: widget, element và '
              'render object. Khoá học giải thích vì sao gọi setState lại '
              'không dựng lại toàn bộ giao diện, và vì sao đặt một widget '
              'const đúng chỗ lại tiết kiệm nhiều đến thế.',
          danhMuc: 'Nhập môn',
          mucDo: MucDo.coBan,
          diemDanhGia: 4.7,
          soLuotDanhGia: 1890,
          gia: 0,
          anhBia: 'bia_widget_nhap_mon.png',
          noiBat: true,
          baiHoc: _bai(const [
            ('b1', 'Cây widget và hàm build', 900),
            ('b2', 'StatelessWidget: khi nào là đủ', 660),
            ('b3', 'StatefulWidget và setState', 1140),
            ('b4', 'Vòng đời: initState, didUpdateWidget, dispose', 1320),
            ('b5', 'const, Key và chuyện dựng lại thừa', 1080),
          ]),
        ),
        KhoaHoc(
          ma: 'bo-cuc-thich-ung',
          tieuDe: 'Bố cục co giãn và thích ứng',
          giangVien: 'Võ Thái Anh',
          moTaNgan:
              'Row, Column, Flex, LayoutBuilder và ba khổ màn hình.',
          moTaDai:
              'Một giao diện đẹp trên điện thoại thường vỡ trên màn hình '
              '27 inch. Khoá học phân biệt rõ responsive (co giãn theo bề '
              'rộng) và adaptive (đổi hẳn cách bố trí), rồi dựng một bộ '
              'khung ba khổ dùng lại được cho mọi dự án web.',
          danhMuc: 'Giao diện',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.9,
          soLuotDanhGia: 1470,
          gia: 490000,
          anhBia: 'bia_bo_cuc_thich_ung.png',
          noiBat: true,
          baiHoc: _bai(const [
            ('b1', 'Ràng buộc đi xuống, kích thước đi lên', 1200),
            ('b2', 'Row, Column, Expanded và Flexible', 1080),
            ('b3', 'LayoutBuilder khác MediaQuery ở chỗ nào', 960),
            ('b4', 'Điểm ngắt và bộ khung ba khổ', 1440),
            ('b5', 'NavigationBar, NavigationRail, NavigationDrawer', 1260),
            ('b6', 'Lưới thẻ tự đổi số cột', 900),
          ]),
        ),
        KhoaHoc(
          ma: 'hieu-ung-hoat-anh',
          tieuDe: 'Hoạt ảnh và chuyển cảnh',
          giangVien: 'Nguyễn Minh Khôi',
          moTaNgan:
              'AnimationController, Tween, Hero và hoạt ảnh ngầm.',
          moTaDai:
              'Hoạt ảnh không phải để loè mắt: nó cho người dùng biết cái gì '
              'vừa biến đi đâu. Khoá học đi từ AnimatedContainer đơn giản '
              'đến AnimationController điều khiển tay, kèm phần đo hiệu năng '
              'để hoạt ảnh không làm rớt khung hình trên web.',
          danhMuc: 'Giao diện',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.5,
          soLuotDanhGia: 860,
          gia: 390000,
          anhBia: 'bia_hieu_ung_hoat_anh.png',
          baiHoc: _bai(const [
            ('b1', 'Hoạt ảnh ngầm: AnimatedContainer và bạn bè', 840),
            ('b2', 'AnimationController và Ticker', 1260),
            ('b3', 'Tween, Curve và CurvedAnimation', 1020),
            ('b4', 'Hero giữa hai trang', 900),
            ('b5', 'Đo khung hình bằng DevTools', 1140),
          ]),
        ),
        KhoaHoc(
          ma: 'luu-tru-hive',
          tieuDe: 'Lưu trữ cục bộ với Hive CE',
          giangVien: 'Trần Thu Hà',
          moTaNgan:
              'Hộp dữ liệu, bộ chuyển đổi kiểu và di trú lược đồ.',
          moTaDai:
              'Hive là cơ sở dữ liệu khoá–giá trị viết thuần bằng Dart, chạy '
              'được cả trên web nhờ IndexedDB. Khoá học dựng một tầng kho dữ '
              'liệu đúng chuẩn: giao diện trừu tượng ở trên, Hive ở dưới, để '
              'sau này thay bằng máy chủ mà không sửa màn hình nào.',
          danhMuc: 'Dữ liệu',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.6,
          soLuotDanhGia: 1130,
          gia: 490000,
          anhBia: 'bia_luu_tru_hive.png',
          baiHoc: _bai(const [
            ('b1', 'Hộp, khoá và giá trị', 780),
            ('b2', 'TypeAdapter: máy sinh ra cái gì', 1500),
            ('b3', 'Số hiệu trường và chuyện nâng cấp lược đồ', 1320),
            ('b4', 'Hive trên web chạy trên IndexedDB', 960),
            ('b5', 'Tầng kho dữ liệu và kiểm thử bằng bản giả lập', 1380),
          ]),
        ),
        KhoaHoc(
          ma: 'goi-api-json',
          tieuDe: 'Gọi API và xử lý JSON',
          giangVien: 'Trần Thu Hà',
          moTaNgan: 'http, Future, async/await, phân rã JSON an toàn.',
          moTaDai:
              'Phần lớn lỗi khi gọi mạng không nằm ở lúc thành công mà nằm ở '
              'lúc thất bại. Khoá học dựng một lớp kết quả kiểu sealed để '
              'trình biên dịch bắt buộc xử lý cả nhánh lỗi, kèm phần chống '
              'CORS khi chạy trên trình duyệt.',
          danhMuc: 'Dữ liệu',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.4,
          soLuotDanhGia: 1520,
          gia: 390000,
          anhBia: 'bia_goi_api_json.png',
          baiHoc: _bai(const [
            ('b1', 'Future, async và await', 900),
            ('b2', 'Gói http và mã trạng thái', 1080),
            ('b3', 'Phân rã JSON không ném lỗi', 1260),
            ('b4', 'Lớp kết quả sealed: thành công hay thất bại', 1140),
            ('b5', 'CORS: vì sao chỉ web mới gặp', 840),
          ]),
        ),
        KhoaHoc(
          ma: 'kien-truc-mvvm',
          tieuDe: 'Kiến trúc MVVM cho ứng dụng Flutter',
          giangVien: 'Võ Thái Anh',
          moTaNgan: 'Model, View, ViewModel và luật phụ thuộc một chiều.',
          moTaDai:
              'MVVM không phải là một thư viện mà là một thoả thuận về chỗ '
              'đặt mã. Khoá học chỉ ra ranh giới cụ thể: View không biết Hive '
              'tồn tại, ViewModel không biết widget nào đang hiển thị, Model '
              'không biết gì ngoài chính nó. Kèm phần tái cấu trúc một màn '
              'hình 600 dòng thành ba tệp gọn.',
          danhMuc: 'Kiến trúc',
          mucDo: MucDo.nangCao,
          diemDanhGia: 4.9,
          soLuotDanhGia: 980,
          gia: 690000,
          anhBia: 'bia_kien_truc_mvvm.png',
          noiBat: true,
          baiHoc: _bai(const [
            ('b1', 'Ba lớp và một chiều phụ thuộc', 1020),
            ('b2', 'ViewModel không được import Flutter', 1200),
            ('b3', 'Tầng kho dữ liệu và bản giả lập', 1320),
            ('b4', 'Tách logic thuần để kiểm thử', 1440),
            ('b5', 'Tái cấu trúc một màn hình phình to', 1560),
          ]),
        ),
        KhoaHoc(
          ma: 'riverpod-3',
          tieuDe: 'Quản lý trạng thái với Riverpod 3',
          giangVien: 'Nguyễn Minh Khôi',
          moTaNgan: 'Provider, Notifier, AsyncValue và ref.watch.',
          moTaDai:
              'Riverpod 3 bỏ StateNotifier khỏi API chính và gộp mọi thứ về '
              'Notifier. Khoá học đi thẳng vào bản mới: cách khai báo '
              'provider không cần sinh mã, cách dùng AsyncValue để giao diện '
              'luôn có đủ ba trạng thái đang tải / lỗi / có dữ liệu, và cách '
              'ghi đè provider trong kiểm thử.',
          danhMuc: 'Kiến trúc',
          mucDo: MucDo.nangCao,
          diemDanhGia: 4.7,
          soLuotDanhGia: 1240,
          gia: 590000,
          anhBia: 'bia_riverpod_3.png',
          baiHoc: _bai(const [
            ('b1', 'Provider là gì, khác Provider cũ ra sao', 960),
            ('b2', 'Notifier và NotifierProvider không cần codegen', 1380),
            ('b3', 'AsyncNotifier và ba trạng thái của AsyncValue', 1500),
            ('b4', 'ref.watch, ref.read, ref.listen dùng lúc nào', 1140),
            ('b5', 'Ghi đè provider để kiểm thử', 1020),
          ]),
        ),
        KhoaHoc(
          ma: 'flutter-web-nen-tang',
          tieuDe: 'Flutter trên Web: bên dưới lớp vỏ',
          giangVien: 'Võ Thái Anh',
          moTaNgan:
              'Trình kết xuất, WebAssembly, tải lần đầu và SEO.',
          moTaDai:
              'Vì sao ứng dụng Flutter web tải lần đầu chậm, và làm gì để đỡ '
              'chậm. Khoá học giải thích Flutter vẽ giao diện bằng canvas '
              'chứ không bằng thẻ HTML, hệ quả của việc đó với SEO và trình '
              'đọc màn hình, cùng lựa chọn biên dịch sang WebAssembly.',
          danhMuc: 'Web',
          mucDo: MucDo.nangCao,
          diemDanhGia: 4.8,
          soLuotDanhGia: 760,
          gia: 590000,
          anhBia: 'bia_flutter_web_nen_tang.png',
          noiBat: true,
          baiHoc: _bai(const [
            ('b1', 'Flutter web vẽ bằng gì', 1080),
            ('b2', 'Cờ --web-renderer đã biến mất', 900),
            ('b3', 'Biên dịch sang WebAssembly bằng --wasm', 1260),
            ('b4', 'Rút ngắn thời gian tải lần đầu', 1320),
            ('b5', 'SEO và khả năng tiếp cận', 1140),
          ]),
        ),
        KhoaHoc(
          ma: 'dieu-huong-url',
          tieuDe: 'Điều hướng theo URL với go_router',
          giangVien: 'Võ Thái Anh',
          moTaNgan:
              'URL thật, tham số đường dẫn, ShellRoute và chặn truy cập.',
          moTaDai:
              'Trên web, URL là một phần của giao diện: người dùng gửi link, '
              'bấm nút Back, mở tab mới. Khoá học thay toàn bộ Navigator 2.0 '
              'tự viết trong sách bằng go_router, và chỉ rõ chỗ nào trên màn '
              'hình phải phản ánh vào thanh địa chỉ.',
          danhMuc: 'Web',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.9,
          soLuotDanhGia: 1610,
          gia: 490000,
          anhBia: 'bia_dieu_huong_url.png',
          baiHoc: _bai(const [
            ('b1', 'Navigator 1.0, 2.0 và vì sao có go_router', 1020),
            ('b2', 'GoRoute, tham số đường dẫn và tham số truy vấn', 1260),
            ('b3', 'ShellRoute: khung chung cho nhiều trang', 1140),
            ('b4', 'redirect: chặn trang cần đăng nhập', 1200),
            ('b5', 'Trang 404 và đường dẫn hỏng', 780),
          ]),
        ),
        KhoaHoc(
          ma: 'kiem-thu-flutter',
          tieuDe: 'Kiểm thử ứng dụng Flutter',
          giangVien: 'Trần Thu Hà',
          moTaNgan: 'Kiểm thử đơn vị, kiểm thử widget và bản giả lập.',
          moTaDai:
              'Bộ kiểm thử tốt không phủ 100% mà phủ đúng chỗ dễ sai. Khoá '
              'học chỉ cách tách logic thuần ra khỏi widget để kiểm thử chạy '
              'trong mili giây, rồi mới dùng WidgetTester cho phần giao diện '
              'thật sự cần.',
          danhMuc: 'Nâng cao',
          mucDo: MucDo.trungCap,
          diemDanhGia: 4.5,
          soLuotDanhGia: 640,
          gia: 0,
          anhBia: 'bia_kiem_thu_flutter.png',
          baiHoc: _bai(const [
            ('b1', 'test, group và expect', 720),
            ('b2', 'Tách logic thuần: bài học lớn nhất', 1320),
            ('b3', 'Bản giả lập viết tay, không cần thư viện', 1080),
            ('b4', 'WidgetTester và pumpWidget', 1200),
            ('b5', 'Chạy kiểm thử trong CI', 900),
          ]),
        ),
        KhoaHoc(
          ma: 'trien-khai-ci-cd',
          tieuDe: 'Đóng gói, triển khai và CI/CD',
          giangVien: 'Nguyễn Minh Khôi',
          moTaNgan:
              'flutter build web, base href, GitHub Actions, Firebase Hosting.',
          moTaDai:
              'Từ mã nguồn tới đường link người khác mở được. Khoá học đi qua '
              'lệnh dựng bản phát hành, bẫy base href khi đặt trong thư mục '
              'con, cấu hình để tải lại trang con không ra 404, và một quy '
              'trình GitHub Actions tự dựng rồi tự đưa lên mỗi lần đẩy mã.',
          danhMuc: 'Nâng cao',
          mucDo: MucDo.nangCao,
          diemDanhGia: 4.7,
          soLuotDanhGia: 890,
          gia: 590000,
          anhBia: 'bia_trien_khai_ci_cd.png',
          baiHoc: _bai(const [
            ('b1', 'flutter build web và thư mục build/web', 840),
            ('b2', 'base href khi đặt trong thư mục con', 960),
            ('b3', 'Cấu hình rewrite để không ra 404', 1020),
            ('b4', 'Đưa lên Firebase Hosting và GitHub Pages', 1260),
            ('b5', 'GitHub Actions: dựng và triển khai tự động', 1440),
          ]),
        ),
      ];
}
