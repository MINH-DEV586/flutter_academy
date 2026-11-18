import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class DangKyKhoaHocVM extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final nguoiDung = await ref.watch(phienProvider.future);
    if (nguoiDung == null) return const {};
    return ref.read(khoNguoiDungProvider).khoaDaDangKy();
  }

  Future<void> dangKy(String maKhoaHoc, {int? soTien}) async {
    final nguoiDung = ref.read(phienProvider).asData?.value;
    await ref
        .read(khoNguoiDungProvider)
        .dangKyKhoaHoc(maKhoaHoc, soTien: soTien);
    if (!ref.mounted || ref.read(phienProvider).asData?.value != nguoiDung) {
      return;
    }
    final hienTai = state.asData?.value;
    if (hienTai == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData({...hienTai, maKhoaHoc});
  }
}
