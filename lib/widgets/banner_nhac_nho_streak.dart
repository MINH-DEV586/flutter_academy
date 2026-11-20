import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/chuoi_hoc.dart';
import '../models/nhat_ky_ngay.dart';
import '../viewmodels/providers.dart';

/// Banner nhắc nhở học tập thông minh dựa trên thời gian thực trong ngày
/// và trạng thái chuỗi học tập (Streak) của học viên.
class BannerNhacNhoStreak extends ConsumerWidget {
  const BannerNhacNhoStreak({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chuoi = ref.watch(chuoiHocProvider).asData?.value;
    final nhatKyAsync = ref.watch(nhatKyHomNayProvider);

    if (chuoi == null) return const SizedBox.shrink();

    return nhatKyAsync.when(
      data: (nhatKy) => _NoiDungBanner(chuoi: chuoi, nhatKy: nhatKy),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _NoiDungBanner extends StatelessWidget {
  const _NoiDungBanner({required this.chuoi, required this.nhatKy});

  final ChuoiHoc chuoi;
  final NhatKyNgay nhatKy;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final gioHienTai = DateTime.now().hour;
    final daHocHomNay = chuoi.daHocHomNay();
    final mucTieuPhut = chuoi.mucTieuPhutMoiNgay;
    final phutDaHoc = nhatKy.thoiGianHocPhut;
    final tiLeMucTieu = (phutDaHoc / (mucTieuPhut > 0 ? mucTieuPhut : 1)).clamp(0.0, 1.0);

    String tieuDe;
    String moTa;
    Color mauVien;
    Color mauNen;
    String emoji;

    if (daHocHomNay) {
      emoji = '🔥';
      tieuDe = 'Chuỗi học tập đã được giữ vững (${chuoi.chuoiHienTai} ngày liên tục)!';
      moTa = 'Tuyệt vời! Bạn đã hoàn thành chỉ tiêu học hôm nay. Tiếp tục phát huy nhé!';
      mauVien = Colors.amber.shade700;
      mauNen = Colors.amber.withValues(alpha: 0.12);
    } else if (gioHienTai >= 5 && gioHienTai < 12) {
      emoji = '🌅';
      tieuDe = 'Chào buổi sáng! Bắt đầu bài học mới hôm nay';
      moTa = 'Khởi động ngày mới với 10 phút học để duy trì chuỗi ${chuoi.chuoiHienTai} ngày.';
      mauVien = Colors.blue.shade400;
      mauNen = Colors.blue.withValues(alpha: 0.08);
    } else if (gioHienTai >= 12 && gioHienTai < 18) {
      emoji = '🌤️';
      tieuDe = 'Bạn chưa hoàn thành mục tiêu học tập hôm nay';
      moTa = 'Dành chút thời gian chiều nay để hoàn thành mục tiêu $mucTieuPhut phút nhé!';
      mauVien = Colors.orange.shade400;
      mauNen = Colors.orange.withValues(alpha: 0.08);
    } else {
      emoji = '🌙';
      tieuDe = 'Hãy học để duy trì ngọn lửa Streak!';
      moTa = 'Chỉ còn vài tiếng nữa là hết ngày! Học ngay để không bị đứt chuỗi ${chuoi.chuoiHienTai} ngày.';
      mauVien = Colors.deepOrange.shade600;
      mauNen = Colors.deepOrange.withValues(alpha: 0.12);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mauNen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mauVien, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tieuDe,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moTa,
                      style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: () => context.go(DuongDan.danhSach),
                child: Text(daHocHomNay ? 'Học thêm' : 'Vào học ngay'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thanh tiến độ mục tiêu ngày
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tiLeMucTieu,
                    minHeight: 6,
                    backgroundColor: mau.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      daHocHomNay ? Colors.amber.shade700 : mau.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mục tiêu: $phutDaHoc / $mucTieuPhut phút',
                style: t.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
