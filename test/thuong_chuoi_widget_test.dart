import 'dart:async';

import 'package:flutter_academy/data/kho_thuong_chuoi.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_academy/viewmodels/thuong_chuoi_vm.dart';
import 'package:flutter_academy/widgets/the_coin_thuong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'kho_gia_lap.dart';

class _KhoVi implements KhoThuongChuoi {
  String trangThai = 'rejected';
  int soLanDoi = 0;
  bool gapLoi = false;
  bool daKetNoi = true;
  bool daXacMinh = true;
  int soNgay = 7;
  int soDu = 30;
  int soCho = 0;
  String? capMocBay = 'issued';
  Object? idDaNhan;
  int soLanNhan = 0;
  Completer<void>? choNhan;

  @override
  int soDangCho(String email) => soCho;

  @override
  Future<void> dongBo(String email) async {
    if (soCho == 0) return;
    soCho = 0;
    soNgay = 7;
    capMocBay = 'pending';
  }

  @override
  Future<void> ghiNhan(String email, String bai) async {
    soCho++;
  }

  @override
  Future<Map<String, dynamic>> yeuCau(
    String duongDan, {
    Map<String, Object?>? duLieu,
  }) async {
    if (duongDan == '/claim') {
      soLanNhan++;
      idDaNhan = duLieu?['awardId'];
      if (choNhan case final cho?) await cho.future;
      capMocBay = 'submitted';
    }
    if (duongDan == '/redeem') {
      soLanDoi++;
      trangThai = 'signing';
      return {'path': '/meta/vi#ma-thu-nghiem'};
    }
    if (duongDan == '/disconnect') {
      daKetNoi = false;
      return {};
    }
    if (gapLoi) throw const LoiThuongChuoi('Mất kết nối');
    return {
      'days': soNgay,
      'milestones': [
        {'day': 3, 'amount': 10, 'status': 'issued'},
        {'day': 7, 'amount': 20, 'status': capMocBay},
      ],
      'awards': [
        if (capMocBay != null)
          {
            'milestone': 7,
            'id': 'moc-7',
            'amount': 20,
            'status': capMocBay,
            'earnedAt': '2026-11-24',
          },
      ],
      'onChain': {
        'enabled': true,
        'connected': daKetNoi,
        'wallet': daXacMinh
            ? '0x0000000000000000000000000000000000000001'
            : null,
        'balance': daXacMinh ? soDu : null,
        'proOffer': {'amount': 30, 'days': 7},
        'redemption': {'status': trangThai},
      },
    };
  }
}

