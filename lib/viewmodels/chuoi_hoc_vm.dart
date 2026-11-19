import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../models/chuoi_hoc.dart';
import '../models/huy_hieu.dart';
import '../models/nhat_ky_ngay.dart';
import 'providers.dart';

/// Quản lý trạng thái Chuỗi học tập, Khiên Freeze, Cấp độ và Điểm kinh nghiệm (XP).
///
/// Sử dụng `AsyncNotifier` để nạp dữ liệu bất đồng bộ từ Hive và hỗ trợ
/// cập nhật lạc quan (optimistic UI) cho trải nghiệm người dùng mượt mà trên web.
class ChuoiHocVM extends AsyncNotifier<ChuoiHoc> {
  KhoChuoiHoc get _kho => ref.read(khoChuoiHocProvider);

  @override
  Future<ChuoiHoc> build() async {
    final duLieu = await _kho.lay();
    final bayGio = DateTime.now();

    // Tự động kiểm tra dùng Khiên Freeze hoặc phát hiện đứt chuỗi khi sang ngày mới
    final sauKiemTra = duLieu.kiemTraVaDungFreezeTuDong(bayGio);
    if (sauKiemTra != duLieu) {
      // Nếu có ngày dùng freeze, ghi nhận vào nhật ký ngày đó
      final ganNhatStr = duLieu.ngayHocGanNhat;
      if (ganNhatStr != null) {
        for (final ngayFreeze in sauKiemTra.cacNgayFreezeDaDung) {
          if (!duLieu.cacNgayFreezeDaDung.contains(ngayFreeze)) {
            final nk = await _kho.layNhatKy(ngayFreeze);
            await _kho.luuNhatKy(nk.danhDauDungFreeze());
          }
        }
      }
      await _kho.luu(sauKiemTra);
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
  }) async {
    final hienTai = _hienTai;
    if (hienTai == null) return;

    final bayGio = DateTime.now();
    final homNayStr = ChuoiHoc.dinhDangNgay(bayGio);

    // 1. Cập nhật nhật ký chi tiết của ngày hôm nay
    final nhatKyCu = await _kho.layNhatKy(homNayStr);
    final nhatKyMoi = nhatKyCu.ghiNhanThem(
      giayCongThem: giayHocThem,
      maBaiMoi: maBaiHoc,
      maKhoaHocMoi: maKhoaHoc,
      xpCongThem: xpCongThem,
      moTaHoatDong: moTaHoatDong,
    );
    await _kho.luuNhatKy(nhatKyMoi);

    // 2. Kiểm tra điều kiện duy trì/tăng Streak:
    // Đủ 10 phút (600 giây) hoặc hoàn thành ít nhất 1 bài học/bài kiểm tra
    ChuoiHoc chuoiMoi;
    if (nhatKyMoi.datDieuKienStreak) {
      chuoiMoi = hienTai.ghiNhanHocHopLe(bayGio, xpCongThem: xpCongThem);
    } else {
      // Chưa đủ điều kiện streak, chỉ tích luỹ XP
      chuoiMoi = hienTai.congXp(xpCongThem);
    }

    // 3. Tự động kiểm tra và trao các huy hiệu mốc Streak đạt được
    final huyHieuMoi = HuyHieu.kiemTraMoKhoa(
      soNgayStreak: chuoiMoi.chuoiHienTai,
      cacMaDaDat: chuoiMoi.danhSachHuyHieu,
      ngayHienTai: homNayStr,
    );
    if (huyHieuMoi.isNotEmpty) {
      for (final h in huyHieuMoi) {
        chuoiMoi = chuoiMoi.moKhoaHuyHieu(h.ma);
      }
    }

    // 4. Cập nhật lạc quan lên State
    state = AsyncData(chuoiMoi);

    try {
      await _kho.luu(chuoiMoi);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  /// Đổi điểm kinh nghiệm (XP) lấy Khiên Freeze bảo vệ chuỗi.
  Future<bool> muaFreeze({int giaXp = 100, int toiDa = 3}) async {
    final hienTai = _hienTai;
    if (hienTai == null) return false;

    final moi = hienTai.muaFreeze(giaXp: giaXp, toiDa: toiDa);
    if (moi == null) return false; // Không đủ điều kiện mua

    state = AsyncData(moi);
    try {
      await _kho.luu(moi);
      return true;
    } catch (_) {
      ref.invalidateSelf();
      return false;
    }
  }

  /// Cài đặt mục tiêu học tập hàng ngày (phút).
  Future<void> datMucTieu(int soPhut) async {
    final hienTai = _hienTai;
    if (hienTai == null) return;

    final moi = hienTai.datMucTieu(soPhut);
    state = AsyncData(moi);
    try {
      await _kho.luu(moi);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  /// Lấy danh sách nhật ký của toàn bộ các ngày trong tháng để hiển thị lên Lịch.
  Future<Map<String, NhatKyNgay>> layNhatKyThang(int nam, int thang) =>
      _kho.nhatKyTrongThang(nam, thang);

  /// Lấy nhật ký của một ngày cụ thể (YYYY-MM-DD).
  Future<NhatKyNgay> layNhatKyNgay(String ngay) => _kho.layNhatKy(ngay);
}
