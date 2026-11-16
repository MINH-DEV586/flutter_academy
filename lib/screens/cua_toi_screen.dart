import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../widgets/luoi_khoa_hoc.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// "Khoá học của tôi" — trang cần đăng nhập.
///
/// Không có dòng nào ở đây kiểm tra đăng nhập. Việc đó do `redirect` của
/// go_router lo (xem `dinh_tuyen/bo_dinh_tuyen.dart`), nên người chưa đăng
/// nhập không bao giờ chạm tới widget này.
///
/// Đặt chốt kiểm tra ở tầng điều hướng thay vì rải trong từng màn hình là
/// một quyết định kiến trúc có chủ đích: thêm trang mới chỉ cần thêm đường
/// dẫn vào `DuongDan.canDangNhap`, không ai quên được.
class CuaToiScreen extends ConsumerWidget {
  const CuaToiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dangHoc = ref.watch(khoaHocDangHocProvider);
    final phanTram = ref.watch(phanTramTienDoProvider);

    return Trang(
      con: [
        const TieuDeMuc(
          chu: 'Khoá học của tôi',
          phu: 'Tiến độ được lưu bằng Hive, ngay trên máy bạn.',
        ),
        KhiAsync(
          gia: dangHoc,
          thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
          khiCo: (ds) {
            if (ds.isEmpty) {
              return KhoiRong(
                bieuTuong: Icons.bookmark_border,
                tieuDe: 'Bạn chưa bắt đầu khoá nào',
                moTa: 'Mở một khoá học và đánh dấu bài đầu tiên là đã xong — '
                    'khoá học sẽ xuất hiện ở đây.',
                hanhDong: FilledButton(
                  onPressed: () => context.go(DuongDan.danhSach),
                  child: const Text('Tìm khoá học'),
                ),
              );
            }
            final xong = ds.where((k) => (phanTram[k.ma] ?? 0) >= 100).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang học ${ds.length - xong} khoá · Đã hoàn thành $xong khoá',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                LuoiKhoaHoc(danhSach: ds, tienDo: phanTram),
              ],
            );
          },
        ),
      ],
    );
  }
}
