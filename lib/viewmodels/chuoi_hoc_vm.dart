import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../models/chuoi_hoc.dart';
import '../models/huy_hieu.dart';
import 'providers.dart';

/// Quản lý trạng thái Chuỗi học tập, Khiên Freeze, Cấp độ và Điểm kinh nghiệm (XP).
///
/// Sử dụng `AsyncNotifier` để nạp dữ liệu bất đồng bộ từ Hive và hỗ trợ
/// cập nhật lạc quan (optimistic UI) cho trải nghiệm người dùng mượt mà trên web.
class ChuoiHocVM extends AsyncNotifier<ChuoiHoc> {
  Future<void> _hangDoi = Future.value();

  @override
  Future<ChuoiHoc> build() async {
    final lanTai = ref;
    final khoDongBo = lanTai.watch(khoDongBoChuoiHocProvider);
    final phien = lanTai.watch(phienProvider.future);
    final nhatKyDemo = lanTai.watch(nhatKyDemoProvider.future);
    final email = (await phien)?.email;
    if (!_conPhien(lanTai, email)) return const ChuoiHoc();
    final kho = lanTai.watch(khoChuoiHocProvider);
    final cucBo = await kho.lay();
    var duLieu = cucBo;
    if (email != null && khoDongBo != null && _conPhien(lanTai, email)) {
      try {
        duLieu = await khoDongBo.layChuoiHoc(email, duLieuCucBo: cucBo);
      } on Exception {
        // Dùng bản cục bộ của chính tài khoản khi chưa đồng bộ được.
      }
    }
    final cacNgayDemo = (await nhatKyDemo).values.toList()
      ..sort((a, b) => a.ngay.compareTo(b.ngay));
    if (!_conPhien(lanTai, email)) return const ChuoiHoc();

    final canKhoiTaoDemo =
        cacNgayDemo.isNotEmpty &&
        duLieu.tongXp == 0 &&
        duLieu.danhSachHuyHieu.isEmpty &&
        duLieu.cacNgayFreezeDaDung.isEmpty &&
        (duLieu.ngayHocGanNhat == null ||
            (duLieu.ngayHocGanNhat == cacNgayDemo.last.ngay &&
                duLieu.chuoiDaiNhat == cacNgayDemo.length));
    if (canKhoiTaoDemo) {
      duLieu = ChuoiHoc(mucTieuPhutMoiNgay: duLieu.mucTieuPhutMoiNgay);
      for (final ngay in cacNgayDemo.where((nk) => nk.datDieuKienStreak)) {
        duLieu = duLieu.ghiNhanHocHopLe(
          DateTime.parse(ngay.ngay),
          xpCongThem: ngay.xpNhanDuoc,
        );
        duLieu = _moHuyHieu(duLieu, ngay.ngay);
      }
    }

    final sauKiemTra = duLieu.kiemTraVaDungFreezeTuDong(ChuoiHoc.gioVietNam());
    if (sauKiemTra != duLieu) {
      for (final ngay in sauKiemTra.cacNgayFreezeDaDung.difference(
        duLieu.cacNgayFreezeDaDung,
      )) {
        final nk = await kho.layNhatKy(ngay);
        if (!_conPhien(lanTai, email)) return const ChuoiHoc();
        await kho.luuNhatKy(nk.danhDauDungFreeze());
      }
    }
    if (_conPhien(lanTai, email)) {
      if (canKhoiTaoDemo || sauKiemTra != duLieu) {
        try {
          await _luuChuoiHoc(lanTai, email, kho, sauKiemTra);
        } on Exception {
          // Nhật ký và trạng thái cục bộ vẫn dùng được khi ngoại tuyến.
        }
      } else if (sauKiemTra != cucBo) {
        await kho.luu(sauKiemTra);
      }
    }

    return sauKiemTra;
  }

