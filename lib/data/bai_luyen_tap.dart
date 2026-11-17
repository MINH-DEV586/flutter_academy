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
};
