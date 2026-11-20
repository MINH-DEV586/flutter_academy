import 'package:flutter_academy/models/tien_do.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('phanTram', () {
    test('chưa học bài nào', () {
      expect(const TienDo(maKhoaHoc: 'k').phanTram(5), 0);
    });

    test('học một phần', () {
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1', 'b2'});
      expect(td.phanTram(5), 40);
      expect(td.phanTram(4), 50);
    });

    test('làm tròn về số nguyên gần nhất', () {
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1'});
      // 1/3 = 33,33% → 33
      expect(td.phanTram(3), 33);
      // 2/3 = 66,67% → 67
      expect(const TienDo(maKhoaHoc: 'k', baiDaXong: {'b1', 'b2'}).phanTram(3),
          67);
    });

    test('không bao giờ vượt 100 dù dữ liệu thừa', () {
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1', 'b2', 'b3'});
      expect(td.phanTram(2), 100);
    });

    test('khoá học không có bài nào thì là 0, không chia cho 0', () {
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1'});
      expect(td.phanTram(0), 0);
      expect(td.tiLe(0), 0.0);
      expect(td.hoanThanh(0), isFalse);
    });
  });

  group('donDep', () {
    test('bỏ những bài không còn trong khoá học', () {
      const td = TienDo(
        maKhoaHoc: 'k',
        baiDaXong: {'b1', 'b2', 'b-da-xoa'},
        baiDangXem: 'b2',
      );
      final sach = td.donDep(['b1', 'b2', 'b3']);
      expect(sach.baiDaXong, {'b1', 'b2'});
      expect(sach.baiDangXem, 'b2');
      // Đây chính là chỗ chặn lỗi "đã học 150%".
      expect(sach.phanTram(3), 67);
    });

    test('xoá luôn bài đang xem nếu bài đó không còn', () {
      const td = TienDo(maKhoaHoc: 'k', baiDangXem: 'b-da-xoa');
      expect(td.donDep(['b1']).baiDangXem, isNull);
    });

    test('không có gì để dọn thì trả về CHÍNH đối tượng cũ', () {
      // Tiết kiệm một lần cấp phát, và quan trọng hơn: giữ nguyên danh tính
      // đối tượng để Riverpod không tưởng nhầm là trạng thái đã đổi.
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1'}, baiDangXem: 'b1');
      expect(identical(td.donDep(['b1', 'b2']), td), isTrue);
    });
  });

  group('daoTrangThai', () {
    test('bật rồi tắt', () {
      const td = TienDo(maKhoaHoc: 'k');
      final bat = td.daoTrangThai('b1');
      expect(bat.daXong('b1'), isTrue);
      expect(bat.daoTrangThai('b1').daXong('b1'), isFalse);
    });

    test('không sửa đối tượng cũ', () {
      const td = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1'});
      td.daoTrangThai('b2');
      expect(td.baiDaXong, {'b1'});
    });

    test('giữ nguyên bài đang xem', () {
      const td = TienDo(maKhoaHoc: 'k', baiDangXem: 'b3');
      expect(td.daoTrangThai('b1').baiDangXem, 'b3');
    });
  });

  group('mã hoá qua Map', () {
    test('đi một vòng rồi về vẫn đúng', () {
      const goc = TienDo(
        maKhoaHoc: 'k',
        baiDaXong: {'b1', 'b3'},
        baiDangXem: 'b3',
      );
      final ve = TienDo.tuMap(goc.sangMap());
      expect(ve.maKhoaHoc, goc.maKhoaHoc);
      expect(ve.baiDaXong, goc.baiDaXong);
      expect(ve.baiDangXem, goc.baiDangXem);
    });

    test('baiDangXem null vẫn đọc lại được', () {
      const goc = TienDo(maKhoaHoc: 'k', baiDaXong: {'b1'});
      expect(TienDo.tuMap(goc.sangMap()).baiDangXem, isNull);
    });
  });
}
