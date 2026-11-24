import 'package:flutter_academy/models/don_nap_coin.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/models/vi_coin.dart';
import 'package:flutter_academy/screens/nap_coin_screen.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_academy/viewmodels/vi_coin_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'kho_gia_lap.dart';

class _ViCoinGiaLap extends ViCoinVM {
  final cacGoiDaXacNhan = <String>[];

  @override
  Future<ViCoin?> build() async => null;

  @override
  Future<Uri?> taoPhienNap(String packageId, {String? orderId}) async {
    cacGoiDaXacNhan.add(packageId);
    return null;
  }
}

void main() {
  testWidgets('chọn gói cho thấy giá và chỉ tạo đơn khi xác nhận', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final vi = _ViCoinGiaLap();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          khoNguoiDungProvider.overrideWithValue(
            KhoNguoiDungGiaLap(
              duLieu: const NguoiDung(
                email: 'nap@example.test',
                hoTen: 'Học viên',
              ),
            ),
          ),
          viCoinProvider.overrideWith(() => vi),
          donNapGanNhatProvider.overrideWith((ref) async => null),
          danhSachGoiNapProvider.overrideWith(
            (ref) async => const [
              GoiNapCoin(
                id: 'pkg_50',
                coinAmount: 50,
                ethAmount: '0.005',
                name: '50 Coin',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const Scaffold(body: NapCoinScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(vi.cacGoiDaXacNhan, isEmpty);
    expect(find.text('Xác nhận thanh toán'), findsNothing);
    await tester.tap(find.text('50 Coin · 0.005 ETH'));
    await tester.pumpAndSettle();
    expect(find.text('Nhận 50 Coin trong ứng dụng'), findsOneWidget);
    expect(
      find.textContaining('0.005 ETH thử nghiệm + phí mạng'),
      findsOneWidget,
    );
    expect(vi.cacGoiDaXacNhan, isEmpty);
    await tester.ensureVisible(find.text('Xác nhận thanh toán'));
    await tester.tap(find.text('Xác nhận thanh toán'));
    await tester.pumpAndSettle();
    expect(vi.cacGoiDaXacNhan, ['pkg_50']);
    expect(tester.takeException(), isNull);
  });
}
