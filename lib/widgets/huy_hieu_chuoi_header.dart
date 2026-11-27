import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/chuoi_hoc.dart';
import '../viewmodels/providers.dart';

/// Huy hiệu hiển thị Chuỗi học tập (Streak) và Cấp độ (Level) trên AppBar.
class HuyHieuChuoiHeader extends ConsumerWidget {
  final bool compact;
  const HuyHieuChuoiHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chuoiAsync = ref.watch(chuoiHocProvider);

    return chuoiAsync.when(
      data: (chuoiHoc) => _NoiDungHuyHieu(chuoiHoc: chuoiHoc, compact: compact),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _NoiDungHuyHieu extends StatelessWidget {
  final bool compact;
  const _NoiDungHuyHieu({required this.chuoiHoc, this.compact = false});

  final ChuoiHoc chuoiHoc;

  void _hienBangTomTat(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final capDo = chuoiHoc.capDo;
    final daHoc = chuoiHoc.daHocHomNay();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(
              daHoc ? '🔥 Đã giữ chuỗi!' : '⏳ Chưa giữ chuỗi!',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (chuoiHoc.soKhiensFreeze > 0)
              Tooltip(
                message: 'Khiên bảo vệ chuỗi nếu lỡ 1 ngày',
                child: Chip(
                  avatar: const Text('🛡️'),
                  label: Text('${chuoiHoc.soKhiensFreeze} Freeze'),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê chuỗi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mau.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CotThongSo(
                    nhan: 'Chuỗi hoạt động',
                    giaTri: '${chuoiHoc.chuoiHienTai} ngày',
                    icon: '',
                  ),
                  _CotThongSo(
                    nhan: 'Kỷ lục dài nhất',
                    giaTri: '${chuoiHoc.chuoiDaiNhat} ngày',
                    icon: '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tiến độ Cấp độ & XP
            Text(
              'Cấp độ: Lv.${capDo.capHienTai} · ${capDo.danhHieu}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: capDo.tiLeTienDo,
                minHeight: 10,
                backgroundColor: mau.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(mau.primary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${capDo.xpCuaCap} / ${capDo.xpCanThiet} XP',
                  style: text.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                ),
                Text(
                  'Tổng: ${chuoiHoc.tongXp} XP',
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mau.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lời nhắc nhở
            Text(
              daHoc
                  ? 'Tuyệt vời! Bạn đã hoàn thành điều kiện học tập ngày hôm nay.'
                  : 'Học ít nhất 10 phút hoặc hoàn thành 1 bài học/kiểm tra để tăng chuỗi nhé!',
              style: text.bodyMedium?.copyWith(color: mau.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(DuongDan.hoSo);
            },
            child: const Text('Xem lịch & huy hiệu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final daHoc = chuoiHoc.daHocHomNay();
    final capDo = chuoiHoc.capDo;

    return Padding(
      padding: EdgeInsets.only(right: compact ? 4 : 8),
      child: InkWell(
        onTap: () => _hienBangTomTat(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: daHoc
                ? Colors.amber.withValues(alpha: 0.15)
                : mau.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: daHoc
                  ? Colors.amber.shade700
                  : mau.outlineVariant.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                daHoc ? '🔥' : '⏳',
                style: TextStyle(fontSize: compact ? 13 : 16),
              ),
              SizedBox(width: compact ? 2 : 4),
              Text(
                '${chuoiHoc.chuoiHienTai}',
                semanticsLabel: 'Chuỗi hoạt động ${chuoiHoc.chuoiHienTai} ngày',
                style: (compact ? text.labelMedium : text.titleSmall)?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: daHoc ? Colors.amber.shade900 : mau.onSurfaceVariant,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: mau.outlineVariant),
                const SizedBox(width: 8),
                Text(
                  'Lv.${capDo.capHienTai}',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mau.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CotThongSo extends StatelessWidget {
  const _CotThongSo({
    required this.nhan,
    required this.giaTri,
    required this.icon,
  });

  final String nhan;
  final String giaTri;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          giaTri,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          nhan,
          style: text.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
