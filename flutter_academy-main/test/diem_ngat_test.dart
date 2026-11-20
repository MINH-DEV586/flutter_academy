import 'package:flutter_academy/cau_hinh/diem_ngat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiểm thử phần bố cục **mà không dựng widget nào**.
///
/// Đây là điểm đáng chú ý nhất của tệp này: quyết định bố cục được viết dưới
/// dạng hàm thuần `DiemNgat.tu(double)`, nên kiểm thử chạy trong mili giây và
/// không cần `WidgetTester`. Nếu logic đó nằm rải rác trong các lời gọi
/// `MediaQuery.of(context)` thì muốn kiểm thử phải dựng cả cây widget.
void main() {
  group('khổ màn hình', () {
    test('ba khoảng giá trị', () {
      expect(DiemNgat.tu(360), Kho.dienThoai);
      expect(DiemNgat.tu(719.9), Kho.dienThoai);
      expect(DiemNgat.tu(720), Kho.mayTinhBang);
      expect(DiemNgat.tu(1199.9), Kho.mayTinhBang);
      expect(DiemNgat.tu(1200), Kho.manHinhRong);
      expect(DiemNgat.tu(2560), Kho.manHinhRong);
    });

    test('bề rộng 0 vẫn ra kết quả hợp lệ', () {
      // Xảy ra thật trong khung hình đầu tiên trên web, trước khi trình duyệt
      // báo kích thước.
      expect(DiemNgat.tu(0), Kho.dienThoai);
    });

    test('chỉ điện thoại mới không có thanh bên', () {
      expect(Kho.dienThoai.coThanhBen, isFalse);
      expect(Kho.mayTinhBang.coThanhBen, isTrue);
      expect(Kho.manHinhRong.coThanhBen, isTrue);
    });
  });

  group('số cột của lưới', () {
    test('tăng dần theo bề rộng', () {
      expect(DiemNgat.soCotLuoi(400), 1);
      expect(DiemNgat.soCotLuoi(559), 1);
      expect(DiemNgat.soCotLuoi(560), 2);
      expect(DiemNgat.soCotLuoi(899), 2);
      expect(DiemNgat.soCotLuoi(900), 3);
      expect(DiemNgat.soCotLuoi(1239), 3);
      expect(DiemNgat.soCotLuoi(1240), 4);
      expect(DiemNgat.soCotLuoi(3000), 4);
    });

    test('không bao giờ trả về 0 — GridView sẽ ném lỗi', () {
      for (final w in [0.0, 1.0, 10.0, 100.0]) {
        expect(DiemNgat.soCotLuoi(w), greaterThanOrEqualTo(1));
      }
    });

    test('số cột không giảm khi bề rộng tăng', () {
      var truoc = 0;
      for (var w = 0.0; w < 2000; w += 17) {
        final c = DiemNgat.soCotLuoi(w);
        expect(c, greaterThanOrEqualTo(truoc));
        truoc = c;
      }
    });
  });
}
