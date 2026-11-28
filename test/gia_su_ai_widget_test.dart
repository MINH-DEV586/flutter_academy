import 'dart:async';

import 'package:flutter_academy/data/kho_gia_su_ai.dart';
import 'package:flutter_academy/data/tai_lieu_bai_hoc.dart';
import 'package:flutter_academy/models/gia_su_ai.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/screens/bai_hoc_screen.dart';
import 'package:flutter_academy/viewmodels/gia_su_ai_vm.dart';
import 'package:flutter_academy/viewmodels/providers.dart';
import 'package:flutter_academy/widgets/gia_su_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'du_lieu_kiem_thu.dart';
import 'kho_gia_lap.dart';

class _KhoTutor implements KhoGiaSuAi {
  final daLuu = <HoiThoaiTutor, List<LuotHoiTutor>>{};
  final yeuCau = <StreamController<Map<String, dynamic>>>[];
  int daHuy = 0;

  @override
  List<LuotHoiTutor> doc(HoiThoaiTutor khoa) => daLuu[khoa] ?? [];

  @override
  Future<void> luu(HoiThoaiTutor khoa, List<LuotHoiTutor> lichSu) async {
    daLuu[khoa] = lichSu;
  }

  @override
  Uri diaChiNguon(String duongDan) => Uri.parse(duongDan);

  @override
  Stream<Map<String, dynamic>> hoi({
    required HoiThoaiTutor khoa,
    required String cauHoi,
    required String mucDo,
    required Future<void> khiHuy,
  }) {
    final controller = StreamController<Map<String, dynamic>>();
    yeuCau.add(controller);
    unawaited(khiHuy.then((_) => daHuy++));
    return controller.stream;
  }
}

void main() {
  Future<void> dung(
    WidgetTester tester,
    _KhoTutor kho,
    ValueNotifier<String> bai,
    Size size, {
    Future<Map<String, TaiLieuBaiHoc>> Function()? taiLai,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          khoGiaSuAiProvider.overrideWithValue(kho),
          khoKhoaHocProvider.overrideWithValue(
            KhoKhoaHocGiaLap([kh(ma: 'flutter-nhap-mon', soBai: 2)]),
          ),
          khoTienDoProvider.overrideWithValue(KhoTienDoGiaLap()),
          khoNguoiDungProvider.overrideWithValue(
            KhoNguoiDungGiaLap(
              duLieu: const NguoiDung(
                email: 'hoc@example.test',
                hoTen: 'Người học',
              ),
            ),
          ),
          laThanhVienProProvider.overrideWithValue(false),
          taiLieuBaiHocProvider.overrideWith(
            (ref) async => taiLai != null
                ? await taiLai()
                : const {
                    'flutter-nhap-mon/b1': TaiLieuBaiHoc(
                      noiDung: 'Nội dung 1',
                      code: 'code 1',
                    ),
                    'flutter-nhap-mon/b2': TaiLieuBaiHoc(
                      noiDung: 'Nội dung 2',
                      code: 'code 2',
                    ),
                  },
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(size.width < 720 ? 1.5 : 1),
              viewInsets: EdgeInsets.only(bottom: size.width < 720 ? 180 : 0),
            ),
            child: child!,
          ),
          home: ValueListenableBuilder(
            valueListenable: bai,
            builder: (context, value, _) =>
                BaiHocScreen(maKhoaHoc: 'flutter-nhap-mon', maBaiHoc: value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nutMo = tester.getSize(find.byTooltip('Mở Gia sư AI'));
    expect(nutMo.width, greaterThanOrEqualTo(48));
    expect(nutMo.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Mở Gia sư AI'));
    await tester.pumpAndSettle();
  }

  Future<void> gui(WidgetTester tester, String cauHoi) async {
    await tester.enterText(find.byType(TextField), cauHoi);
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump();
  }

  testWidgets('màn lớn giữ bài và bỏ phản hồi cũ khi đổi bài', (tester) async {
    final kho = _KhoTutor();
    final bai = ValueNotifier('b1');
    await dung(tester, kho, bai, const Size(1440, 900));
    expect(tester.getTopLeft(find.byType(GiaSuAi)).dx, greaterThan(900));
    expect(find.text('Nội dung 1'), findsOneWidget);
    await gui(tester, 'Giải thích giúp mình');
    kho.yeuCau.single.add({'loai': 'phan', 'text': 'Đoạn đang nhận'});
    await tester.pump();
    expect(find.text('Đoạn đang nhận'), findsOneWidget);
    bai.value = 'b2';
    await tester.pumpAndSettle();
    expect(kho.daHuy, 1);
    kho.yeuCau.single.add({'loai': 'phan', 'text': 'Đoạn đến muộn'});
    await tester.pump();
    expect(find.text('Đoạn đến muộn'), findsNothing);
    expect(
      find.text('Bạn muốn hiểu thêm điều gì trong bài này?'),
      findsOneWidget,
    );
  });

  testWidgets('điện thoại đóng, mở lại và thử lại từ lịch sử', (tester) async {
    final kho = _KhoTutor();
    await dung(tester, kho, ValueNotifier('b1'), const Size(360, 740));
    expect(tester.getSize(find.byType(GiaSuAi)).width, 360);
    expect(find.byTooltip('Mở Gia sư AI'), findsNothing);
    expect(find.byTooltip('Mở Gia sư AI', skipOffstage: false), findsOneWidget);
    for (final nhan in ['Đóng Gia sư AI', 'Gửi câu hỏi']) {
      final nut = tester.getSize(find.byTooltip(nhan));
      expect(nut.width, greaterThanOrEqualTo(48));
      expect(nut.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
    await gui(tester, 'Câu hỏi đang gửi');
    kho.yeuCau.single.add({'loai': 'batDau', 'demo': false});
    kho.yeuCau.single.add({'loai': 'cho'});
    await tester.pump();
    expect(find.text('Đang trả lời…'), findsOneWidget);
    kho.yeuCau.single.add({'loai': 'phan', 'text': 'Giữ câu trả lời dở'});
    await tester.pump();
    await tester.tap(find.byTooltip('Đóng Gia sư AI'));
    await tester.pumpAndSettle();
    expect(kho.daHuy, 1);
    await tester.tap(find.byTooltip('Mở Gia sư AI'));
    await tester.pumpAndSettle();
    expect(find.text('Giữ câu trả lời dở'), findsOneWidget);
    await tester.tap(find.text('Thử trả lời lại'));
    await tester.pump();
    expect(kho.yeuCau, hasLength(2));
    kho.yeuCau.last.addError(const LoiTutor('Bạn đã hết lượt hỏi hôm nay.'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã hết lượt hỏi hôm nay.'), findsOneWidget);
    expect(find.text('Giữ câu trả lời dở'), findsOneWidget);
  });

  testWidgets('vẫn mở Tutor trên điện thoại khi tải tài liệu lỗi', (
    tester,
  ) async {
    var soLanTai = 0;
    await dung(
      tester,
      _KhoTutor(),
      ValueNotifier('b1'),
      const Size(360, 740),
      taiLai: () async {
        if (soLanTai++ == 0) throw StateError('Mất kết nối');
        return const {
          'flutter-nhap-mon/b1': TaiLieuBaiHoc(noiDung: 'Tài liệu', code: ''),
        };
      },
    );
    expect(find.text('Không tải được tài liệu bài học.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn muốn hiểu thêm điều gì trong bài này?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
