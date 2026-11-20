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
    'dart-co-ban': GioiThieuKhoaHoc(
      mucTieu: [
        'Nắm vững cú pháp biến, kiểu dữ liệu hiện đại và Sound Null Safety trong Dart.',
        'Sử dụng lớp, abstract class, mixin để xây dựng cấu trúc OOP sạch sẽ.',
        'Làm chủ xử lý bất đồng bộ với Future, Stream và async/await.',
      ],
      yeuCau: [
        'Đã có tư duy logic lập trình cơ bản.',
        'Đã cài đặt Flutter SDK hoặc Dart SDK trên máy.',
      ],
      chuong: {
        'Cú pháp cơ bản và Hướng đối tượng': ['b1', 'b2'],
        'Bất đồng bộ và Luồng dữ liệu': ['b3'],
      },
    ),
    'flutter-animation': GioiThieuKhoaHoc(
      mucTieu: [
        'Tạo chuyển động mượt mà với AnimatedContainer và các Implicit widgets.',
        'Kiểm soát tỉ mỉ từng khung hình bằng AnimationController và CurvedAnimation.',
        'Xây dựng hiệu ứng chuyển trang ấn tượng với Hero Animation.',
      ],
      yeuCau: [
        'Đã biết cách dựng giao diện cơ bản bằng Flutter widget.',
      ],
      chuong: {
        'Chuyển động ngầm định và Điều khiển': ['b1', 'b2'],
        'Hiệu ứng chuyển cảnh trang': ['b3'],
      },
    ),
    'flutter-responsive-web': GioiThieuKhoaHoc(
      mucTieu: [
        'Thiết kế layout tự động co giãn theo kích thước màn hình bằng LayoutBuilder.',
        'Quản lý Breakpoints linh hoạt cho Mobile, Tablet, Web và Desktop.',
        'Tối ưu thao tác chuột, bàn phím và phím tắt chuyên nghiệp trên Web.',
      ],
      yeuCau: [
        'Đã biết sử dụng Scaffold, Row, Column và Flex trong Flutter.',
      ],
      chuong: {
        'Bố cục thích ứng và Breakpoints': ['b1', 'b2'],
        'Tương tác chuột và bàn phím': ['b3'],
      },
    ),
    'flutter-riverpod-3': GioiThieuKhoaHoc(
      mucTieu: [
        'Hiểu kiến trúc Riverpod 3 và vai trò của Provider, Notifier.',
        'Quản lý trạng thái bất đồng bộ an toàn với AsyncNotifier và AsyncValue.',
        'Tối ưu hiệu năng rebuild UI chính xác bằng ref.select.',
      ],
      yeuCau: [
        'Biết các hạn chế của setState và ChangeNotifier thông thường.',
      ],
      chuong: {
        'Kiến trúc Riverpod và AsyncNotifier': ['b1', 'b2'],
        'Tối ưu hiệu năng tái dựng giao diện': ['b3'],
      },
    ),
    'flutter-luu-tru-hive': GioiThieuKhoaHoc(
      mucTieu: [
        'Lưu trữ NoSQL nhị phân tốc độ cao với Hive CE trên Web và Mobile.',
        'Tự tay định nghĩa TypeAdapter tùy chỉnh không cần build_runner.',
        'Xây dựng chiến lược đồng bộ dữ liệu Offline-first với REST API.',
      ],
      yeuCau: [
        'Hiểu cách làm việc với JSON và mô hình dữ liệu trong Dart.',
      ],
      chuong: {
        'Khởi tạo Box và TypeAdapter nhị phân': ['b1', 'b2'],
        'Kiến trúc Offline-first': ['b3'],
      },
    ),
    'flutter-web3-blockchain': GioiThieuKhoaHoc(
      mucTieu: [
        'Kết nối dApp Flutter với ví Web3 (MetaMask) thông qua JS Interop.',
        'Ký và gửi giao dịch On-chain EIP-712 tương tác với Smart Contract Sepolia.',
        'Xác thực giao dịch an toàn bằng JSON-RPC trên backend Node.js.',
      ],
      yeuCau: [
        'Đã cài đặt ví MetaMask trên trình duyệt Chrome.',
        'Hiểu khái niệm cơ bản về Blockchain, Gas Fee và Ethereum Testnet.',
      ],
      chuong: {
        'Kết nối ví và Tương tác Smart Contract': ['b1', 'b2'],
        'Xác thực giao dịch On-chain': ['b3'],
      },
    ),
    'flutter-clean-architecture': GioiThieuKhoaHoc(
      mucTieu: [
        'Tổ chức dự án Flutter theo 3 phân tầng Clean Architecture độc lập.',
        'Áp dụng Repository Pattern và Dependency Inversion bảo vệ mã nguồn.',
        'Chia nhỏ ứng dụng lớn thành hệ sinh thái Micro-packages độc lập.',
      ],
      yeuCau: [
        'Có kinh nghiệm làm dự án Flutter thực tế trên 6 tháng.',
        'Hiểu các nguyên lý thiết kế SOLID.',
      ],
      chuong: {
        'Phân tầng kiến trúc và Repository Pattern': ['b1', 'b2'],
        'Kiến trúc Micro-packages': ['b3'],
      },
    ),
    'flutter-ai-agent-pro': GioiThieuKhoaHoc(
      mucTieu: [
        'Tích hợp Gemini Flash/Pro với Streaming phản hồi token thời gian thực.',
        'Xây dựng Tool/Function Calling cho phép LLM gọi hàm trong ứng dụng.',
        'Quản lý Sliding Window Context và tối ưu hóa ngân sách Token.',
      ],
      yeuCau: [
        'Có API Key Gemini hoặc OpenRouter.',
        'Hiểu kiến trúc gọi API bất đồng bộ và Stream trong Dart.',
      ],
      chuong: {
        'Kết nối LLM và Function Calling': ['b1', 'b2'],
        'Quản lý Context và Bộ nhớ Agent': ['b3'],
      },
    ),
    'flutter-security-pro': GioiThieuKhoaHoc(
      mucTieu: [
        'Bảo mật mã hóa dữ liệu với AES-256-GCM và Flutter Secure Storage.',
        'Triển khai SSL Pinning chống nghe lén dữ liệu đường truyền HTTPS.',
        'Phát hiện thiết bị can thiệp Root, Jailbreak và chống dịch ngược.',
      ],
      yeuCau: [
        'Hiểu kiến trúc bảo mật mạng và mật mã học cơ bản.',
      ],
      chuong: {
        'Mã hóa dữ liệu và SSL Pinning': ['b1', 'b2'],
        'Phát hiện Root/Jailbreak': ['b3'],
      },
    ),
    'flutter-cicd-devops': GioiThieuKhoaHoc(
      mucTieu: [
        'Thiết lập pipeline tự động hóa CI/CD với GitHub Actions.',
        'Đóng gói Flutter Web đa tầng với Docker và Nginx Alpine siêu nhẹ.',
        'Triển khai tự động lên Firebase Hosting, Google Cloud Run.',
      ],
      yeuCau: [
        'Đã có tài khoản GitHub và cài Docker Desktop cơ bản.',
      ],
      chuong: {
        'Tự động hóa kiểm thử và Dockerize': ['b1', 'b2'],
        'Triển khai Cloud Production': ['b3'],
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
