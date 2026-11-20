import 'package:material_ui/material_ui.dart';

import '../models/dinh_dang.dart' as dd;

/// Dãy sao đánh giá.
///
/// Làm tròn về nửa sao chứ không vẽ sao đầy một phần: mắt không phân biệt
/// được 4,3 với 4,4 sao, mà vẽ chính xác thì tốn gấp ba lượng mã.
class SaoDanhGia extends StatelessWidget {
  final double diem;
  final int soLuot;
  final double coChu;

  const SaoDanhGia({
    super.key,
    required this.diem,
    required this.soLuot,
    this.coChu = 13,
  });

  @override
  Widget build(BuildContext context) {
    if (soLuot == 0) return const SizedBox.shrink();
    final mau = Theme.of(context).colorScheme;
    final nuaSao = (diem * 2).round(); // 0..10
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            nuaSao >= i * 2
                ? Icons.star_rounded
                : (nuaSao == i * 2 - 1
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: coChu + 3,
            color: const Color(0xFFE8A33D),
          ),
        const SizedBox(width: 6),
        Text(
          '${dd.diem(diem)} (${dd.soGon(soLuot)})',
          style: TextStyle(fontSize: coChu, color: mau.onSurfaceVariant),
        ),
      ],
    );
  }
}
