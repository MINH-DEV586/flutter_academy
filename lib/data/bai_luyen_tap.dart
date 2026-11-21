class CauHoiQuiz {
  const CauHoiQuiz(this.cauHoi, this.luaChon, this.dapAn, this.giaiThich);

  final String cauHoi;
  final List<String> luaChon;
  final int dapAn;
  final String giaiThich;
}

class BaiTapCode {
  const BaiTapCode({
    required this.tieuDe,
    required this.deBai,
    required this.maKhoiDau,
    required this.ketQua,
    required this.goiY,
    required this.loiGiai,
  });

  final String tieuDe;
  final String deBai;
  final String maKhoiDau;
  final String ketQua;
  final String goiY;
  final String loiGiai;
}

class BaiLuyenTap {
  const BaiLuyenTap(this.quiz, this.baiTap);

  final List<CauHoiQuiz> quiz;
  final BaiTapCode baiTap;

  static BaiLuyenTap? cua(String maKhoaHoc) => _danhMuc[maKhoaHoc];

  int chamDiem(Map<int, int> luaChon) {
    var diem = 0;
    for (var i = 0; i < quiz.length; i++) {
      if (luaChon[i] == quiz[i].dapAn) diem++;
    }
    return diem;
  }
}

const _danhMuc = {
  'python-co-ban': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Sau lệnh diem = 8.5, type(diem) là gì?',
        ['int', 'float', 'str'],
        1,
        '8.5 là một literal số thực nên Python tạo giá trị kiểu float.',
      ),
      CauHoiQuiz(
        'Nếu cả điều kiện if và elif đều đúng, nhánh nào được thực thi?',
        ['Chỉ nhánh if', 'Cả hai nhánh', 'Chỉ nhánh elif'],
        0,
        'Trong cùng một chuỗi if/elif/else, chỉ nhánh đúng đầu tiên chạy.',
      ),
      CauHoiQuiz(
        'Lệnh nào trả kết quả 12 để nơi gọi hàm có thể lưu vào biến?',
        ['print(12)', 'pass', 'return 12'],
        2,
        'return gửi giá trị về nơi gọi. print chỉ in ra màn hình.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Xếp loại điểm bằng hàm Python',
      deBai:
          'Viết hàm xep_loai(diem). Từ 9 trở lên trả về "Xuất sắc", '
          'từ 5 đến dưới 9 trả về "Đạt", còn lại trả về "Cần ôn thêm".',
      maKhoiDau: '''def xep_loai(diem):
    # Viết phần xử lý ở đây.
    pass

print(xep_loai(9))
print(xep_loai(5))
print(xep_loai(4))''',
      ketQua: 'Với 9, 5 và 4, chương trình lần lượt in Xuất sắc, Đạt và Cần ôn thêm.',
      goiY: 'Kiểm tra diem >= 9 trước. Nếu kiểm tra diem >= 5 trước, điểm 9 sẽ đi vào nhánh Đạt.',
      loiGiai: '''def xep_loai(diem):
    if diem >= 9:
        return "Xuất sắc"
    if diem >= 5:
        return "Đạt"
    return "Cần ôn thêm"

print(xep_loai(9))
print(xep_loai(5))
print(xep_loai(4))''',
    ),
  ),
  'java-co-ban': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Kiểu nào lưu được giá trị 8.5 với khai báo thông thường trong Java?',
        ['boolean', 'int', 'double'],
        2,
        'double lưu được số thực. Literal 8.5 mặc định mang kiểu double.',
      ),
      CauHoiQuiz(
        'Điều kiện bên trong if (...) phải cho ra kiểu dữ liệu nào?',
        ['String', 'boolean', 'int'],
        1,
        'Java yêu cầu biểu thức điều kiện có giá trị boolean.',
      ),
      CauHoiQuiz(
        'Phương thức static int tong(int a, int b) phải trả về kiểu gì?',
        ['int', 'void', 'boolean'],
        0,
        'Từ int đứng trước tên phương thức là kiểu của giá trị trả về.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Tính phí giao hàng bằng phương thức Java',
      deBai:
          'Viết phương thức static int phiGiaoHang(int tongTien). '
          'Đơn từ 200.000 đồng được miễn phí. Các đơn nhỏ hơn có phí 20.000 đồng.',
      maKhoiDau: '''class Main {
    static int phiGiaoHang(int tongTien) {
        // Tính phí dựa vào tổng tiền.
        return -1;
    }

    public static void main(String[] args) {
        System.out.println(phiGiaoHang(200000));
        System.out.println(phiGiaoHang(199999));
    }
}''',
      ketQua: 'Với 200000, kết quả là 0. Với 199999, kết quả là 20000.',
      goiY: 'Dùng >= để đơn đúng 200.000 đồng cũng được miễn phí.',
      loiGiai: '''class Main {
    static int phiGiaoHang(int tongTien) {
        if (tongTien >= 200_000) {
            return 0;
        }
        return 20_000;
    }

    public static void main(String[] args) {
        System.out.println(phiGiaoHang(200000));
        System.out.println(phiGiaoHang(199999));
    }
}''',
    ),
  ),
  'flutter-nhap-mon': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Widget nào thường đặt các widget con theo chiều ngang?',
        ['Column', 'Row', 'Expanded'],
        1,
        'Row bố trí các widget con theo chiều ngang. Column xếp theo chiều dọc.',
      ),
      CauHoiQuiz(
        'Trong một Row, Expanded dùng để làm gì?',
        [
          'Chiếm phần không gian còn lại được phân bổ',
          'Ép hàng xuống dòng',
          'Tạo khoảng trắng cố định',
        ],
        0,
        'Expanded cho widget con nhận phần chiều rộng còn lại theo hệ số flex.',
      ),
      CauHoiQuiz(
        'Công cụ nào giúp xem cây widget và kiểm tra bố cục khi ứng dụng đang chạy?',
        ['pub get', 'Hot reload', 'Flutter Inspector'],
        2,
        'Flutter Inspector trong DevTools cho bạn chọn một widget và xem cấu trúc, kích thước của nó.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Dựng hàng tiêu đề cho thẻ bài học',
      deBai:
          'Hoàn thiện hàm tieuDeBaiHoc. Hàng có icon môn học, khoảng cách 8 px và tên bài. '
          'Phần chữ nhận chiều rộng còn lại và hiện dấu ba chấm nếu quá dài.',
      maKhoiDau: '''Widget tieuDeBaiHoc(String ten) {
  return Row(
    children: [
      const Icon(Icons.school_outlined),
      // Thêm khoảng cách và tên bài.
    ],
  );
}''',
      ketQua: 'Icon luôn hiện đủ. Tên bài dùng một dòng và rút gọn khi không còn chỗ.',
      goiY: 'Dùng SizedBox(width: 8) cho khoảng cách. Bọc Text bằng Expanded.',
      loiGiai: '''Widget tieuDeBaiHoc(String ten) {
  return Row(
    children: [
      const Icon(Icons.school_outlined),
      const SizedBox(width: 8),
      Expanded(
        child: Text(ten, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}''',
    ),
  ),
  'trang-thai-flutter': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Đối tượng nào giữ dữ liệu thay đổi của một StatefulWidget?',
        ['State', 'BuildContext', 'Widget'],
        0,
        'State giữ dữ liệu có thể thay đổi. StatefulWidget giữ cấu hình bất biến.',
      ),
      CauHoiQuiz(
        'Sau khi cập nhật dữ liệu trong ChangeNotifier, gọi hàm nào để báo cho người nghe?',
        ['dispose()', 'build()', 'notifyListeners()'],
        2,
        'notifyListeners() báo cho các đối tượng đã đăng ký lắng nghe.',
      ),
      CauHoiQuiz(
        'ValueListenableBuilder đọc giá trị mới từ đâu?',
        [
          'Từ tham số child',
          'Từ ValueListenable đang được theo dõi',
          'Từ BuildContext của ứng dụng',
        ],
        1,
        'Builder nhận giá trị mới của ValueListenable. child là widget có thể tái sử dụng.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Tạo bộ đếm bài học đã hoàn thành',
      deBai:
          'Dùng ValueNotifier<int> lưu số bài đã xong. '
          'Khi người học bấm nút, tăng bộ đếm và cập nhật dòng chữ bằng ValueListenableBuilder.',
      maKhoiDau: '''Widget boDemBaiHoc(ValueNotifier<int> soBai) {
  // Tạo nội dung lắng nghe soBai và nút để tăng giá trị.
  return const SizedBox.shrink();
}''',
      ketQua: 'Với soBai.value ban đầu bằng 0, bấm nút hai lần sẽ hiển thị "Đã xong: 2".',
      goiY:
          'Truyền soBai vào valueListenable. Tăng soBai.value trong onPressed.',
      loiGiai: '''Widget boDemBaiHoc(ValueNotifier<int> soBai) {
  return Column(
    children: [
      ValueListenableBuilder<int>(
        valueListenable: soBai,
        builder: (context, giaTri, child) => Text('Đã xong: \$giaTri'),
      ),
      FilledButton(
        onPressed: () => soBai.value++,
        child: const Text('Hoàn thành một bài'),
      ),
    ],
  );
}''',
    ),
  ),
  'dieu-huong-url': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Để đọc mã trong /khoa-hoc/python khi route khai báo /khoa-hoc/:ma, dùng gì?',
        [
          'state.uri.fragment',
          'state.pathParameters',
          'state.uri.queryParameters',
        ],
        1,
        'Mã python nằm trong một đoạn của đường dẫn, ứng với tham số :ma.',
      ),
      CauHoiQuiz(
        'Với URL /khoa-hoc?q=java, thuộc tính nào cho giá trị java khi đọc khóa q?',
        ['state.pathParameters', 'state.extra', 'state.uri.queryParameters'],
        2,
        'q nằm sau dấu hỏi nên là tham số truy vấn, được đọc từ state.uri.queryParameters.',
      ),
      CauHoiQuiz(
        'ShellRoute phù hợp với tình huống nào?',
        [
          'Giữ thanh điều hướng chung khi đổi trang con',
          'Chuyển một chuỗi thành Uri',
          'Sắp xếp các tham số truy vấn',
        ],
        0,
        'ShellRoute bọc màn hình con trong một khung dùng chung do builder cung cấp.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Đưa từ khóa tìm kiếm vào URL',
      deBai:
          'Viết hàm urlTimKiem. Nếu từ khóa rỗng sau khi bỏ khoảng trắng thừa, '
          'trả về /khoa-hoc. Nếu có từ khóa, dùng Uri để thêm tham số q.',
      maKhoiDau: '''String urlTimKiem(String tuKhoa) {
  // Bỏ khoảng trắng thừa rồi tạo URL.
  return '/khoa-hoc';
}''',
      ketQua: 'Đầu vào rỗng trả về /khoa-hoc. Với "  java  ", kết quả là /khoa-hoc?q=java.',
      goiY:
          'Dùng trim(), kiểm tra isEmpty, rồi truyền queryParameters cho Uri.',
      loiGiai: '''String urlTimKiem(String tuKhoa) {
  final q = tuKhoa.trim();
  if (q.isEmpty) return '/khoa-hoc';

  return Uri(path: '/khoa-hoc', queryParameters: {'q': q}).toString();
}''',
    ),
  ),
  'dart-co-ban': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Trong Dart với Sound Null Safety, biến kiểu int có thể gán null không?',
        ['Có thể gán bất cứ lúc nào', 'Không thể gán trừ khi khai báo int?', 'Chỉ gán được khi dùng var'],
        1,
        'int không chấp nhận null; chỉ int? mới có thể chứa giá trị null.',
      ),
      CauHoiQuiz(
        'Từ khóa nào trong Dart dùng để tích hợp một mixin vào class?',
        ['extends', 'implements', 'with'],
        2,
        'Từ khóa with được sử dụng để ghép một hoặc nhiều mixin vào lớp.',
      ),
      CauHoiQuiz(
        'Hàm trả về dữ liệu liên tục theo thời gian trong Dart có kiểu trả về là gì?',
        ['Future', 'Stream', 'Iterable'],
        1,
        'Stream biểu diễn chuỗi dữ liệu bất đồng bộ phát ra liên tục theo thời gian.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Kiểm tra chuỗi an toàn null',
      deBai: 'Viết hàm dinhDangTen(String? hoTen). Nếu hoTen là null hoặc rỗng, trả về "Khách", ngược lại trả về tên viết hoa.',
      maKhoiDau: '''String dinhDangTen(String? hoTen) {
  return '';
}''',
      ketQua: 'dinhDangTen(null) -> "Khách", dinhDangTen("lan") -> "LAN"',
      goiY: 'Sử dụng toán tử null-aware hoặc kiểm tra null/isEmpty.',
      loiGiai: '''String dinhDangTen(String? hoTen) {
  if (hoTen == null || hoTen.trim().isEmpty) return 'Khách';
  return hoTen.trim().toUpperCase();
}''',
    ),
  ),
  'flutter-animation': BaiLuyenTap(
    [
      CauHoiQuiz(
        'AnimatedContainer thuộc nhóm animation nào trong Flutter?',
        ['Implicit Animations', 'Explicit Animations', 'Physics-based Animations'],
        0,
        'AnimatedContainer là widget chuyển động ngầm định (Implicit Animation), tự động nội suy.',
      ),
      CauHoiQuiz(
        'Thuộc tính nào của Hero widget bắt buộc phải giống nhau giữa hai màn hình?',
        ['child', 'tag', 'flightShuttleBuilder'],
        1,
        'tag là định danh duy nhất giúp Flutter liên kết hai phần tử Hero với nhau.',
      ),
      CauHoiQuiz(
        'Để dọn dẹp bộ nhớ của AnimationController, ta gọi hàm nào trong dispose()?',
        ['controller.stop()', 'controller.reset()', 'controller.dispose()'],
        2,
        'Phải gọi controller.dispose() trong dispose của State để tránh rò rỉ bộ nhớ (memory leak).',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Tính toán tỷ lệ hoàn thành chuyển động',
      deBai: 'Viết hàm tinhTienDo(double batDau, double ketThuc, double t). Trả về giá trị nội suy tuyến tính giữa batDau và ketThuc theo tỉ lệ t (0.0 đến 1.0).',
      maKhoiDau: '''double tinhTienDo(double batDau, double ketThuc, double t) {
  return 0.0;
}''',
      ketQua: 'tinhTienDo(10, 20, 0.5) -> 15.0',
      goiY: 'Công thức lerp: batDau + (ketThuc - batDau) * t.',
      loiGiai: '''double tinhTienDo(double batDau, double ketThuc, double t) {
  return batDau + (ketThuc - batDau) * t;
}''',
    ),
  ),
  'flutter-responsive-web': BaiLuyenTap(
    [
      CauHoiQuiz(
        'LayoutBuilder cung cấp thông tin gì qua tham số constraints?',
        ['Kích thước toàn bộ màn hình', 'Kích thước tối đa và tối thiểu của widget cha', 'Độ phân giải DPI'],
        1,
        'LayoutBuilder cung cấp BoxConstraints áp đặt từ widget cha trực tiếp.',
      ),
      CauHoiQuiz(
        'Cách nào lấy chiều rộng cửa sổ trình duyệt tối ưu trong Flutter 3.x?',
        ['MediaQuery.sizeOf(context).width', 'MediaQuery.of(context).size.width', 'window.physicalSize.width'],
        0,
        'MediaQuery.sizeOf(context) chỉ lắng nghe thay đổi kích thước, không rebuild thừa khi đổi độ sáng/inset.',
      ),
      CauHoiQuiz(
        'Widget nào bắt sự kiện di chuyển con trỏ chuột trên Web?',
        ['GestureDetector', 'MouseRegion', 'InkWell'],
        1,
        'MouseRegion chuyên dụng cho Web/Desktop để theo dõi hover, enter, exit của chuột.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Tính số cột theo độ rộng màn hình',
      deBai: 'Viết hàm tinhSoCot(double width). Nếu width >= 1200 trả về 4, >= 800 trả về 3, >= 600 trả về 2, còn lại trả về 1.',
      maKhoiDau: '''int tinhSoCot(double width) {
  return 1;
}''',
      ketQua: 'width 1024 -> 3, width 400 -> 1',
      goiY: 'Sử dụng if/else kiểm tra giảm dần từ 1200 xuống.',
      loiGiai: '''int tinhSoCot(double width) {
  if (width >= 1200) return 4;
  if (width >= 800) return 3;
  if (width >= 600) return 2;
  return 1;
}''',
    ),
  ),
  'flutter-riverpod-3': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Phương thức nào của WidgetRef dùng để đọc giá trị một lần mà không đăng ký rebuild?',
        ['ref.watch', 'ref.listen', 'ref.read'],
        2,
        'ref.read chỉ lấy giá trị hiện tại một lần, thường dùng trong callback sự kiện onTap/onPressed.',
      ),
      CauHoiQuiz(
        'Lợi ích của ref.select so với ref.watch thông thường là gì?',
        ['Tăng tốc biên dịch', 'Chỉ rebuild widget khi trường dữ liệu được chọn thay đổi', 'Tự động gọi dispose'],
        1,
        'ref.select lọc thay đổi và chỉ rebuild widget khi giá trị biểu thức con thay đổi.',
      ),
      CauHoiQuiz(
        'Để hủy cache và tải lại dữ liệu trong một FutureProvider/AsyncNotifier, ta dùng:',
        ['ref.invalidate(provider)', 'ref.refresh(provider)', 'ref.reset(provider)'],
        0,
        'ref.invalidate đánh dấu provider hết hạn và lên lịch tính toán lại khi có người nghe.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Đếm số lượng mục chưa hoàn thành',
      deBai: 'Viết hàm demMucChuaXong(List<bool> ds). Đếm và trả về số lượng giá trị false trong danh sách.',
      maKhoiDau: '''int demMucChuaXong(List<bool> ds) {
  return 0;
}''',
      ketQua: 'demMucChuaXong([true, false, true, false]) -> 2',
      goiY: 'Dùng where((x) => !x).length hoặc vòng lặp for.',
      loiGiai: '''int demMucChuaXong(List<bool> ds) {
  return ds.where((daXong) => !daXong).length;
}''',
    ),
  ),
  'flutter-luu-tru-hive': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Trên nền tảng Web, Hive CE lưu trữ dữ liệu vào đâu?',
        ['IndexedDB của trình duyệt', 'LocalStorage dạng text', 'Cookies trình duyệt'],
        0,
        'Hive CE tận dụng IndexedDB nhị phân của trình duyệt để lưu trữ tốc độ cao trên Web.',
      ),
      CauHoiQuiz(
        'Mỗi TypeAdapter tùy chỉnh của Hive bắt buộc phải có thuộc tính gì duy nhất?',
        ['typeId', 'boxName', 'adapterKey'],
        0,
        'typeId là số hiệu nguyên duy nhất xác định kiểu dữ liệu khi giải mã nhị phân.',
      ),
      CauHoiQuiz(
        'Trong chiến lược Offline-first, thao tác nào nên diễn ra trước?',
        ['Gửi request lên API', 'Ghi vào database cục bộ và cập nhật UI ngay', 'Chờ người dùng xác nhận'],
        1,
        'Ghi cục bộ trước giúp giao diện phản hồi tức thì (Optimistic UI) không cần chờ mạng.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Tạo khóa định danh cho bài học',
      deBai: 'Viết hàm taoKhoaBai(String maKhoa, String maBai). Nối hai chuỗi bằng dấu gạch chéo "/".',
      maKhoiDau: '''String taoKhoaBai(String maKhoa, String maBai) {
  return '';
}''',
      ketQua: 'taoKhoaBai("dart", "b1") -> "dart/b1"',
      goiY: 'Dùng chuỗi nội suy "\$maKhoa/\$maBai".',
      loiGiai: '''String taoKhoaBai(String maKhoa, String maBai) {
  return '\$maKhoa/\$maBai';
}''',
    ),
  ),
  'flutter-web3-blockchain': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Đối tượng JavaScript nào được MetaMask tiêm vào trình duyệt để dApp giao tiếp?',
        ['window.web3', 'window.ethereum', 'window.metamask'],
        1,
        'MetaMask tiêm provider chuẩn EIP-1193 vào đối tượng window.ethereum.',
      ),
      CauHoiQuiz(
        'Để nạp tiền vào Smart Contract, ta gọi hàm RPC nào của MetaMask?',
        ['eth_accounts', 'eth_call', 'eth_sendTransaction'],
        2,
        'eth_sendTransaction được sử dụng để gửi giao dịch kèm giá trị (value) và dữ liệu thực thi (data).',
      ),
      CauHoiQuiz(
        'Lý do cần xác thực giao dịch on-chain trên máy chủ backend là gì?',
        ['Tránh gian lận client-side và tấn công Replay Attack', 'Để tăng tốc độ giao dịch', 'MetaMask không cho phép kiểm tra từ app'],
        0,
        'Client có thể bị can thiệp; backend phải tự gọi JSON-RPC đối chiếu orderId để đảm bảo tính an toàn tài chính.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Quy đổi ETH sang Wei',
      deBai: 'Viết hàm ethSangWei(double eth). Biết 1 ETH = 10^18 Wei. Trả về số lượng Wei dưới dạng BigInt.',
      maKhoiDau: '''BigInt ethSangWei(double eth) {
  return BigInt.zero;
}''',
      ketQua: 'ethSangWei(0.01) -> BigInt.from(10000000000000000)',
      goiY: '1 ETH = 1,000,000,000,000,000,000 Wei.',
      loiGiai: '''BigInt ethSangWei(double eth) {
  final weiPerEth = BigInt.from(10).pow(18);
  return BigInt.from((eth * 1e6).round()) * (weiPerEth ~/ BigInt.from(1e6));
}''',
    ),
  ),
  'flutter-clean-architecture': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Theo Clean Architecture, tầng nào nằm ở trung tâm và không phụ thuộc vào bất kỳ tầng nào khác?',
        ['Presentation', 'Data', 'Domain'],
        2,
        'Tầng Domain chứa Enterprise Business Rules và Entities, là lõi độc lập hoàn toàn.',
      ),
      CauHoiQuiz(
        'Lợi ích chính của việc phân chia Micro-packages độc lập là gì?',
        ['Tăng dung lượng file tải về', 'Cô lập dependencies và tăng tốc độ biên dịch song song', 'Không cần viết unit test'],
        1,
        'Micro-packages giúp mã nguồn module hóa cao, kiểm thử độc lập và tăng tốc build đáng kể.',
      ),
      CauHoiQuiz(
        'Nguyên tắc Dependency Inversion (D trong SOLID) phát biểu điều gì?',
        ['Module cấp cao không nên phụ thuộc module cấp thấp; cả hai nên phụ thuộc vào abstractions', 'Tất cả hàm phải private', 'Không được dùng kế thừa'],
        0,
        'Nguyên tắc Đảo ngược phụ thuộc yêu cầu cả hai tầng cùng dựa trên abstraction (interface/abstract class).',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Kiểm tra đường dẫn Feature module hợp lệ',
      deBai: 'Viết hàm laModuleHopLe(String duongDan). Trả về true nếu đường dẫn bắt đầu bằng "packages/features/".',
      maKhoiDau: '''bool laModuleHopLe(String duongDan) {
  return false;
}''',
      ketQua: 'laModuleHopLe("packages/features/auth") -> true',
      goiY: 'Dùng startsWith("packages/features/").',
      loiGiai: '''bool laModuleHopLe(String duongDan) {
  return duongDan.startsWith('packages/features/');
}''',
    ),
  ),
  'flutter-ai-agent-pro': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Ưu điểm lớn nhất của Streaming SSE so với phản hồi một lần trong AI chat là gì?',
        ['Giảm dung lượng token', 'Người dùng thấy ký tự gõ theo thời gian thực, giảm cảm giác chờ đợi', 'Không cần internet'],
        1,
        'Streaming gửi dữ liệu từng chunk giúp giao diện sống động và phản hồi tức thì.',
      ),
      CauHoiQuiz(
        'Cơ chế Tool / Function Calling cho phép LLM làm gì?',
        ['Chạy trực tiếp code mã độc', 'Trả về cấu trúc JSON yêu cầu ứng dụng client gọi hàm tương ứng', 'Tự động sửa database'],
        1,
        'LLM phân tích câu hỏi và sinh ra lời gọi hàm có cấu trúc JSON để ứng dụng thực thi.',
      ),
      CauHoiQuiz(
        'Kỹ thuật Sliding Window Context dùng để giải quyết vấn đề gì?',
        ['Giới hạn cửa sổ ngữ cảnh (Context Window) và tiết kiệm chi phí Token', 'Tăng độ phân giải hình ảnh', 'Bảo mật mật khẩu'],
        0,
        'Cắt tỉa lịch sử hội thoại chỉ giữ lại các lượt gần nhất giúp không vượt ngưỡng giới hạn token của model.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Lọc tin nhắn theo vai trò',
      deBai: 'Viết hàm locTinNhanUser(List<Map<String, String>> ds). Lọc và trả về danh sách nội dung của role "user".',
      maKhoiDau: '''List<String> locTinNhanUser(List<Map<String, String>> ds) {
  return [];
}''',
      ketQua: '[{"role": "user", "text": "Hi"}] -> ["Hi"]',
      goiY: 'Lọc m["role"] == "user" rồi lấy m["text"].',
      loiGiai: '''List<String> locTinNhanUser(List<Map<String, String>> ds) {
  return ds
      .where((m) => m['role'] == 'user')
      .map((m) => m['text'] ?? '')
      .toList();
}''',
    ),
  ),
  'flutter-security-pro': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Tại sao không nên lưu Token JWT trong SharedPreferences hoặc LocalStorage?',
        ['Dữ liệu được lưu dạng văn bản thuần (plaintext) và dễ bị trích xuất trái phép', 'Dung lượng tối đa chỉ 100 byte', 'Không đọc được trên Web'],
        0,
        'SharedPreferences/LocalStorage không mã hóa, rất nguy hiểm khi thiết bị bị can thiệp vật lý.',
      ),
      CauHoiQuiz(
        'Mục đích của kỹ thuật SSL Certificate Pinning là gì?',
        ['Tăng tốc độ tải trang web', 'Ngăn chặn tấn công Man-in-the-Middle bằng chứng chỉ giả mạo', 'Nén dữ liệu JSON'],
        1,
        'SSL Pinning chỉ tin cậy chứng chỉ số được ghim cứng trong app, từ chối mọi chứng chỉ giả mạo từ proxy can thiệp.',
      ),
      CauHoiQuiz(
        'Thuật toán mã hóa đối xứng nào được khuyến nghị chuẩn hiện đại nhất?',
        ['DES', 'MD5', 'AES-256-GCM'],
        2,
        'AES-256-GCM cung cấp cả tính bảo mật (confidentiality) và xác thực tính toàn vẹn (integrity).',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Ẩn bớt ký tự nhạy cảm của địa chỉ ví',
      deBai: 'Viết hàm cheDiaChiVi(String vi). Nếu độ dài < 10 trả về vi, ngược lại giữ 6 ký tự đầu, 4 ký tự cuối và thay giữa bằng "...".',
      maKhoiDau: '''String cheDiaChiVi(String vi) {
  return vi;
}''',
      ketQua: '"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" -> "0x3C44...93BC"',
      goiY: 'Dùng substring(0, 6) + "..." + substring(vi.length - 4).',
      loiGiai: '''String cheDiaChiVi(String vi) {
  if (vi.length < 10) return vi;
  return '\${vi.substring(0, 6)}...\${vi.substring(vi.length - 4)}';
}''',
    ),
  ),
  'flutter-cicd-devops': BaiLuyenTap(
    [
      CauHoiQuiz(
        'Ưu điểm của Multi-stage Docker build cho Flutter Web là gì?',
        ['Image cuối cùng cực kỳ nhỏ gọn chỉ chứa Nginx và static files (< 25MB)', 'Tự động chạy flutter doctor', 'Không cần cài Git'],
        0,
        'Giai đoạn build Flutter SDK nặng hàng GB bị loại bỏ, chỉ giữ lại web bundle siêu nhẹ chạy trên Nginx alpine.',
      ),
      CauHoiQuiz(
        'Lệnh nào trong Flutter dùng để kiểm tra tĩnh toàn bộ mã nguồn theo chuẩn linter?',
        ['flutter check', 'flutter analyze', 'flutter verify'],
        1,
        'flutter analyze phân tích cú pháp tĩnh và cảnh báo vi phạm quy tắc quy ước mã nguồn.',
      ),
      CauHoiQuiz(
        'Trong GitHub Actions, file workflow định nghĩa quy trình tự động được lưu ở thư mục nào?',
        ['.github/workflows/', 'configs/actions/', '.ci/pipelines/'],
        0,
        'GitHub Actions tự động nhận diện các tệp cấu hình YAML đặt trong thư mục .github/workflows/.',
      ),
    ],
    BaiTapCode(
      tieuDe: 'Kiểm tra mã trạng thái HTTP thành công',
      deBai: 'Viết hàm laKetQuaThanhCong(int statusCode). Trả về true nếu statusCode thuộc dải 200 đến 299.',
      maKhoiDau: '''bool laKetQuaThanhCong(int statusCode) {
  return false;
}''',
      ketQua: 'laKetQuaThanhCong(200) -> true, laKetQuaThanhCong(404) -> false',
      goiY: 'Kiểm tra statusCode >= 200 && statusCode < 300.',
      loiGiai: '''bool laKetQuaThanhCong(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}''',
    ),
  ),
};
