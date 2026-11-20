import 'package:material_ui/material_ui.dart';
import 'package:flutter_academy/models/bo_loc.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';
import 'package:flutter_academy/widgets/thanh_loc.dart';
import 'package:flutter_academy/widgets/trang_thai.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiểm thử giao diện, cố ý giữ ở mức tối thiểu.
///
/// Phần lớn giá trị của bộ kiểm thử nằm ở các tệp trước: logic thuần, chạy
/// trong mili giây, không bao giờ "lúc xanh lúc đỏ". Kiểm thử widget chậm
/// hơn hàng trăm lần và dễ hỏng mỗi khi đổi bố cục, nên chỉ dùng cho những
/// thứ **chỉ có thể** kiểm bằng cách dựng widget thật.
///
/// `ThanhLoc` là ví dụ đúng: nó không phụ thuộc Riverpod lẫn go_router (nhận
/// bộ lọc vào, gọi `khiDoi` ra), nên dựng nó trong kiểm thử chỉ cần một
/// `MaterialApp`. Chính vì widget được thiết kế như vậy mà nó kiểm thử được.
void main() {
  Future<void> dung(
    WidgetTester tester, {
    required BoLoc boLoc,
    required void Function(BoLoc) khiDoi,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThanhLoc(
              boLoc: boLoc,
              danhMuc: const ['Web', 'Dữ liệu'],
              khiDoi: khiDoi,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('hiện đủ chip mức độ và danh mục', (tester) async {
    await dung(tester, boLoc: BoLoc.macDinh, khiDoi: (_) {});

    expect(find.text('Miễn phí'), findsOneWidget);
    for (final m in MucDo.values) {
      expect(find.text(m.nhan), findsOneWidget);
    }
    expect(find.text('Web'), findsOneWidget);
    expect(find.text('Dữ liệu'), findsOneWidget);
  });

  testWidgets('chưa lọc gì thì không có nút xoá bộ lọc', (tester) async {
    await dung(tester, boLoc: BoLoc.macDinh, khiDoi: (_) {});
    expect(find.text('Xoá bộ lọc'), findsNothing);
  });

  testWidgets('bấm chip danh mục gọi khiDoi với bộ lọc mới', (tester) async {
    BoLoc? nhan;
    await dung(tester, boLoc: BoLoc.macDinh, khiDoi: (b) => nhan = b);

    await tester.tap(find.text('Web'));
    await tester.pump();

    expect(nhan, isNotNull);
    expect(nhan!.danhMuc, 'Web');
  });

  testWidgets('bấm lại chip đang chọn thì bỏ lọc', (tester) async {
    BoLoc? nhan;
    await dung(
      tester,
      boLoc: const BoLoc(danhMuc: 'Web'),
      khiDoi: (b) => nhan = b,
    );

    await tester.tap(find.text('Web'));
    await tester.pump();

    expect(nhan, isNotNull);
    expect(nhan!.danhMuc, isNull);
  });

  testWidgets('đang lọc thì hiện nút xoá bộ lọc, bấm vào là về mặc định',
      (tester) async {
    BoLoc? nhan;
    await dung(
      tester,
      boLoc: const BoLoc(chiMienPhi: true),
      khiDoi: (b) => nhan = b,
    );

    final nut = find.text('Xoá bộ lọc');
    expect(nut, findsOneWidget);
    await tester.tap(nut);
    await tester.pump();
    expect(nhan, BoLoc.macDinh);
  });

  testWidgets('KhoiRong hiện tiêu đề, mô tả và nút hành động', (tester) async {
    var bam = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KhoiRong(
            bieuTuong: Icons.search_off,
            tieuDe: 'Không có kết quả',
            moTa: 'Thử bỏ bớt điều kiện lọc.',
            hanhDong: FilledButton(
              onPressed: () => bam++,
              child: const Text('Xoá bộ lọc'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Không có kết quả'), findsOneWidget);
    expect(find.text('Thử bỏ bớt điều kiện lọc.'), findsOneWidget);
    await tester.tap(find.text('Xoá bộ lọc'));
    expect(bam, 1);
  });
}
