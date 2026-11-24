import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cau_hinh/may_chu.dart';
import '../data/kho_thuong_chuoi.dart';
import '../models/thuong_chuoi.dart';
import 'providers.dart';

final khoThuongChuoiProvider = Provider<KhoThuongChuoi?>((ref) => null);
final dongBoThuongProvider = NotifierProvider<DongBoThuongVM, int>(
  DongBoThuongVM.new,
);

final trangThaiThuongProvider =
    AsyncNotifierProvider.autoDispose<ThuongChuoiVM, TrangThaiThuongChuoi?>(
      ThuongChuoiVM.new,
      retry: (_, _) => null,
    );

class ThuongChuoiVM extends AsyncNotifier<TrangThaiThuongChuoi?> {
  @override
  Future<TrangThaiThuongChuoi?> build() async {
    final email = ref.watch(phienProvider).asData?.value?.email;
    final kho = ref.watch(khoThuongChuoiProvider);
    if (email == null || kho == null) return null;
    final tinhTrang = TrangThaiThuongChuoi.tuJson(await kho.yeuCau(''));
    if (ref.mounted && tinhTrang.doiPro == 'completed') {
      ref.invalidate(thanhVienProvider);
    }
    return tinhTrang;
  }

  Future<Uri> moVi({required bool doiPro}) async {
    final kho = ref.read(khoThuongChuoiProvider);
    if (kho == null) throw const LoiThuongChuoi('Chưa cấu hình Coin thưởng.');
    final kq = await kho.yeuCau(doiPro ? '/redeem' : '/link', duLieu: {});
    final path = Uri.parse(kq['path'] as String);
    if (path.hasAuthority || path.path != '/meta/vi' || !path.hasFragment) {
      throw const LoiThuongChuoi('Đường dẫn ký ví không hợp lệ.');
    }
    return Uri.parse(MayChu.api).resolveUri(path);
  }

  Future<void> ngatKetNoiVi() async {
    final kho = ref.read(khoThuongChuoiProvider);
    if (kho == null) return;
    await kho.yeuCau('/disconnect', duLieu: {});
    if (ref.mounted) ref.invalidateSelf();
  }
}

class DongBoThuongVM extends Notifier<int> {
  @override
  int build() {
    final kho = ref.watch(khoThuongChuoiProvider);
    final email = ref.watch(phienProvider).asData?.value?.email;
    if (email == null || kho == null) return 0;
    return kho.soDangCho(email);
  }

  Future<void> ghiNhan(String email, String bai) async {
    final kho = ref.read(khoThuongChuoiProvider);
    if (kho == null) return;
    await kho.ghiNhan(email, bai);
    if (!ref.mounted || ref.read(phienProvider).asData?.value?.email != email) {
      return;
    }
    state = kho.soDangCho(email);
    await thuLai();
  }

  Future<void> thuLai() async {
    final kho = ref.read(khoThuongChuoiProvider);
    final email = ref.read(phienProvider).asData?.value?.email;
    if (email == null || kho == null || kho.soDangCho(email) == 0) return;
    try {
      await kho.dongBo(email);
    } catch (_) {
      // Sự kiện giữ nguyên trong Hive cho lần thử kế tiếp.
    }
    if (ref.mounted && ref.read(phienProvider).asData?.value?.email == email) {
      state = kho.soDangCho(email);
    }
  }
}
