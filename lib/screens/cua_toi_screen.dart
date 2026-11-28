import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../widgets/luoi_khoa_hoc.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Các khóa học mà tài khoản hiện tại đã đăng ký.
class CuaToiScreen extends ConsumerWidget {
  const CuaToiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danhSach = ref.watch(danhSachKhoaHocProvider);
    final dangKy = ref.watch(dangKyKhoaHocProvider);
    final phanTram = ref.watch(phanTramTienDoProvider);

    return Trang(
      con: [
        const TieuDeMuc(
          chu: 'Khoá học của tôi',
          phu: 'Các khóa học bạn đã đăng ký.',
        ),
        KhiAsync(
          gia: dangKy,
          thuLai: () => ref.invalidate(dangKyKhoaHocProvider),
          khiCo: (maDaDangKy) => KhiAsync(
            gia: danhSach,
            thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
            khiCo: (khoaHoc) {
              final ds = locDangHoc(khoaHoc, {
                for (final ma in maDaDangKy) ma: phanTram[ma] ?? 0,
              });
              if (ds.isEmpty) {
                return KhoiRong(
                  bieuTuong: Icons.bookmark_border,
                  tieuDe: 'Bạn chưa đăng ký khóa học nào',
                  moTa: 'Mở khóa bạn muốn học và chọn Đăng ký khóa học.',
                  hanhDong: FilledButton(
                    onPressed: () => context.go(DuongDan.danhSach),
                    child: const Text('Tìm khoá học'),
                  ),
                );
              }
              final xong = ds.where((k) => (phanTram[k.ma] ?? 0) >= 100).length;
              final proCount = ds.where((k) => k.laPro).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Đã đăng ký ${ds.length} khóa · Đã hoàn thành $xong khóa',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (proCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFB74D)),
                          ),
                          child: Text(
                            '$proCount khóa PRO ⭐',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LuoiKhoaHoc(danhSach: ds, tienDo: phanTram),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