  ChuoiHoc? get _hienTai => switch (state) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// Ghi nhận thời gian học, hoàn thành bài hoặc làm kiểm tra.
  ///
  /// - `giayHocThem`: số giây học video tích lũy thêm.
  /// - `maBaiHoc`: mã bài học hoàn thành (nếu có).
  /// - `maKhoaHoc`: mã khóa học đang học (nếu có).
  /// - `xpCongThem`: điểm XP nhận được từ hoạt động.
  /// - `moTaHoatDong`: mô tả ngắn (ví dụ: 'Học video 10 phút').
  Future<void> ghiNhanHocTap({
    int giayHocThem = 0,
    String? maBaiHoc,
    String? maKhoaHoc,
    int xpCongThem = 0,
    String? moTaHoatDong,
  }) {
    final lanTai = ref;
    final email = lanTai.read(emailHocVienProvider);
    final kho = lanTai.read(khoChuoiHocProvider);
    final ghi = _hangDoi.then((_) async {
      if (!_conPhien(lanTai, email)) return;
      final hienTai =
          _hienTai ?? await lanTai.read<Future<ChuoiHoc>>(chuoiHocProvider.future);
      if (!_conPhien(lanTai, email)) return;
      await _ghiNhan(
        lanTai,
        email,
        kho,
        hienTai,
        giayHocThem: giayHocThem,
        maBaiHoc: maBaiHoc,
        maKhoaHoc: maKhoaHoc,
        xpCongThem: xpCongThem,
        moTaHoatDong: moTaHoatDong,
      );
    });
    _hangDoi = ghi.catchError((Object _) {});
    return _hangDoi;
  }

  Future<void> _ghiNhan(
    Ref lanTai,
    String? email,
    KhoChuoiHoc kho,
    ChuoiHoc hienTai, {
    required int giayHocThem,
    required String? maBaiHoc,
    required String? maKhoaHoc,
    required int xpCongThem,
    required String? moTaHoatDong,
  }) async {
    final bayGio = ChuoiHoc.gioVietNam();
    final homNayStr = ChuoiHoc.dinhDangNgay(bayGio);

    // 1. Cập nhật nhật ký chi tiết của ngày hôm nay
    final nhatKyCu = await kho.layNhatKy(homNayStr);
    if (!_conPhien(lanTai, email)) return;

    // Tính toán XP thưởng tự động theo các tiêu chuẩn của hệ thống:
    var xpTongCong = xpCongThem;

    // Tự động thưởng 10 XP cho mỗi 5 phút (300 giây) tích lũy trong ngày
    final moc5pCu = nhatKyCu.thoiGianHocGiay ~/ 300;
    final moc5pMoi = (nhatKyCu.thoiGianHocGiay + giayHocThem) ~/ 300;
    if (moc5pMoi > moc5pCu) {
      xpTongCong += (moc5pMoi - moc5pCu) * 10;
    }

    // Tự động thưởng 20 XP khi hoàn thành mục tiêu hàng ngày (Daily Goal)
    final mucTieuGiay = hienTai.mucTieuPhutMoiNgay * 60;
    if (nhatKyCu.thoiGianHocGiay < mucTieuGiay &&
        (nhatKyCu.thoiGianHocGiay + giayHocThem) >= mucTieuGiay) {
      xpTongCong += 20;
    }

    final nhatKyMoi = nhatKyCu.ghiNhanThem(
      giayCongThem: giayHocThem,
      maBaiMoi: maBaiHoc == null || maKhoaHoc == null
          ? maBaiHoc
          : '$maKhoaHoc/$maBaiHoc',
      maKhoaHocMoi: maKhoaHoc,
      xpCongThem: xpTongCong,
      moTaHoatDong: moTaHoatDong,
    );
    await kho.luuNhatKy(nhatKyMoi);
    if (!_conPhien(lanTai, email)) return;

    // 2. Kiểm tra điều kiện duy trì/tăng Streak:
    // Đủ 10 phút (600 giây) hoặc hoàn thành ít nhất 1 bài học/bài kiểm tra
    ChuoiHoc chuoiMoi;
    if (nhatKyMoi.datDieuKienStreak) {
      chuoiMoi = hienTai.ghiNhanHocHopLe(bayGio, xpCongThem: xpTongCong);
    } else {
      // Chưa đủ điều kiện streak, chỉ tích luỹ XP
      chuoiMoi = hienTai.congXp(xpTongCong);
    }

    // Thưởng XP khi đạt các mốc Streak đặc biệt (7 ngày: +50 XP, 30 ngày: +200 XP)
    if (chuoiMoi.chuoiHienTai > hienTai.chuoiHienTai) {
      if (chuoiMoi.chuoiHienTai == 7) {
        chuoiMoi = chuoiMoi.congXp(50);
      } else if (chuoiMoi.chuoiHienTai == 30) {
        chuoiMoi = chuoiMoi.congXp(200);
      }
    }

    // 3. Tự động kiểm tra và trao các huy hiệu mốc Streak đạt được
    chuoiMoi = _moHuyHieu(chuoiMoi, homNayStr);

    // 4. Cập nhật lạc quan lên State
    state = AsyncData(chuoiMoi);

    try {
      await _luuChuoiHoc(lanTai, email, kho, chuoiMoi);
    } catch (_) {
      if (_conPhien(lanTai, email)) lanTai.invalidateSelf();
    }
  }

