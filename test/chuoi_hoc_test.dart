import 'package:flutter_academy/models/cap_do.dart';
import 'package:flutter_academy/models/chuoi_hoc.dart';
import 'package:flutter_academy/models/huy_hieu.dart';
import 'package:flutter_academy/models/nhat_ky_ngay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapDo Model', () {
    test('Khởi tạo đúng theo tổng XP tích luỹ', () {
      final lv1 = CapDo.tuTongXp(0);
      expect(lv1.capHienTai, 1);
      expect(lv1.danhHieu, 'Tập sự');
      expect(lv1.xpCuaCap, 0);
      expect(lv1.xpCanThiet, 100);

      final lv2 = CapDo.tuTongXp(120);
      expect(lv2.capHienTai, 2);
      expect(lv2.danhHieu, 'Nhập môn');
      expect(lv2.xpCuaCap, 20); // 120 - 100
      expect(lv2.xpCanThiet, 150);

      final lv5 = CapDo.tuTongXp(750);
      expect(lv5.capHienTai, 5);
      expect(lv5.danhHieu, 'Thành thạo');
    });

    test('Kiểm tra phát hiện thăng cấp (Level Up)', () {
      expect(CapDo.kiemTraLenCap(90, 110), isTrue);
      expect(CapDo.kiemTraLenCap(110, 140), isFalse);
      expect(CapDo.kiemTraLenCap(240, 260), isTrue);
    });
  });

  group('ChuoiHoc Model & Freeze Logic', () {
    final ngay1 = DateTime.utc(2026, 11, 1);
    final ngay2 = DateTime.utc(2026, 11, 2);
    final ngay3 = DateTime.utc(2026, 11, 3);

    test('Lần đầu học trong đời tạo chuỗi 1', () {
      var streak = const ChuoiHoc();
      streak = streak.ghiNhanHocHopLe(ngay1, xpCongThem: 20);

      expect(streak.chuoiHienTai, 1);
      expect(streak.chuoiDaiNhat, 1);
      expect(streak.ngayHocGanNhat, '2026-11-01');
      expect(streak.tongXp, 20);
      expect(streak.daHocHomNay(ngay1), isTrue);
    });

    test('Học nhiều lần trong cùng một ngày không tăng chuỗi thêm', () {
      var streak = const ChuoiHoc();
      streak = streak.ghiNhanHocHopLe(ngay1, xpCongThem: 20);
      streak = streak.ghiNhanHocHopLe(ngay1, xpCongThem: 30);

      expect(streak.chuoiHienTai, 1);
      expect(streak.tongXp, 50);
    });

    test('Học liên tiếp các ngày chuỗi tăng đều', () {
      var streak = const ChuoiHoc();
      streak = streak.ghiNhanHocHopLe(ngay1);
      streak = streak.ghiNhanHocHopLe(ngay2);
      streak = streak.ghiNhanHocHopLe(ngay3);

      expect(streak.chuoiHienTai, 3);
      expect(streak.chuoiDaiNhat, 3);
    });

    test('Tặng 1 Freeze miễn phí khi đạt chuỗi 7 ngày', () {
      var streak = const ChuoiHoc();
      for (var i = 1; i <= 7; i++) {
        streak = streak.ghiNhanHocHopLe(DateTime.utc(2026, 11, i));
      }

      expect(streak.chuoiHienTai, 7);
      expect(streak.soKhiensFreeze, 1); // Được tặng 1 Freeze
    });

    test('Bảo vệ chuỗi khi lỡ 1 ngày nhờ có Freeze', () {
      // Giả sử có chuỗi 15 ngày, có 1 Freeze
      var streak = const ChuoiHoc(
        chuoiHienTai: 15,
        chuoiDaiNhat: 15,
        ngayHocGanNhat: '2026-11-15',
        soKhiensFreeze: 1,
      );

      // Ngày 16 không học, ngày 17 học lại
      streak = streak.ghiNhanHocHopLe(DateTime.utc(2026, 11, 17));

      expect(streak.soKhiensFreeze, 0); // Đã tiêu hao 1 Freeze
      expect(streak.cacNgayFreezeDaDung.contains('2026-11-16'), isTrue);
      expect(streak.chuoiHienTai, 17); // 15 + 1 (freeze ngày 16) + 1 (ngày 17)
    });

    test('Bỏ lỡ ngày khi không có Freeze thì chuỗi đứt về 1', () {
      var streak = const ChuoiHoc(
        chuoiHienTai: 15,
        chuoiDaiNhat: 15,
        ngayHocGanNhat: '2026-11-15',
        soKhiensFreeze: 0,
      );

      // Ngày 17 học (bỏ lỡ ngày 16 và không có Freeze)
      streak = streak.ghiNhanHocHopLe(DateTime.utc(2026, 11, 17));

      expect(streak.chuoiHienTai, 1);
      expect(streak.chuoiDaiNhat, 15); // Kỷ lục 15 vẫn được giữ nguyên
    });

    test('Đổi điểm XP lấy Khiên Freeze', () {
      var streak = const ChuoiHoc(tongXp: 250, soKhiensFreeze: 0);
      final muaThanhCong = streak.muaFreeze(giaXp: 100, toiDa: 3);

      expect(muaThanhCong, isNotNull);
      expect(muaThanhCong!.soKhiensFreeze, 1);
      expect(muaThanhCong.tongXp, 150);

      // Không đủ XP thì trả về null
      final hetXp = const ChuoiHoc(tongXp: 50, soKhiensFreeze: 0);
      expect(hetXp.muaFreeze(giaXp: 100), isNull);
    });

    test('Tự động dùng Freeze khi mở app kiểm tra', () {
      var streak = const ChuoiHoc(
        chuoiHienTai: 5,
        ngayHocGanNhat: '2026-11-10',
        soKhiensFreeze: 1,
      );

      // Mở app vào ngày 12 (lỡ ngày 11)
      final capNhat = streak.kiemTraVaDungFreezeTuDong(DateTime.utc(2026, 11, 12));
      expect(capNhat.soKhiensFreeze, 0);
      expect(capNhat.chuoiHienTai, 6); // 5 + 1 freeze
      expect(capNhat.cacNgayFreezeDaDung.contains('2026-11-11'), isTrue);
    });
  });

  group('HuyHieu Model', () {
    test('Tự động phát hiện mở khoá huy hiệu khi đạt mốc chuỗi', () {
      final daCo = <String>{};
      final moi3 = HuyHieu.kiemTraMoKhoa(
        soNgayStreak: 3,
        cacMaDaDat: daCo,
        ngayHienTai: '2026-11-03',
      );
      expect(moi3.length, 1);
      expect(moi3.first.ma, 'streak_3');
      expect(moi3.first.tieuDe, 'Getting Started');

      // Khi đạt 7 ngày sẽ nhận thêm 'streak_7'
      daCo.add('streak_3');
      final moi7 = HuyHieu.kiemTraMoKhoa(
        soNgayStreak: 7,
        cacMaDaDat: daCo,
        ngayHienTai: '2026-11-07',
      );
      expect(moi7.length, 1);
      expect(moi7.first.ma, 'streak_7');
      expect(moi7.first.tieuDe, 'Weekly Learner');
    });
  });

  group('NhatKyNgay Model', () {
    test('Đạt điều kiện tính ngày học', () {
      // Dưới 10 phút, không có bài xong -> Chưa đạt
      const nhatKy1 = NhatKyNgay(ngay: '2026-11-01', thoiGianHocGiay: 300);
      expect(nhatKy1.datDieuKienStreak, isFalse);

      // Đủ 10 phút (600 giây) -> Đạt
      const nhatKy2 = NhatKyNgay(ngay: '2026-11-01', thoiGianHocGiay: 600);
      expect(nhatKy2.datDieuKienStreak, isTrue);

      // Có hoàn thành bài học -> Đạt
      const nhatKy3 = NhatKyNgay(
        ngay: '2026-11-01',
        thoiGianHocGiay: 100,
        baiDaHoanThanh: {'bai_01'},
      );
      expect(nhatKy3.datDieuKienStreak, isTrue);

      // Ngày dùng Freeze -> Đạt
      const nhatKy4 = NhatKyNgay(ngay: '2026-11-01', dungFreeze: true);
      expect(nhatKy4.datDieuKienStreak, isTrue);
    });

    test('Chuyển đổi sang Map và từ Map không thất thoát dữ liệu', () {
      const goc = NhatKyNgay(
        ngay: '2026-11-01',
        thoiGianHocGiay: 1200,
        baiDaHoanThanh: {'bai_01', 'quiz_01'},
        khoaHocDaThamGia: {'flutter_co_ban'},
        xpNhanDuoc: 70,
        dungFreeze: false,
        hoatDongDuyTri: 'Xem video 20 phút',
      );

      final map = goc.sangMap();
      final taiTao = NhatKyNgay.tuMap(map);

      expect(taiTao, equals(goc));
    });
  });
}
