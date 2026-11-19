import 'package:flutter_academy/data/kho_du_lieu.dart';
import 'package:flutter_academy/models/chuoi_hoc.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'kho_gia_lap.dart';

class _KhoDongBoGiaLap implements KhoDongBoChuoiHoc {
  final Map<String, ChuoiHoc> cacChuoi = {};
  String? taiKhoanCu;
  final List<ChuoiHoc> cacLanLuu = [];

  _KhoDongBoGiaLap({String? email, ChuoiHoc? chuoi}) : taiKhoanCu = email {
    if (email != null && chuoi != null) cacChuoi[email] = chuoi;
  }

  @override
  Future<ChuoiHoc> layChuoiHoc(
    String email, {
    required ChuoiHoc duLieuCucBo,
  }) async {
    final trenMayChu = cacChuoi[email];
    if (trenMayChu != null) return trenMayChu;
    final duLieuNhap = taiKhoanCu == null || taiKhoanCu == email
        ? duLieuCucBo
        : const ChuoiHoc();
    await luuChuoiHoc(email, duLieuNhap);
    return duLieuNhap;
  }

  @override
  Future<void> luuChuoiHoc(String email, ChuoiHoc chuoiHoc) async {
    cacChuoi[email] = chuoiHoc;
    taiKhoanCu = email;
    cacLanLuu.add(chuoiHoc);
  }
}

void main() {
  ProviderContainer dungContainer({
    required KhoChuoiHocGiaLap khoCucBo,
    required _KhoDongBoGiaLap khoMayChu,
    String email = 'hoc-vien@example.test',
  }) {
    return ProviderContainer.test(
      overrides: [
        khoChuoiHocProvider.overrideWithValue(khoCucBo),
        khoNguoiDungProvider.overrideWithValue(
          KhoNguoiDungGiaLap(
            duLieu: NguoiDung(email: email, hoTen: 'Học viên'),
          ),
        ),
        khoDongBoChuoiHocProvider.overrideWithValue(khoMayChu),
      ],
    );
  }

  test('tải streak tài khoản và cập nhật cache cục bộ', () async {
    final streakMayChu = ChuoiHoc(
      chuoiHienTai: 3,
      chuoiDaiNhat: 6,
      ngayHocGanNhat: ChuoiHoc.dinhDangNgay(DateTime.now()),
      tongXp: 150,
    );
    final khoCucBo = KhoChuoiHocGiaLap();
    final khoMayChu = _KhoDongBoGiaLap(
      email: 'hoc-vien@example.test',
      chuoi: streakMayChu,
    );
    final container = dungContainer(khoCucBo: khoCucBo, khoMayChu: khoMayChu);

    expect(await container.read(chuoiHocProvider.future), streakMayChu);
    expect(khoCucBo.chuoi, isNot(streakMayChu));
  });

  test('khởi tạo tài khoản mới từ dữ liệu Hive hiện có', () async {
    final streakCucBo = ChuoiHoc(
      chuoiHienTai: 2,
      chuoiDaiNhat: 4,
      ngayHocGanNhat: ChuoiHoc.dinhDangNgay(DateTime.now()),
      tongXp: 80,
    );
    final khoCucBo = KhoChuoiHocGiaLap(chuoi: streakCucBo);
    final khoMayChu = _KhoDongBoGiaLap();
    final container = dungContainer(khoCucBo: khoCucBo, khoMayChu: khoMayChu);

    expect(await container.read(chuoiHocProvider.future), streakCucBo);
    expect(khoMayChu.cacChuoi['hoc-vien@example.test'], streakCucBo);
    expect(khoMayChu.cacLanLuu, [streakCucBo]);
  });

  test('đẩy trạng thái mới lên máy chủ khi ghi nhận học', () async {
    final homQua = DateTime.now().subtract(const Duration(days: 1));
    final streakBanDau = ChuoiHoc(
      chuoiHienTai: 2,
      chuoiDaiNhat: 2,
      ngayHocGanNhat: ChuoiHoc.dinhDangNgay(homQua),
      tongXp: 30,
    );
    final khoCucBo = KhoChuoiHocGiaLap();
    final khoMayChu = _KhoDongBoGiaLap(
      email: 'hoc-vien@example.test',
      chuoi: streakBanDau,
    );
    final container = dungContainer(khoCucBo: khoCucBo, khoMayChu: khoMayChu);
    await container.read(chuoiHocProvider.future);

    await container
        .read(chuoiHocProvider.notifier)
        .ghiNhanHocTap(giayHocThem: 600);

    final streakDuocLuu = khoMayChu.cacChuoi['hoc-vien@example.test']!;
    expect(streakDuocLuu.chuoiHienTai, 3);
    expect(streakDuocLuu.tongXp, greaterThan(streakBanDau.tongXp));
    expect(khoMayChu.cacLanLuu, hasLength(1));
  });

  test('không nhập streak cục bộ của tài khoản khác', () async {
    final streakCucBo = ChuoiHoc(
      chuoiHienTai: 8,
      chuoiDaiNhat: 8,
      ngayHocGanNhat: ChuoiHoc.dinhDangNgay(DateTime.now()),
    );
    final khoCucBo = KhoChuoiHocGiaLap(chuoi: streakCucBo);
    final khoMayChu = _KhoDongBoGiaLap(email: 'tai-khoan-a@example.test');
    final container = dungContainer(
      khoCucBo: khoCucBo,
      khoMayChu: khoMayChu,
      email: 'tai-khoan-b@example.test',
    );

    expect(await container.read(chuoiHocProvider.future), const ChuoiHoc());
    expect(khoMayChu.cacChuoi['tai-khoan-b@example.test'], const ChuoiHoc());
  });
}
