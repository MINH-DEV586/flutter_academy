import 'package:flutter/material.dart';

import '../models/khoa_hoc.dart';
import 'the_khoa_hoc.dart';

/// Dải khoá học cuộn ngang — mục `FeaturedSection` / "Recent Courses" của
/// sách.
///
/// Trên web, cuộn ngang là con dao hai lưỡi: chuột không có thao tác vuốt,
/// nên nếu chỉ có thể kéo bằng tay thì nhiều người sẽ không thấy phần bị
/// khuất. Vì vậy dải này luôn hiện thanh cuộn (`Scrollbar` với
/// `thumbVisibility`) — một chi tiết nhỏ mà bản gốc viết cho di động không
/// cần tới.
class MucNoiBat extends StatefulWidget {
  final String tieuDe;
  final String? moTa;
  final List<KhoaHoc> danhSach;
  final Map<String, int> tienDo;
  final Widget? hanhDong;

  const MucNoiBat({
    super.key,
    required this.tieuDe,
    required this.danhSach,
    this.moTa,
    this.tienDo = const {},
    this.hanhDong,
  });

  @override
  State<MucNoiBat> createState() => _MucNoiBatState();
}

class _MucNoiBatState extends State<MucNoiBat> {
  /// `Scrollbar` cần biết mình điều khiển vùng cuộn nào, nên phải tự tạo
  /// controller và tự huỷ trong `dispose`.
  final ScrollController _cuon = ScrollController();

  @override
  void dispose() {
    _cuon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tieuDe,
                    style: chu.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (widget.moTa != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.moTa!,
                      style: chu.bodyMedium
                          ?.copyWith(color: mau.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.hanhDong != null) widget.hanhDong!,
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          // 320 cho thẻ + 14 cho thanh cuộn nằm dưới.
          height: 334,
          child: Scrollbar(
            controller: _cuon,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _cuon,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: widget.danhSach.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final k = widget.danhSach[i];
                return SizedBox(
                  width: 300,
                  child: TheKhoaHoc(
                    khoaHoc: k,
                    phanTramTienDo: widget.tienDo[k.ma],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