  /// Đổi điểm kinh nghiệm (XP) lấy Khiên Freeze bảo vệ chuỗi.
  Future<bool> muaFreeze({int giaXp = 100, int toiDa = 3}) async {
    final hienTai = _hienTai;
    if (hienTai == null) return false;

    final moi = hienTai.muaFreeze(giaXp: giaXp, toiDa: toiDa);
    if (moi == null) return false; // Không đủ điều kiện mua
    final lanTai = ref;
    final email = lanTai.read(emailHocVienProvider);
    final kho = lanTai.read(khoChuoiHocProvider);

    state = AsyncData(moi);
    try {
      await _luuChuoiHoc(lanTai, email, kho, moi);
      return true;
    } catch (_) {
      if (_conPhien(lanTai, email)) lanTai.invalidateSelf();
      return false;
    }
  }

  /// Cài đặt mục tiêu học tập hàng ngày (phút).
  Future<void> datMucTieu(int soPhut) async {
    final hienTai = _hienTai;
    if (hienTai == null) return;
    final lanTai = ref;
    final email = lanTai.read(emailHocVienProvider);
    final kho = lanTai.read(khoChuoiHocProvider);

    final moi = hienTai.datMucTieu(soPhut);
    state = AsyncData(moi);
    try {
      await _luuChuoiHoc(lanTai, email, kho, moi);
    } catch (_) {
      if (_conPhien(lanTai, email)) lanTai.invalidateSelf();
    }
  }

  ChuoiHoc _moHuyHieu(ChuoiHoc chuoi, String ngay) {
    final huyHieu = HuyHieu.kiemTraMoKhoa(
      soNgayStreak: chuoi.chuoiHienTai,
      cacMaDaDat: chuoi.danhSachHuyHieu,
      ngayHienTai: ngay,
    );
    for (final moc in huyHieu) {
      chuoi = chuoi.moKhoaHuyHieu(moc.ma);
    }
    return chuoi;
  }

  bool _conPhien(Ref lanTai, String? email) =>
      lanTai.mounted && lanTai.read(emailHocVienProvider) == email;

  Future<void> _luuChuoiHoc(
    Ref lanTai,
    String? email,
    KhoChuoiHoc kho,
    ChuoiHoc chuoiHoc,
  ) async {
    final khoDongBo = lanTai.read(khoDongBoChuoiHocProvider);
    await kho.luu(chuoiHoc);
    if (email != null && khoDongBo != null && _conPhien(lanTai, email)) {
      await khoDongBo.luuChuoiHoc(email, chuoiHoc);
    }
  }
}
