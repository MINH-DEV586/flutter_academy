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

  @override
  int soDangCho(String email) => 0;

  @override
  Future<void> dongBo(String email) async {}

  @override
  Future<void> ghiNhan(String email, String bai) async {}

  @override
  Future<Map<String, dynamic>> yeuCau(
    String duongDan, {
    Map<String, Object?>? duLieu,
  }) async {
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
      'days': 7,
      'milestones': <Object>[],
      'awards': [
        {
          'milestone': 7,
          'amount': 20,
          'status': 'issued',
          'earnedAt': '2026-11-24',
        },
      ],
      'onChain': {
        'enabled': true,
        'connected': daKetNoi,
        'wallet': '0x0000000000000000000000000000000000000001',
        'balance': 30,
        'proOffer': {'amount': 30, 'days': 7},
        'redemption': {'status': trangThai},
      },
    };
  }
}

void main() {
  testWidgets('thử lại đổi Pro sau khi ví từ chối và xem chờ xác nhận', (
    tester,
  ) async {
    final kho = _KhoVi();
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
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: TheCoinThuong())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn đã từ chối yêu cầu. Có thể thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Đổi 30 Coin thưởng lấy 7 ngày Pro'));
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
    expect(find.text('Đã cập nhật Coin thưởng.'), findsOneWidget);
    expect(find.text('Đã gửi giao dịch. Đang chờ xác nhận.'), findsOneWidget);
    final nut = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Đổi 30 Coin thưởng lấy 7 ngày Pro'),
    );
    expect(nut.onPressed, isNull);
    await tester.ensureVisible(find.text('Ngắt kết nối ví thưởng'));
    await tester.tap(find.text('Ngắt kết nối ví thưởng'));
    await tester.pumpAndSettle();
    expect(find.text('Kết nối lại MetaMask'), findsOneWidget);
    expect(find.text('30 Coin thưởng'), findsOneWidget);
    expect(find.text('Đổi 30 Coin thưởng lấy 7 ngày Pro'), findsNothing);
    await tester.ensureVisible(find.text('Lịch sử nhận thưởng'));
    await tester.tap(find.text('Lịch sử nhận thưởng'));
    await tester.pumpAndSettle();
    expect(find.text('+20 Coin · Mốc 7 ngày'), findsOneWidget);
    expect(find.textContaining('Đã nhận'), findsOneWidget);
  }, variant: const TargetPlatformVariant({TargetPlatform.windows}));
}
