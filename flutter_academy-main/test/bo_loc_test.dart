import 'package:flutter_academy/models/bo_loc.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'du_lieu_kiem_thu.dart';

void main() {
  final nguon = boMau();

  group('lọc', () {
    test('mặc định giữ nguyên tất cả', () {
      expect(BoLoc.macDinh.apDung(nguon).length, nguon.length);
    });

    test('theo danh mục', () {
      final ra = const BoLoc(danhMuc: 'Web').apDung(nguon);
      expect(ma(ra), ['a-dieu-huong', 'f-wasm']);
    });

    test('theo mức độ', () {
      final ra = const BoLoc(mucDo: MucDo.nangCao).apDung(nguon);
      expect(ma(ra)..sort(), ['d-mvvm', 'f-wasm']);
    });

    test('chỉ miễn phí', () {
      final ra = const BoLoc(chiMienPhi: true).apDung(nguon);
      expect(ma(ra)..sort(), ['c-dart', 'e-kiem-thu']);
    });

    test('từ khoá không dấu khớp tiêu đề có dấu', () {
      final ra = const BoLoc(tuKhoa: 'dieu huong').apDung(nguon);
      expect(ma(ra), ['a-dieu-huong']);
    });

    test('từ khoá khớp cả tên danh mục', () {
      final ra = const BoLoc(tuKhoa: 'kien truc').apDung(nguon);
      expect(ma(ra), ['d-mvvm']);
    });

    test('nhiều điều kiện cùng lúc', () {
      final ra = const BoLoc(danhMuc: 'Web', chiMienPhi: true).apDung(nguon);
      expect(ra, isEmpty);
    });

    test('không sửa danh sách đầu vào', () {
      final truoc = List.of(nguon);
      const BoLoc(danhMuc: 'Web').apDung(nguon);
      expect(ma(nguon), ma(truoc));
    });
  });

  group('sắp xếp', () {
    test('phổ biến: lượt đánh giá giảm dần', () {
      final ra = BoLoc.macDinh.apDung(nguon);
      expect(ma(ra).first, 'c-dart'); // 900 lượt
      expect(ma(ra).last, 'f-wasm'); // 120 lượt
    });

    test('bằng điểm thì xếp theo tên, thứ tự luôn ổn định', () {
      // b-hive và e-kiem-thu cùng 500 lượt.
      // "Kiểm thử Flutter" < "Lưu trữ với Hive" khi bỏ dấu.
      final ra = ma(BoLoc.macDinh.apDung(nguon));
      expect(ra.indexOf('e-kiem-thu'), lessThan(ra.indexOf('b-hive')));
    });

    test('đánh giá cao', () {
      final ra = ma(const BoLoc(thuTu: ThuTuSapXep.danhGiaCao).apDung(nguon));
      // 4.9: a-dieu-huong ("Điều hướng…") và d-mvvm ("Kiến trúc…")
      expect(ra.take(2).toList(), ['a-dieu-huong', 'd-mvvm']);
      expect(ra.last, 'e-kiem-thu'); // 4.5
    });

    test('giá tăng dần và giảm dần là nghịch đảo về hai đầu', () {
      final tang = ma(const BoLoc(thuTu: ThuTuSapXep.giaTang).apDung(nguon));
      final giam = ma(const BoLoc(thuTu: ThuTuSapXep.giaGiam).apDung(nguon));
      expect(tang.last, 'd-mvvm'); // đắt nhất
      expect(giam.first, 'd-mvvm');
    });

    test('tên A → Z bỏ dấu', () {
      final ra = ma(const BoLoc(thuTu: ThuTuSapXep.tenAZ).apDung(nguon));
      expect(ra, [
        'c-dart', //      "dart co ban"
        'a-dieu-huong', //"dieu huong theo url"
        'f-wasm', //      "flutter web va webassembly"
        // Chú ý cặp này: "kiem" đứng TRƯỚC "kien" vì 'm' < 'n'. Bỏ dấu xong
        // mới so sánh nên "Kiểm thử" lên trước "Kiến trúc" — khác hẳn thứ tự
        // mà mắt người quen nhìn chữ có dấu đoán ra.
        'e-kiem-thu', //  "kiem thu flutter"
        'd-mvvm', //      "kien truc mvvm"
        'b-hive', //      "luu tru voi hive"
      ]);
    });
  });

  group('đồng bộ với URL', () {
    test('bộ lọc mặc định không sinh tham số nào', () {
      expect(BoLoc.macDinh.sangThamSo(), isEmpty);
    });

    test('chỉ sinh tham số cho giá trị khác mặc định', () {
      const loc = BoLoc(danhMuc: 'Web', thuTu: ThuTuSapXep.giaTang);
      expect(loc.sangThamSo(), {'danh-muc': 'Web', 'sap': 'gia-tang'});
    });

    test('đi một vòng URL rồi về vẫn bằng chính nó', () {
      const goc = BoLoc(
        tuKhoa: 'điều hướng',
        danhMuc: 'Web',
        mucDo: MucDo.nangCao,
        chiMienPhi: true,
        chiPro: true,
        thuTu: ThuTuSapXep.danhGiaCao,
      );
      expect(BoLoc.tuThamSo(goc.sangThamSo()), goc);
    });

    test('đồng bộ URL cho chiPro', () {
      const loc = BoLoc(chiPro: true);
      expect(loc.sangThamSo(), {'pro': '1'});
      expect(BoLoc.tuThamSo(const {'pro': '1'}).chiPro, isTrue);
    });

    test('tham số lạ thì lùi về mặc định, không ném lỗi', () {
      final loc = BoLoc.tuThamSo(const {
        'muc-do': 'khong-co-that',
        'sap': 'khong-co-that',
        'danh-muc': '   ',
        'mien-phi': 'co',
      });
      expect(loc.mucDo, isNull);
      expect(loc.danhMuc, isNull);
      expect(loc.chiMienPhi, isFalse);
      expect(loc.thuTu, ThuTuSapXep.phoBien);
    });

    test('từ khoá chỉ có khoảng trắng thì không vào URL', () {
      expect(const BoLoc(tuKhoa: '   ').sangThamSo(), isEmpty);
    });
  });

  group('copyVoi', () {
    test('xoá được giá trị về null', () {
      const loc = BoLoc(danhMuc: 'Web', mucDo: MucDo.coBan);
      expect(loc.copyVoi(xoaDanhMuc: true).danhMuc, isNull);
      expect(loc.copyVoi(xoaMucDo: true).mucDo, isNull);
      // Xoá cái này không đụng cái kia.
      expect(loc.copyVoi(xoaDanhMuc: true).mucDo, MucDo.coBan);
    });

    test('coLoc phản ánh đúng', () {
      expect(BoLoc.macDinh.coLoc, isFalse);
      // Đổi thứ tự sắp xếp KHÔNG tính là đang lọc.
      expect(const BoLoc(thuTu: ThuTuSapXep.tenAZ).coLoc, isFalse);
      expect(const BoLoc(chiMienPhi: true).coLoc, isTrue);
      expect(const BoLoc(tuKhoa: ' a ').coLoc, isTrue);
    });
  });
}
