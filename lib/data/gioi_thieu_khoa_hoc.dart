import '../models/bai_hoc.dart';
import '../models/khoa_hoc.dart';

class GioiThieuKhoaHoc {
  const GioiThieuKhoaHoc({
    required this.mucTieu,
    required this.yeuCau,
    required this.chuong,
  });

  final List<String> mucTieu;
  final List<String> yeuCau;
  final Map<String, List<String>> chuong;

  static const _danhMuc = {
    'flutter-nhap-mon': GioiThieuKhoaHoc(
      mucTieu: [
        'Tạo và chạy ứng dụng Flutter đầu tiên, sau đó dùng hot reload để xem thay đổi.',
        'Tách giao diện thành widget và sắp xếp chúng bằng Row, Column và Expanded.',
        'Dùng Flutter Inspector để đọc cây widget và tìm lỗi bố cục.',
      ],
      yeuCau: [
        'Biết biến và hàm cơ bản trong Dart.',
        'Cài Flutter SDK và chuẩn bị Chrome hoặc thiết bị để chạy thử.',
      ],
      chuong: {
        'Tạo ứng dụng và làm quen với widget': ['b1', 'b2'],
        'Dựng và kiểm tra bố cục': ['b3', 'b4'],
      },
    ),
    'trang-thai-flutter': GioiThieuKhoaHoc(
      mucTieu: [
        'Dùng StatefulWidget và setState để cập nhật một màn hình.',
        'Gom dữ liệu thay đổi vào ChangeNotifier và thông báo cho nơi đang lắng nghe.',
        'Dựng lại một phần giao diện bằng ValueListenableBuilder.',
      ],
      yeuCau: ['Biết viết widget Flutter và dùng lớp trong Dart.'],
      chuong: {
        'Trạng thái trong widget': ['b1'],
        'Tách và theo dõi trạng thái': ['b2', 'b3'],
      },
    ),
    'dieu-huong-url': GioiThieuKhoaHoc(
      mucTieu: [
        'Khai báo đường dẫn và màn hình tương ứng bằng go_router.',
        'Đọc tham số đường dẫn và truy vấn để khôi phục bộ lọc từ URL.',
        'Dùng ShellRoute để giữ khung điều hướng khi chuyển trang.',
      ],
      yeuCau: [
        'Đã tạo ứng dụng Flutter và biết cách chuyển giữa hai màn hình.',
        'Có Chrome để thử mở trực tiếp URL và tải lại trang.',
      ],
      chuong: {
        'Khai báo tuyến và xử lý URL': ['b1', 'b2'],
        'Điều hướng lồng nhau': ['b3'],
      },
    ),
    'python-co-ban': GioiThieuKhoaHoc(
      mucTieu: [
        'Lưu số, chuỗi và giá trị đúng/sai trong biến.',
        'Dùng if, elif và else để chọn nhánh theo điều kiện.',
        'Viết hàm nhận tham số và trả về kết quả bằng return.',
      ],
      yeuCau: [
        'Bạn có thể bắt đầu khi chưa từng lập trình.',
        'Cài Python 3 hoặc dùng môi trường Python trực tuyến để chạy ví dụ.',
      ],
      chuong: {
        'Dữ liệu và câu lệnh điều kiện': ['b1', 'b2'],
        'Viết và gọi hàm': ['b3'],
      },
    ),
    'java-co-ban': GioiThieuKhoaHoc(
      mucTieu: [
        'Khai báo biến với int, double, boolean và String.',
        'Viết câu lệnh if, else if và else để xử lý các trường hợp khác nhau.',
        'Tách phép tính thành phương thức có tham số và kiểu trả về.',
      ],
      yeuCau: [
        'Bạn có thể bắt đầu khi chưa từng lập trình.',
        'Cài JDK hoặc dùng môi trường Java trực tuyến để chạy chương trình.',
      ],
      chuong: {
        'Kiểu dữ liệu và rẽ nhánh': ['b1', 'b2'],
        'Viết và gọi phương thức': ['b3'],
      },
    ),
  };

  static GioiThieuKhoaHoc? cua(String maKhoaHoc) => _danhMuc[maKhoaHoc];

  Map<String, List<BaiHoc>> chiaChuong(KhoaHoc khoaHoc) {
    final conLai = {for (final bai in khoaHoc.baiHoc) bai.ma: bai};
    final ketQua = <String, List<BaiHoc>>{};
    for (final muc in chuong.entries) {
      final bai = [
        for (final ma in muc.value)
          ?conLai.remove(ma),
      ];
      if (bai.isNotEmpty) ketQua[muc.key] = bai;
    }
    if (conLai.isNotEmpty) ketQua['Bài học khác'] = conLai.values.toList();
    return ketQua;
  }
}
