import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tien_do.dart';
import 'providers.dart';
import 'thuong_chuoi_vm.dart';

/// Toàn bộ tiến độ học, gom trong một `Map` theo mã khoá học.
///
/// Vì sao một provider cho tất cả thay vì một provider cho mỗi khoá học:
/// trang "Khoá học của tôi" cần xem hết một lượt, mà toàn bộ dữ liệu này chỉ
/// vài kilobyte. Một nguồn dữ liệu thì không bao giờ có chuyện hai chỗ lệch
/// nhau.
///
/// `AsyncNotifier` (không phải `Notifier`) vì lần dựng đầu tiên phải đọc ổ
/// đĩa. `build` trả về `Future`, còn giao diện nhận `AsyncValue` nên buộc
/// phải xử lý đủ ba trạng thái: đang tải, lỗi, có dữ liệu.
class TienDoVM extends AsyncNotifier<Map<String, TienDo>> {
  @override
  Future<Map<String, TienDo>> build() async {
    final lanTai = ref;
    final phien = lanTai.watch(phienProvider.future);
    final demo = lanTai.watch(nhatKyDemoProvider.future);
    final email = (await phien)?.email;
    if (!lanTai.mounted || lanTai.read(emailHocVienProvider) != email) {
      return const {};
    }
    final kho = lanTai.watch(khoTienDoProvider);
    final ds = await kho.tatCa();
    final macDinh = <String, Set<String>>{};
    for (final ngay in (await demo).values) {
      for (final ma in ngay.baiDaHoanThanh) {
        if (ma.split('/') case [final khoa, final bai]) {
          (macDinh[khoa] ??= {}).add(bai);
        }
      }
    }
    final bang = {
      for (final entry in macDinh.entries)
        entry.key: TienDo(maKhoaHoc: entry.key, baiDaXong: entry.value),
      for (final t in ds) t.maKhoaHoc: t,
    };
    for (final ma in macDinh.keys) {
      final tienDo = bang[ma]!;
      if (tienDo.baiDaXong.isEmpty && tienDo.baiDangXem == null) {
        bang.remove(ma);
      }
    }
    return bang;
  }

  /// Bảng hiện tại, hoặc null khi chưa tải xong.
  ///
  /// Dùng so khớp mẫu thay vì `state.value`: trình biên dịch bắt buộc xử lý
  /// nhánh chưa có dữ liệu, không quên được.
  Map<String, TienDo>? get _bang => switch (state) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// Bật/tắt trạng thái hoàn thành của một bài học.
  ///
  /// Cập nhật trạng thái TRƯỚC rồi mới ghi xuống Hive ("cập nhật lạc quan"):
  /// dấu tích đổi ngay khi bấm chứ không chờ ổ đĩa. Ghi hỏng thì nạp lại từ
  /// kho để giao diện quay về đúng sự thật.
  Future<void> daoTrangThaiBai(String maKhoaHoc, String maBai) async {
    final bang = _bang;
    if (bang == null) return;
    final lanTai = ref;
    final kho = lanTai.read(khoTienDoProvider);

    final cu = bang[maKhoaHoc] ?? TienDo(maKhoaHoc: maKhoaHoc);
    final moi = cu.daoTrangThai(maBai);
    state = AsyncData({...bang, maKhoaHoc: moi});

    final vuaHoanThanh = moi.daXong(maBai) && !cu.daXong(maBai);
    final email = !vuaHoanThanh || lanTai.read(khoThuongChuoiProvider) == null
        ? null
        : lanTai.read(emailHocVienProvider);
    final khoThuong = lanTai.read(khoThuongChuoiProvider);

    try {
      await kho.luu(moi);
    } catch (_) {
      if (lanTai.mounted) lanTai.invalidateSelf();
      return;
    }
    if (vuaHoanThanh && lanTai.mounted) {
      unawaited(
        lanTai
            .read(chuoiHocProvider.notifier)
            .ghiNhanHocTap(
              maKhoaHoc: maKhoaHoc,
              maBaiHoc: maBai,
              xpCongThem: 20,
              moTaHoatDong: 'Hoàn thành bài học',
            ),
      );
    }
    if (email != null && khoThuong != null) {
      unawaited(
        (lanTai.mounted
                ? lanTai
                      .read(dongBoThuongProvider.notifier)
                      .ghiNhan(email, '$maKhoaHoc/$maBai')
                : khoThuong.ghiNhan(email, '$maKhoaHoc/$maBai'))
            .catchError((Object _) {}),
      );
    }
  }

  /// Ghi nhớ bài đang xem dở, để nút "Học tiếp" biết nhảy về đâu.
  Future<void> danhDauDangXem(String maKhoaHoc, String maBai) async {
    final bang = _bang;
    if (bang == null) return;
    final lanTai = ref;
    final kho = lanTai.read(khoTienDoProvider);

    final cu = bang[maKhoaHoc] ?? TienDo(maKhoaHoc: maKhoaHoc);
    if (cu.baiDangXem == maBai) return;

    final moi = cu.danhDauDangXem(maBai);
    state = AsyncData({...bang, maKhoaHoc: moi});
    try {
      await kho.luu(moi);
    } catch (_) {
      if (lanTai.mounted) lanTai.invalidateSelf();
    }
  }

  /// Xoá sạch tiến độ của một khoá học.
  Future<void> datLai(String maKhoaHoc) async {
    final bang = _bang;
    if (bang == null) return;
    final lanTai = ref;
    final kho = lanTai.read(khoTienDoProvider);

    final moi = Map<String, TienDo>.from(bang)..remove(maKhoaHoc);
    state = AsyncData(moi);
    try {
      final demo = lanTai.read(nhatKyDemoProvider).asData?.value;
      if (demo?.values.any(
            (ngay) => ngay.khoaHocDaThamGia.contains(maKhoaHoc),
          ) ==
          true) {
        await kho.luu(TienDo(maKhoaHoc: maKhoaHoc));
      } else {
        await kho.xoa(maKhoaHoc);
      }
    } catch (_) {
      if (lanTai.mounted) lanTai.invalidateSelf();
    }
  }
}
