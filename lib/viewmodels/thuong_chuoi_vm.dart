import 'dart:async';

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
  final _yeuCauNhan = <(String, String)>{};
  Timer? _henGio;

  @override
  Future<TrangThaiThuongChuoi?> build() async {
    final lanTai = ref;
    final email = lanTai.watch(emailHocVienProvider);
    final kho = lanTai.watch(khoThuongChuoiProvider);
    if (email == null || kho == null) return null;
    lanTai.onDispose(() => _henGio?.cancel());
    final tinhTrang = TrangThaiThuongChuoi.tuJson(await kho.yeuCau(''));
    if (_conPhien(lanTai, email)) _theoDoi(lanTai, tinhTrang);
    return tinhTrang;
  }

  bool _conPhien(Ref lanTai, String email) =>
      lanTai.mounted && lanTai.read(emailHocVienProvider) == email;

  void _theoDoi(Ref lanTai, TrangThaiThuongChuoi tinhTrang) {
    if (tinhTrang.doiPro == 'completed') lanTai.invalidate(thanhVienProvider);
    _henGio?.cancel();
    if ((tinhTrang.dangCapCoin || tinhTrang.doiPro == 'confirming') &&
        tinhTrang.loiMang == null) {
      _henGio = Timer(const Duration(seconds: 3), lanTai.invalidateSelf);
    }
  }

  Future<void> nhanCoin(String id) async {
    final lanTai = ref;
    final email = lanTai.read(emailHocVienProvider);
    final kho = lanTai.read(khoThuongChuoiProvider);
    if (email == null || kho == null) {
      throw const LoiThuongChuoi('Đăng nhập để nhận Coin.');
    }
    final yeuCau = (email, id);
    if (!_yeuCauNhan.add(yeuCau)) return;
    try {
      final tinhTrang = TrangThaiThuongChuoi.tuJson(
        await kho.yeuCau('/claim', duLieu: {'awardId': id}),
      );
      if (_conPhien(lanTai, email)) {
        _theoDoi(lanTai, tinhTrang);
        state = AsyncData(tinhTrang);
      } else if (_conPhien(ref, email)) {
        ref.invalidateSelf();
      }
    } catch (_) {
      if (_conPhien(lanTai, email)) lanTai.invalidateSelf();
      rethrow;
    } finally {
      _yeuCauNhan.remove(yeuCau);
    }
  }

  Future<Uri> moVi({required bool doiPro, String? packageId}) async {
    final kho = ref.read(khoThuongChuoiProvider);
    if (kho == null) throw const LoiThuongChuoi('Chưa cấu hình ví Coin.');
    final kq = await kho.yeuCau(
      doiPro ? '/redeem' : '/link',
      duLieu: {if (doiPro && packageId != null) 'packageId': packageId},
    );
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

final soDuCoinProvider = Provider<int?>(
  (ref) => ref.watch(trangThaiThuongProvider).asData?.value?.soDu,
);

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
      ref.invalidate(trangThaiThuongProvider);
    }
  }
}
