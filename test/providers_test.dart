import 'package:flutter_academy/models/che_do_giao_dien.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/models/tien_do.dart';
import 'package:flutter_academy/viewmodels/phien_vm.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'du_lieu_kiem_thu.dart';
import 'kho_gia_lap.dart';

/// Kiểm thử tầng ViewModel bằng `ProviderContainer`.
///
/// Không dựng widget nào cả. `ProviderContainer.test()` dựng một cây provider
/// độc lập, tự huỷ khi bài kiểm thử kết thúc — đúng thứ cần để kiểm thử
/// ViewModel mà không kéo theo giao diện.
void main() {
  /// Đọc bảng tiến độ hiện tại bằng so khớp mẫu.
  ///
  /// Không dùng `AsyncValue.value`: getter đó ném lại ngoại lệ khi provider
  /// đang ở trạng thái lỗi, nên một bài kiểm thử đang kiểm tra nhánh lỗi sẽ
  /// đỏ vì lý do khác hẳn cái mình muốn kiểm tra.
  Map<String, TienDo> bang(ProviderContainer c) =>
      switch (c.read(tienDoProvider)) {
        AsyncData(:final value) => value,
        _ => const <String, TienDo>{},
      };

  /// Dựng container với ba kho giả lập đã ghi đè.
  ProviderContainer dung({
    List<KhoaHoc>? khoaHoc,
    KhoTienDoGiaLap? tienDo,
    KhoNguoiDungGiaLap? nguoiDung,
    KhoKhoaHocGiaLap? khoKhoaHoc,
  }) {
    return ProviderContainer.test(
      overrides: [
        khoKhoaHocProvider.overrideWithValue(
          khoKhoaHoc ?? KhoKhoaHocGiaLap(khoaHoc ?? boMau()),
        ),
        khoTienDoProvider.overrideWithValue(tienDo ?? KhoTienDoGiaLap()),
        khoChuoiHocProvider.overrideWithValue(KhoChuoiHocGiaLap()),
        khoNguoiDungProvider.overrideWithValue(
          nguoiDung ?? KhoNguoiDungGiaLap(),
        ),
      ],
    );
  }

  group('danhSachKhoaHocProvider', () {
    test('đọc được danh sách từ kho', () async {
      final c = dung();
      final ds = await c.read(danhSachKhoaHocProvider.future);
      expect(ds.length, 6);
    });

    test('kho hỏng thì provider ở trạng thái lỗi, không làm sập', () async {
      final c = dung(khoKhoaHoc: KhoKhoaHocGiaLap(const [], gayLoi: true));
      await expectLater(
        c.read(danhSachKhoaHocProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(c.read(danhSachKhoaHocProvider), isA<AsyncError>());
    });
  });

  group('danhMucProvider', () {
    test('rút danh mục không trùng, giữ thứ tự xuất hiện', () async {
      final c = dung();
      await c.read(danhSachKhoaHocProvider.future);
      expect(c.read(danhMucProvider), [
        'Web',
        'Dữ liệu',
        'Nhập môn',
        'Kiến trúc',
      ]);
    });

    test('lúc chưa tải xong thì là danh sách rỗng, không null', () {
      final c = dung();
      expect(c.read(danhMucProvider), isEmpty);
    });
  });

  group('tinhPhanTram', () {
    final ds = boMau(); // mỗi khoá học có 3 bài: b1, b2, b3

    test('chỉ tính khoá đã có tiến độ', () {
      final ra = tinhPhanTram(ds, {
        'c-dart': const TienDo(maKhoaHoc: 'c-dart', baiDaXong: {'b1'}),
      });
      expect(ra, {'c-dart': 33});
    });

    test('bỏ qua tiến độ của khoá học không còn tồn tại', () {
      final ra = tinhPhanTram(ds, {
        'khoa-da-go': const TienDo(maKhoaHoc: 'khoa-da-go', baiDaXong: {'b1'}),
      });
      expect(ra, isEmpty);
    });

    test('lọc bài đã bị xoá khỏi khoá học trước khi tính', () {
      final ra = tinhPhanTram(ds, {
        'c-dart': const TienDo(
          maKhoaHoc: 'c-dart',
          baiDaXong: {'b1', 'b2', 'b3', 'b-khong-con'},
        ),
      });
      // 4 bài đã xong nhưng chỉ 3 bài còn tồn tại → đúng 100%, không phải 133%.
      expect(ra['c-dart'], 100);
    });
  });

  group('locDangHoc', () {
    final ds = boMau();

    test('chỉ giữ khoá đã bắt đầu', () {
      final ra = locDangHoc(ds, {'c-dart': 33, 'b-hive': 67});
      expect(ma(ra)..sort(), ['b-hive', 'c-dart']);
    });

    test('khoá đã hoàn thành xuống cuối', () {
      final ra = locDangHoc(ds, {'c-dart': 100, 'b-hive': 10});
      expect(ma(ra), ['b-hive', 'c-dart']);
    });

    test('trong nhóm chưa xong, gần xong hơn thì lên trước', () {
      final ra = locDangHoc(ds, {'c-dart': 20, 'b-hive': 80, 'd-mvvm': 50});
      expect(ma(ra), ['b-hive', 'd-mvvm', 'c-dart']);
    });
  });

  group('TienDoVM', () {
    test('đánh dấu xong rồi bỏ đánh dấu', () async {
      final kho = KhoTienDoGiaLap();
      final c = dung(tienDo: kho);
      await c.read(tienDoProvider.future);

      final vm = c.read(tienDoProvider.notifier);
      await vm.daoTrangThaiBai('c-dart', 'b1');

      expect(bang(c)['c-dart']?.daXong('b1'), isTrue);
      expect(
        kho.duLieu['c-dart']?.daXong('b1'),
        isTrue,
        reason: 'phải ghi xuống kho, không chỉ đổi trên màn hình',
      );

      await vm.daoTrangThaiBai('c-dart', 'b1');
      expect(bang(c)['c-dart']?.daXong('b1'), isFalse);
    });

    test('ghi nhớ bài đang xem, gọi lại cùng bài thì không ghi thêm', () async {
      final kho = KhoTienDoGiaLap();
      final c = dung(tienDo: kho);
      await c.read(tienDoProvider.future);
      final vm = c.read(tienDoProvider.notifier);

      await vm.danhDauDangXem('c-dart', 'b2');
      expect(kho.soLanLuu, 1);
      await vm.danhDauDangXem('c-dart', 'b2');
      expect(kho.soLanLuu, 1, reason: 'không đổi thì không ghi lại');
      await vm.danhDauDangXem('c-dart', 'b3');
      expect(kho.soLanLuu, 2);
    });

    test('đặt lại xoá sạch tiến độ của một khoá', () async {
      final kho = KhoTienDoGiaLap({
        'c-dart': const TienDo(maKhoaHoc: 'c-dart', baiDaXong: {'b1', 'b2'}),
        'b-hive': const TienDo(maKhoaHoc: 'b-hive', baiDaXong: {'b1'}),
      });
      final c = dung(tienDo: kho);
      await c.read(tienDoProvider.future);

      await c.read(tienDoProvider.notifier).datLai('c-dart');
      expect(bang(c).containsKey('c-dart'), isFalse);
      expect(kho.duLieu.containsKey('c-dart'), isFalse);
      expect(kho.duLieu.containsKey('b-hive'), isTrue);
    });

    test('nạp lại từ kho khi ghi hỏng', () async {
      final kho = KhoTienDoGiaLap();
      final c = dung(tienDo: kho);
      await c.read(tienDoProvider.future);

      kho.gayLoi = true;
      await c.read(tienDoProvider.notifier).daoTrangThaiBai('c-dart', 'b1');

      // Provider đã tự nạp lại; giá trị mới đọc được phải khớp với kho
      // (tức là KHÔNG có bài nào được đánh dấu), chứ không giữ cái đã hiện
      // lạc quan trên màn hình.
      final sau = await c.read(tienDoProvider.future);
      expect(sau['c-dart'], isNull);
    });
  });

  group('PhienVM', () {
    test('chưa đăng nhập', () async {
      final c = dung();
      expect(await c.read(phienProvider.future), isNull);
      expect(c.read(daDangNhapProvider), isFalse);
      expect(c.read(phienDaTaiProvider), isTrue);
    });

    test('đăng ký rồi đăng xuất', () async {
      final kho = KhoNguoiDungGiaLap();
      final c = dung(nguoiDung: kho);
      await c.read(phienProvider.future);

      final loi = await c
          .read(phienProvider.notifier)
          .dangNhap(
            email: 'an@phenikaa-uni.edu.vn',
            hoTen: 'Võ Thái Anh',
            matKhau: 'mat-khau-kiem-thu',
          );
      expect(loi, isNull);
      expect(c.read(daDangNhapProvider), isTrue);
      expect(kho.duLieu?.hoTen, 'Võ Thái Anh');

      await c.read(phienProvider.notifier).dangXuat();
      expect(c.read(daDangNhapProvider), isFalse);
      expect(kho.duLieu, isNull);
    });

    test('email sai thì báo lỗi và không ghi gì', () async {
      final kho = KhoNguoiDungGiaLap();
      final c = dung(nguoiDung: kho);
      await c.read(phienProvider.future);

      final loi = await c
          .read(phienProvider.notifier)
          .dangNhap(email: 'khong-phai-email', matKhau: 'mat-khau-kiem-thu');
      expect(loi, isNotNull);
      expect(kho.duLieu, isNull);
      expect(c.read(daDangNhapProvider), isFalse);
    });

    test('phiên có sẵn được đọc lên khi khởi động', () async {
      final c = dung(
        nguoiDung: KhoNguoiDungGiaLap(
          duLieu: const NguoiDung(email: 'a@b.vn', hoTen: 'Trần Thu Hà'),
        ),
      );
      final nd = await c.read(phienProvider.future);
      expect(nd?.hoTen, 'Trần Thu Hà');
      expect(c.read(daDangNhapProvider), isTrue);
    });

    test('đăng ký khóa cập nhật danh sách và tách theo tài khoản', () async {
      final c = dung();
      final phien = c.read(phienProvider.notifier);
      expect(await c.read(dangKyKhoaHocProvider.future), isEmpty);
      await phien.dangNhap(email: 'a@b.vn', matKhau: 'mat-khau-kiem-thu');
      expect(await c.read(dangKyKhoaHocProvider.future), isEmpty);

      await c.read(dangKyKhoaHocProvider.notifier).dangKy('python-co-ban');
      expect(await c.read(dangKyKhoaHocProvider.future), {'python-co-ban'});

      await phien.dangXuat();
      await phien.dangNhap(email: 'c@b.vn', matKhau: 'mat-khau-kiem-thu');
      expect(await c.read(dangKyKhoaHocProvider.future), isEmpty);
      await phien.dangXuat();
      await phien.dangNhap(email: 'a@b.vn', matKhau: 'mat-khau-kiem-thu');
      expect(await c.read(dangKyKhoaHocProvider.future), {'python-co-ban'});
    });
  });

  group('hopLeEmail', () {
    test('chấp nhận email bình thường', () {
      expect(hopLeEmail('an@phenikaa-uni.edu.vn'), isTrue);
      expect(hopLeEmail('  a.b@c.vn  '), isTrue);
    });

    test('từ chối các dạng hỏng', () {
      for (final s in [
        '',
        'a@b',
        'a@b.',
        'a@.vn',
        '@b.vn',
        'a b@c.vn',
        'a@@b.vn',
        'abc.vn',
      ]) {
        expect(hopLeEmail(s), isFalse, reason: 'phải từ chối "$s"');
      }
    });
  });

  group('chuDeProvider', () {
    test('xoay vòng ba chế độ rồi quay lại', () {
      final c = dung();
      final vm = c.read(chuDeProvider.notifier);
      expect(c.read(chuDeProvider), CheDoGiaoDien.theoHeThong);
      vm.xoayVong();
      expect(c.read(chuDeProvider), CheDoGiaoDien.sang);
      vm.xoayVong();
      expect(c.read(chuDeProvider), CheDoGiaoDien.toi);
      vm.xoayVong();
      expect(c.read(chuDeProvider), CheDoGiaoDien.theoHeThong);
    });

    test('dat không đổi gì khi chọn lại đúng chế độ đang dùng', () {
      final c = dung();
      final vm = c.read(chuDeProvider.notifier);
      vm.dat(CheDoGiaoDien.toi);
      vm.dat(CheDoGiaoDien.toi);
      expect(c.read(chuDeProvider), CheDoGiaoDien.toi);
    });
  });
}
