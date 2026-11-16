import 'package:flutter/material.dart';

import '../cau_hinh/diem_ngat.dart';

/// Vỏ chung của một trang: cuộn dọc + lề hai bên theo khổ màn hình.
///
/// Lề 16 pixel trên điện thoại và 32 trên màn hình lớn. Con số này không
/// quan trọng bằng việc **chỉ có một chỗ quyết định nó**: sửa ở đây thì cả
/// bảy trang đổi theo, không trang nào lệch.
class Trang extends StatelessWidget {
  final List<Widget> con;
  final EdgeInsets? leRieng;

  const Trang({super.key, required this.con, this.leRieng});

  @override
  Widget build(BuildContext context) {
    final ngang = context.kho.laDienThoai ? 16.0 : 32.0;
    return SingleChildScrollView(
      padding: leRieng ??
          EdgeInsets.fromLTRB(ngang, 24, ngang, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: con,
      ),
    );
  }
}

/// Tiêu đề mục, dùng lại ở nhiều trang.
class TieuDeMuc extends StatelessWidget {
  final String chu;
  final String? phu;
  final Widget? hanhDong;

  const TieuDeMuc({super.key, required this.chu, this.phu, this.hanhDong});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chu,
                    style:
                        t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (phu != null) ...[
                  const SizedBox(height: 4),
                  Text(phu!,
                      style: t.bodyMedium
                          ?.copyWith(color: mau.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (hanhDong != null) hanhDong!,
        ],
      ),
    );
  }
}
