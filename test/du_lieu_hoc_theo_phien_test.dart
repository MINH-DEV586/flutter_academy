import 'dart:async';
import 'dart:io';

import 'package:flutter_academy/data/bo_chuyen_doi.dart';
import 'package:flutter_academy/data/kho_du_lieu.dart';
import 'package:flutter_academy/data/kho_hive.dart';
import 'package:flutter_academy/models/chuoi_hoc.dart';
import 'package:flutter_academy/models/nhat_ky_ngay.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/models/tien_do.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'kho_gia_lap.dart';

const _a = 'a@example.test';
const _b = 'b@example.test';
const _demo = 'demo@example.com';

class _KhoTienDoCham extends KhoTienDoGiaLap {
  final daGoi = Completer<void>();
  final ketQua = Completer<List<TienDo>>();

  @override
  Future<List<TienDo>> tatCa() {
    if (!daGoi.isCompleted) daGoi.complete();
    return ketQua.future;
  }
}

class _KhoNhatKyDemo implements KhoNhatKyDemo {
  _KhoNhatKyDemo(this.nhatKy);

  final List<NhatKyNgay> nhatKy;

  @override
  Future<List<NhatKyNgay>> layNhatKyDemo(String email) async =>
      email == _demo ? nhatKy : [];
}

void main() {
  test('Hive giữ tiến độ, nhật ký và chuỗi riêng cho A, B và khách', () async {
    final thuMuc = await Directory.systemTemp.createTemp('academy-phien-');
    Hive.init(thuMuc.path);
    dangKyBoChuyenDoi();
    final tienDo = await Hive.openBox<TienDo>('tien_do');
    final chuoi = await Hive.openBox<ChuoiHoc>('chuoi_hoc');
    final nhatKy = await Hive.openBox<NhatKyNgay>('nhat_ky_hoc');
    final ngay = ChuoiHoc.dinhDangNgay(ChuoiHoc.gioVietNam());
    const duLieuCu = TienDo(maKhoaHoc: 'du-lieu-cu', baiDaXong: {'b1'});
    await tienDo.put(duLieuCu.maKhoaHoc, duLieuCu);
    await chuoi.put('hien_tai', const ChuoiHoc(tongXp: 999));
    await nhatKy.put(ngay, NhatKyNgay(ngay: ngay, xpNhanDuoc: 999));

    final c = ProviderContainer(
      overrides: [
        khoNguoiDungProvider.overrideWithValue(
          KhoNguoiDungGiaLap(
            duLieu: const NguoiDung(email: _a, hoTen: 'A'),
          ),
        ),
        khoTienDoProvider.overrideWith(
          (ref) =>
              HiveKhoTienDo(tienDo, email: ref.watch(emailHocVienProvider)),
        ),
        khoChuoiHocProvider.overrideWith(
          (ref) => HiveKhoChuoiHoc(
            hopChuoiHoc: chuoi,
            hopNhatKy: nhatKy,
            email: ref.watch(emailHocVienProvider),
          ),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await Hive.close();
      await thuMuc.delete(recursive: true);
    });

    expect(await c.read(tienDoProvider.future), isEmpty);
    expect((await c.read(chuoiHocProvider.future)).tongXp, 0);
    await c.read(tienDoProvider.notifier).daoTrangThaiBai('flutter', 'b1');
    // Ghi thêm một hoạt động nối tiếp để chờ hàng đợi nhật ký của lần đánh dấu.
    await c.read(chuoiHocProvider.notifier).ghiNhanHocTap();
    expect(
      (await c.read(tienDoProvider.future))['flutter']?.daXong('b1'),
      isTrue,
    );
    expect((await c.read(nhatKyHomNayProvider.future)).baiDaHoanThanh, {
      'flutter/b1',
    });
    expect((await c.read(chuoiHocProvider.future)).tongXp, 20);

    final phien = c.read(phienProvider.notifier);
    expect(await phien.dangXuat(), isTrue);
    expect(await c.read(tienDoProvider.future), isEmpty);
    expect((await c.read(nhatKyHomNayProvider.future)).xpNhanDuoc, 0);
    await c.read(tienDoProvider.notifier).danhDauDangXem('thu-khach', 'b2');

    expect(await phien.dangNhap(email: _b, matKhau: 'kiem-thu'), isNull);
    expect(await c.read(tienDoProvider.future), isEmpty);
    expect((await c.read(chuoiHocProvider.future)).tongXp, 0);
    expect((await c.read(nhatKyHomNayProvider.future)).baiDaHoanThanh, isEmpty);

    expect(await phien.dangNhap(email: _a, matKhau: 'kiem-thu'), isNull);
    expect(
      (await c.read(tienDoProvider.future))['flutter']?.daXong('b1'),
      isTrue,
    );
    expect((await c.read(nhatKyHomNayProvider.future)).xpNhanDuoc, 20);
    expect((await c.read(chuoiHocProvider.future)).tongXp, 20);
    expect(tienDo.get('du-lieu-cu')?.baiDaXong, {'b1'});
    expect(chuoi.get('hien_tai')?.tongXp, 999);
  });

  test('đọc chậm của A không ghi đè tiến độ của B', () async {
    final khoA = _KhoTienDoCham();
    final c = ProviderContainer.test(
      overrides: [
        khoNguoiDungProvider.overrideWithValue(
          KhoNguoiDungGiaLap(
            duLieu: const NguoiDung(email: _a, hoTen: 'A'),
          ),
        ),
        khoTienDoProvider.overrideWith(
          (ref) =>
              ref.watch(emailHocVienProvider) == _a ? khoA : KhoTienDoGiaLap(),
        ),
      ],
    );
    final theoDoi = c.listen(tienDoProvider, (_, _) {});
    addTearDown(theoDoi.close);
    await khoA.daGoi.future;

    await c
        .read(phienProvider.notifier)
        .dangNhap(email: _b, matKhau: 'kiem-thu');
    expect(await c.read(tienDoProvider.future), isEmpty);
    khoA.ketQua.complete([
      const TienDo(maKhoaHoc: 'cua-a', baiDaXong: {'b1'}),
    ]);
    await c.pump();
    expect(c.read(tienDoProvider).requireValue, isEmpty);
  });

  test(
    'demo tính lại XP và huy hiệu từ sáu ngày, mở lại không cộng lần hai',
    () async {
      final homNay = ChuoiHoc.gioVietNam();
      final nhatKy = [
        for (var cach = 6; cach >= 1; cach--)
          NhatKyNgay(
            ngay: ChuoiHoc.dinhDangNgay(homNay.subtract(Duration(days: cach))),
            baiDaHoanThanh: const {'flutter-nhap-mon/b1'},
            khoaHocDaThamGia: const {'flutter-nhap-mon'},
            xpNhanDuoc: 20,
          ),
      ];
      final kho = KhoChuoiHocGiaLap(
        chuoi: ChuoiHoc(
          chuoiHienTai: 6,
          chuoiDaiNhat: 6,
          ngayHocGanNhat: nhatKy.last.ngay,
        ),
      );
      final c = ProviderContainer.test(
        overrides: [
          khoNguoiDungProvider.overrideWithValue(
            KhoNguoiDungGiaLap(
              duLieu: const NguoiDung(email: _demo, hoTen: 'Demo'),
            ),
          ),
          khoChuoiHocProvider.overrideWithValue(kho),
          khoTienDoProvider.overrideWithValue(KhoTienDoGiaLap()),
          khoNhatKyDemoProvider.overrideWithValue(_KhoNhatKyDemo(nhatKy)),
        ],
      );
      final chuoi = await c.read(chuoiHocProvider.future);
      expect(chuoi.chuoiHienTai, 6);
      expect(chuoi.tongXp, 120);
      expect(chuoi.danhSachHuyHieu, {'streak_3'});
      final td = (await c.read(tienDoProvider.future))['flutter-nhap-mon']!;
      expect(td.baiDaXong, {'b1'});
      final thang = (homNay.year, homNay.month);
      final trongThang = nhatKy.where(
        (nk) => DateTime.parse(nk.ngay).month == homNay.month,
      );
      expect(
        (await c.read(nhatKyThangProvider(thang).future)).keys,
        unorderedEquals(trongThang.map((nk) => nk.ngay)),
      );
      c.invalidate(chuoiHocProvider);
      expect(await c.read(chuoiHocProvider.future), chuoi);
      await c
          .read(chuoiHocProvider.notifier)
          .ghiNhanHocTap(
            maKhoaHoc: 'flutter-nhap-mon',
            maBaiHoc: 'b2',
            xpCongThem: 20,
          );
      final ngayBay = await c.read(chuoiHocProvider.future);
      expect(ngayBay.chuoiHienTai, 7);
      expect(ngayBay.danhSachHuyHieu, {'streak_3', 'streak_7'});
    },
  );
}
