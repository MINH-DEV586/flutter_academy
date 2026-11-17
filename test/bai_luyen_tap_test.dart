import 'package:flutter_academy/data/bai_luyen_tap.dart';
import 'package:flutter_academy/data/du_lieu_mau.dart';
import 'package:flutter_academy/dinh_tuyen/duong_dan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mỗi khóa có quiz hợp lệ và bài tập code riêng', () {
    for (final khoaHoc in DuLieuMau.khoaHoc()) {
      final luyenTap = BaiLuyenTap.cua(khoaHoc.ma)!;
      expect(luyenTap.quiz, hasLength(3), reason: khoaHoc.ma);
      for (final cau in luyenTap.quiz) {
        expect(cau.luaChon.toSet(), hasLength(3));
        expect(cau.dapAn, inInclusiveRange(0, cau.luaChon.length - 1));
        expect(cau.giaiThich, isNotEmpty);
      }
      expect(luyenTap.baiTap.maKhoiDau, isNotEmpty);
      expect(luyenTap.baiTap.ketQua, isNotEmpty);
      expect(luyenTap.baiTap.loiGiai, isNot(luyenTap.baiTap.maKhoiDau));
    }
  });

  test('quiz chấm đúng câu trả lời và bỏ qua câu chưa trả lời', () {
    final quiz = BaiLuyenTap.cua('python-co-ban')!;
    expect(quiz.chamDiem({}), 0);
    expect(quiz.chamDiem({0: 1, 1: 2}), 1);
    expect(quiz.chamDiem({0: 1, 1: 0, 2: 2}), 3);
    expect(BaiLuyenTap.cua('khoa-khong-ton-tai'), isNull);
    expect(
      DuongDan.luyenTap('python-co-ban'),
      '/khoa-hoc/python-co-ban/luyen-tap',
    );
  });
}
