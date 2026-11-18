import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import 'trang_thai.dart';

class CanMuaKhoaHoc extends ConsumerWidget {
  const CanMuaKhoaHoc({
    super.key,
    required this.maKhoaHoc,
    required this.child,
  });

  final String maKhoaHoc;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KhiAsync(
    gia: ref.watch(dangKyKhoaHocProvider),
    thuLai: () => ref.invalidate(dangKyKhoaHocProvider),
    khiCo: (ds) => ds.contains(maKhoaHoc)
        ? child
        : Center(
            child: KhoiRong(
              bieuTuong: Icons.lock_outline,
              tieuDe: 'Nội dung dành cho học viên đã mua khóa',
              moTa:
                  'Về trang giới thiệu để xem giá và mở khóa toàn bộ nội dung.',
              hanhDong: FilledButton(
                onPressed: () => context.go(DuongDan.chiTiet(maKhoaHoc)),
                child: const Text('Xem khóa học'),
              ),
            ),
          ),
  );
}
