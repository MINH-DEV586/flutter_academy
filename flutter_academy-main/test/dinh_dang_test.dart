import 'package:flutter_academy/models/dinh_dang.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('thoiLuong', () {
    test('dưới một giờ thì chỉ hiện phút', () {
      expect(thoiLuong(300), '5 phút');
      expect(thoiLuong(1380), '23 phút');
    });

    test('làm tròn LÊN tới phút', () {
      // 90 giây là "2 phút", không phải "1 phút" — người học thấy con số nhỏ
      // hơn thực tế sẽ khó chịu hơn thấy số lớn hơn.
      expect(thoiLuong(90), '2 phút');
      expect(thoiLuong(61), '2 phút');
      expect(thoiLuong(60), '1 phút');
    });

    test('tròn giờ thì không hiện phút', () {
      expect(thoiLuong(3600), '1 giờ');
      expect(thoiLuong(7200), '2 giờ');
    });

    test('giờ kèm phút', () {
      expect(thoiLuong(5400), '1 giờ 30 phút');
    });

    test('làm tròn lên chạm 60 phút thì lên thành giờ tròn', () {
      // 3599 giây: 0 giờ dư 3599 → ceil(59,98) = 60 phút. Không xử lý riêng
      // thì ra chuỗi "0 giờ 60 phút".
      expect(thoiLuong(3599), '60 phút');
      expect(thoiLuong(7199), '2 giờ');
    });

    test('không dương thì là 0 phút', () {
      expect(thoiLuong(0), '0 phút');
      expect(thoiLuong(-5), '0 phút');
    });
  });

  group('nhomBaChuSo', () {
    test('chèn dấu chấm mỗi ba chữ số', () {
      expect(nhomBaChuSo(0), '0');
      expect(nhomBaChuSo(999), '999');
      expect(nhomBaChuSo(1000), '1.000');
      expect(nhomBaChuSo(1490000), '1.490.000');
      expect(nhomBaChuSo(1234567890), '1.234.567.890');
    });

    test('số âm giữ dấu trừ ở ngoài', () {
      expect(nhomBaChuSo(-1000), '-1.000');
    });
  });

  group('tienVND', () {
    test('0 đồng là miễn phí', () {
      expect(tienVND(0), 'Miễn phí');
      expect(tienVND(-1), 'Miễn phí');
    });

    test('có đơn vị và dấu phân nhóm', () {
      expect(tienVND(490000), '490.000 ₫');
    });
  });

  group('diem và soGon', () {
    test('điểm luôn một chữ số thập phân', () {
      expect(diem(4), '4.0');
      expect(diem(4.26), '4.3');
      expect(diem(4.94), '4.9');
    });

    test('số lượt rút gọn khi lớn', () {
      expect(soGon(0), '0');
      expect(soGon(999), '999');
      expect(soGon(1000), '1.0k');
      expect(soGon(2140), '2.1k');
      expect(soGon(12345), '12k');
    });
  });
}