void main() {
  Future<void> dung(
    WidgetTester tester,
    _KhoVi kho, {
    TheCoinThuong the = const TheCoinThuong(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          khoNguoiDungProvider.overrideWithValue(
            KhoNguoiDungGiaLap(
              duLieu: const NguoiDung(
                email: 'hoc@example.test',
                hoTen: 'Học viên',
              ),
            ),
          ),
          khoThuongChuoiProvider.overrideWithValue(kho),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: the)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('thử lại đổi Pro sau khi ví từ chối và xem chờ xác nhận', (
    tester,
  ) async {
    final kho = _KhoVi();
    await dung(tester, kho);
    expect(
      find.text('Bạn đã từ chối yêu cầu. Có thể thử lại.'),
      findsOneWidget,
    );
    final nutDoi = find.text('Đổi 30 Coin lấy 7 ngày Pro');
    await tester.ensureVisible(nutDoi);
    await tester.tap(nutDoi);
    await tester.pumpAndSettle();
    expect(kho.soLanDoi, 1);
    expect(find.text('Đang chờ ký trong MetaMask.'), findsOneWidget);
    expect(find.text('Mở trang ký trong MetaMask'), findsOneWidget);
    kho.gapLoi = true;
    await tester.ensureVisible(find.text('Kiểm tra trạng thái'));
    await tester.tap(find.text('Kiểm tra trạng thái'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa kết nối được máy chủ. Hãy thử lại.'),
      findsOneWidget,
    );
    kho.gapLoi = false;
    kho.trangThai = 'confirming';
    await tester.ensureVisible(find.text('Kiểm tra trạng thái'));
    await tester.tap(find.text('Kiểm tra trạng thái'));
    await tester.pumpAndSettle();
    expect(find.text('Đã cập nhật Coin.'), findsOneWidget);
    expect(find.text('Đã gửi giao dịch. Đang chờ xác nhận.'), findsOneWidget);
    final nut = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Đổi 30 Coin lấy 7 ngày Pro'),
    );
    expect(nut.onPressed, isNull);
    await tester.ensureVisible(find.text('Ngắt kết nối ví Coin'));
    await tester.tap(find.text('Ngắt kết nối ví Coin'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối lại MetaMask'), findsOneWidget);
    expect(find.text('30 Coin'), findsOneWidget);
    expect(find.text('Đổi 30 Coin lấy 7 ngày Pro'), findsNothing);
    await tester.ensureVisible(find.text('Lịch sử nhận thưởng'));
    await tester.tap(find.text('Lịch sử nhận thưởng'));
    await tester.pumpAndSettle();
    final mucLichSu = find.text('+20 Coin · Mốc 7 ngày');
    expect(mucLichSu, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: mucLichSu, matching: find.byType(ListTile)),
        matching: find.textContaining('Đã nhận'),
      ),
      findsOneWidget,
    );
  }, variant: const TargetPlatformVariant({TargetPlatform.windows}));

  testWidgets('đồng bộ mốc 7 và tự cập nhật số dư khi Hardhat xác nhận', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final kho = _KhoVi()
      ..soNgay = 6
      ..soDu = 10
      ..capMocBay = null;
    await dung(tester, kho, the: const TheCoinThuong(hienVi: false));
    expect(find.text('10 Coin'), findsOneWidget);
    final ref = ProviderScope.containerOf(
      tester.element(find.byType(TheCoinThuong)),
    );
    await ref
        .read(dongBoThuongProvider.notifier)
        .ghiNhan('hoc@example.test', 'flutter-nhap-mon/b2');
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã đạt chuỗi 7 ngày!'), findsOneWidget);
    expect(find.text('Mốc 7 ngày · Có thể nhận'), findsOneWidget);
    expect(find.text('10 Coin'), findsOneWidget);
    expect(kho.idDaNhan, isNull);
    final nutNhan = find.text('Nhận 20 Coin · Mốc 7 ngày');
    await tester.ensureVisible(nutNhan);
    kho.choNhan = Completer<void>();
    await tester.tap(nutNhan);
    await tester.tap(nutNhan);
    await tester.pump();
    expect(kho.soLanNhan, 1);
    expect(find.text('Nhận thưởng thành công.'), findsNothing);
    kho.choNhan!.complete();
    await tester.pumpAndSettle();
    expect(kho.idDaNhan, 'moc-7');
    expect(find.text('Mốc 7 ngày · Chờ xác nhận trên Hardhat'), findsOneWidget);

    kho.capMocBay = 'issued';
    kho.soDu = 30;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('30 Coin'), findsOneWidget);
    expect(ref.read(soDuCoinProvider), 30);
    expect(find.text('Mốc 7 ngày · Đã nhận'), findsOneWidget);
    expect(find.text('Nhận thưởng thành công.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiện khoản chờ xác minh ví cùng mốc đã đạt', (tester) async {
    final kho = _KhoVi()
      ..daKetNoi = false
      ..daXacMinh = false
      ..capMocBay = 'pending';
    await dung(tester, kho);
    expect(find.text('20 Coin chờ xác minh ví MetaMask.'), findsOneWidget);
    expect(find.text('Mốc 7 ngày · Chờ xác minh ví'), findsOneWidget);
    expect(find.text('Kết nối MetaMask'), findsOneWidget);
    expect(find.text('Đổi 30 Coin lấy 7 ngày Pro'), findsNothing);
  });
}
