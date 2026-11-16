import 'package:flutter_academy/dinh_tuyen/bo_dinh_tuyen.dart';
import 'package:flutter_academy/dinh_tuyen/duong_dan.dart';
import 'package:flutter_academy/models/bo_loc.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dựng đường dẫn', () {
    test('chi tiết và bài học', () {
      expect(DuongDan.chiTiet('dieu-huong-url'), '/khoa-hoc/dieu-huong-url');
      expect(DuongDan.baiHoc('dieu-huong-url', 'b3'),
          '/khoa-hoc/dieu-huong-url/bai/b3');
    });

    test('bộ lọc mặc định cho URL sạch, không có dấu ? thừa', () {
      expect(DuongDan.danhSachVoiLoc(BoLoc.macDinh), '/khoa-hoc');
    });

    test('mã hoá phần trăm cho từ khoá có dấu và khoảng trắng', () {
      final url = DuongDan.danhSachVoiLoc(const BoLoc(tuKhoa: 'điều hướng'));
      expect(url.startsWith('/khoa-hoc?q='), isTrue);
      expect(url.contains(' '), isFalse);
      // Giải mã lại phải ra đúng chuỗi ban đầu.
      expect(Uri.parse(url).queryParameters['q'], 'điều hướng');
    });

    test('nhiều tham số nối bằng &', () {
      final url = DuongDan.danhSachVoiLoc(
        const BoLoc(danhMuc: 'Web', mucDo: MucDo.nangCao),
      );
      final q = Uri.parse(url).queryParameters;
      expect(q['danh-muc'], 'Web');
      expect(q['muc-do'], 'nangCao');
    });
  });

  group('phaiDangNhap', () {
    test('trang được bảo vệ', () {
      expect(DuongDan.phaiDangNhap('/cua-toi'), isTrue);
      expect(DuongDan.phaiDangNhap('/ho-so'), isTrue);
      expect(DuongDan.phaiDangNhap('/ho-so/doi-ten'), isTrue);
    });

    test('trang công khai', () {
      expect(DuongDan.phaiDangNhap('/'), isFalse);
      expect(DuongDan.phaiDangNhap('/khoa-hoc'), isFalse);
      expect(DuongDan.phaiDangNhap('/khoa-hoc/abc/bai/b1'), isFalse);
    });

    test('đường dẫn chỉ TRÙNG TIỀN TỐ thì không bị chặn oan', () {
      // Nếu cài đặt bằng `startsWith('/ho-so')` trơn thì dòng này đỏ.
      expect(DuongDan.phaiDangNhap('/ho-so-cong-khai'), isFalse);
    });
  });

  group('chiSoTab', () {
    test('mỗi tab ra đúng chỉ số của nó', () {
      expect(DuongDan.chiSoTab('/'), 0);
      expect(DuongDan.chiSoTab('/khoa-hoc'), 1);
      expect(DuongDan.chiSoTab('/cua-toi'), 2);
      expect(DuongDan.chiSoTab('/ho-so'), 3);
    });

    test('trang con vẫn sáng đúng tab cha', () {
      expect(DuongDan.chiSoTab('/khoa-hoc/dieu-huong-url'), 1);
      expect(DuongDan.chiSoTab('/khoa-hoc/dieu-huong-url/bai/b2'), 1);
    });

    test('"/" là tiền tố của mọi thứ nhưng không được thắng', () {
      // Lỗi kinh điển: duyệt theo thứ tự và so khớp tiền tố thì trang nào
      // cũng ra "Trang chủ".
      expect(DuongDan.chiSoTab('/cua-toi'), isNot(0));
    });

    test('trang ngoài thanh điều hướng trả về -1', () {
      expect(DuongDan.chiSoTab('/dang-nhap'), -1);
      expect(DuongDan.chiSoTab('/khong-co-that'), -1);
    });
  });

  group('diaChiVeSauDangNhap', () {
    test('quay về đúng trang đã định vào', () {
      expect(diaChiVeSauDangNhap('/cua-toi'), '/cua-toi');
      expect(diaChiVeSauDangNhap('/khoa-hoc?danh-muc=Web'),
          '/khoa-hoc?danh-muc=Web');
    });

    test('không có tham số thì về trang chủ', () {
      expect(diaChiVeSauDangNhap(null), '/');
      expect(diaChiVeSauDangNhap(''), '/');
    });

    test('chặn chuyển hướng ra ngoài (open redirect)', () {
      // Đây là lỗ hổng thật, có tên riêng. Không có ba dòng này thì một link
      // dạng /dang-nhap?tiep=https://trang-gia-mao là đủ để lừa người dùng.
      expect(diaChiVeSauDangNhap('https://trang-khac.example'), '/');
      expect(diaChiVeSauDangNhap('//trang-khac.example'), '/');
      expect(diaChiVeSauDangNhap('javascript:alert(1)'), '/');
      expect(diaChiVeSauDangNhap('khoa-hoc'), '/');
    });
  });
}
