import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../cau_hinh/diem_ngat.dart';
import '../cau_hinh/mau_sac.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/bo_loc.dart';
import '../models/chuoi_hoc.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import '../models/nhat_ky_ngay.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/thuong_chuoi_vm.dart';
import '../widgets/banner_nhac_nho_streak.dart';
import '../widgets/huy_hieu_pro_badge.dart';
import '../widgets/muc_noi_bat.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Trang chủ Dashboard — trung tâm học tập phong cách EdTech hiện đại.
class TrangChuScreen extends ConsumerWidget {
  const TrangChuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noiBat = ref.watch(khoaHocNoiBatProvider);
    final dangHoc = switch (ref.watch(khoaHocDangHocProvider)) {
      AsyncData(:final value) => value,
      _ => const <KhoaHoc>[],
    };
    final phanTram = ref.watch(phanTramTienDoProvider);
    final danhMuc = ref.watch(danhMucProvider);
    final tatCaKhoaHoc =
        ref.watch(danhSachKhoaHocProvider).asData?.value ?? const <KhoaHoc>[];
    final khoaHocPro = tatCaKhoaHoc.where((k) => k.laPro).toList();
    final laPro = ref.watch(laThanhVienProProvider);
    final chuoiHoc =
        ref.watch(chuoiHocProvider).asData?.value ?? const ChuoiHoc();
    final dangKy = ref.watch(dangKyKhoaHocProvider).asData?.value ?? const {};
    final soDuCoin = ref.watch(soDuCoinProvider);
    final nhatKy =
        ref.watch(nhatKyHomNayProvider).asData?.value ??
        NhatKyNgay(ngay: ChuoiHoc.dinhDangNgay(ChuoiHoc.gioVietNam()));

    // Tính thời lượng đã học chính xác
    var giayDaHoc = 0;
    for (final k in tatCaKhoaHoc) {
      final p = phanTram[k.ma];
      if (p == null || k.soBaiHoc == 0) continue;
      final soXong = (k.soBaiHoc * p / 100).round();
      giayDaHoc += (k.tongThoiLuongGiay * soXong / k.soBaiHoc).round();
    }
    final soXong = phanTram.values.where((p) => p >= 100).length;

    return Trang(
      con: [
        // 1. Hero Dashboard Section
        const _HeroDashboard(),
        const SizedBox(height: 24),

        // 2. Nhắc nhở duy trì Streak
        const BannerNhacNhoStreak(),
        const SizedBox(height: 24),

        // 3. Bảng thống kê học tập (Learning Statistics Cards)
        _BangThongKeDashboard(
          daDangKy: dangKy.length,
          daHoanThanh: soXong,
          chuoiHienTai: chuoiHoc.chuoiHienTai,
          capHienTai: chuoiHoc.capDo.capHienTai,
          tongXp: chuoiHoc.tongXp,
          soDuCoin: soDuCoin,
          giayDaHoc: giayDaHoc,
        ),
        const SizedBox(height: 28),

        // 4. Mục tiêu học tập hôm nay (Daily Learning Goal)
        _MucTieuHangNgayCard(chuoiHoc: chuoiHoc, nhatKy: nhatKy),
        const SizedBox(height: 36),

        // 5. Khu vực tiếp tục học (Continue Learning)
        if (dangHoc.isNotEmpty) ...[
          MucNoiBat(
            tieuDe: 'Tiếp tục học',
            moTa: 'Bạn đang học dở ${dangHoc.length} khoá học.',
            danhSach: dangHoc,
            tienDo: phanTram,
            hanhDong: TextButton.icon(
              onPressed: () => context.go(DuongDan.cuaToi),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Xem tất cả'),
            ),
          ),
          const SizedBox(height: 40),
        ] else ...[
          _EmptyContinueLearningCard(),
          const SizedBox(height: 40),
        ],

        // 6. Khóa học PRO đặc quyền
        if (khoaHocPro.isNotEmpty) ...[
          MucNoiBat(
            tieuDe: 'Khóa học PRO chuyên sâu ⭐',
            moTa: laPro
                ? 'Đặc quyền tài khoản PRO: Toàn bộ nội dung & AI Tutor đã được mở khóa.'
                : 'Mở khóa toàn bộ khóa học chuyên sâu khi nâng cấp tài khoản PRO.',
            danhSach: khoaHocPro,
            tienDo: phanTram,
            hanhDong: TextButton.icon(
              onPressed: () => context.go(
                DuongDan.danhSachVoiLoc(const BoLoc(chiPro: true)),
              ),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Xem tất cả khóa PRO'),
            ),
          ),
          const SizedBox(height: 40),
        ],

        // 7. Khóa học nổi bật
        KhiAsync(
          gia: noiBat,
          thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
          khiCo: (ds) => MucNoiBat(
            tieuDe: 'Khoá học nổi bật',
            moTa: 'Những khoá được cộng đồng học nhiều nhất.',
            danhSach: ds,
            tienDo: phanTram,
            hanhDong: TextButton.icon(
              onPressed: () => context.go(DuongDan.danhSach),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Tất cả khoá học'),
            ),
          ),
        ),
        const SizedBox(height: 44),

        // 8. Khám phá theo Chủ đề
        if (danhMuc.isNotEmpty) ...[
          const TieuDeMuc(
            chu: 'Chủ đề chuyên môn',
            phu: 'Lựa chọn lộ trình phù hợp với mục tiêu nghề nghiệp của bạn.',
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final d in danhMuc)
                _TheChuDe(
                  ten: d,
                  onTap: () =>
                      context.go(DuongDan.danhSachVoiLoc(BoLoc(danhMuc: d))),
                ),
            ],
          ),
          const SizedBox(height: 40),
        ],

        // 9. Lời khuyên động lực học tập
        const _LearningMotivationCard(),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. HERO SECTION DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class _HeroDashboard extends ConsumerWidget {
  const _HeroDashboard();

  String _loiChaoTheoGio() {
    final gio = DateTime.now().hour;
    if (gio < 12) return 'Chào buổi sáng';
    if (gio < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final hep = context.kho.laDienThoai;
    final phien = ref.watch(phienProvider).asData?.value;
    final ten = phien?.hoTen ?? 'Học viên Flutter';
    final pro = ref.watch(thanhVienProvider).asData?.value;
    final laPro = pro != null && pro.isPro && !pro.daHetHan;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hep ? 24 : 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: laPro
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E40AF), const Color(0xFF0284C7)],
        ),
        boxShadow: [
          BoxShadow(
            color: (laPro ? const Color(0xFFFFD700) : const Color(0xFF1E40AF))
                .withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${_loiChaoTheoGio()}, $ten! 👋',
                      style: (hep ? t.titleMedium : t.titleLarge)?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (laPro)
                      const HuyHieuProBadge(fontSize: 10, compact: false),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  laPro
                      ? 'Tài khoản PRO kích hoạt · Bạn có toàn quyền truy cập 15 khóa học cao cấp và AI Tutor 24/7.'
                      : 'Học Flutter cho Web từ Widget đến Production. Nắm vững Clean Architecture, State Management & Web3.',
                  style: t.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: laPro
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                        foregroundColor: laPro
                            ? Colors.black87
                            : const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => context.go(DuongDan.danhSach),
                      icon: const Icon(Icons.explore, size: 18),
                      label: const Text(
                        'Khám phá khóa học',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!laPro)
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => context.go(DuongDan.nangCapPro),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 18,
                              color: Color(0xFFFFD700),
                            ),
                            SizedBox(width: 6),
                            Text('Nâng cấp PRO ⭐'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!hep) ...[
            const SizedBox(width: 24),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                laPro ? Icons.workspace_premium : Icons.code,
                size: 56,
                color: laPro ? const Color(0xFFFFD700) : Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. LEARNING STATISTICS CARDS
// ═════════════════════════════════════════════════════════════════════════════

class _BangThongKeDashboard extends StatelessWidget {
  final int daDangKy;
  final int daHoanThanh;
  final int chuoiHienTai;
  final int capHienTai;
  final int tongXp;
  final int? soDuCoin;
  final int giayDaHoc;

  const _BangThongKeDashboard({
    required this.daDangKy,
    required this.daHoanThanh,
    required this.chuoiHienTai,
    required this.capHienTai,
    required this.tongXp,
    required this.soDuCoin,
    required this.giayDaHoc,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final soCot = w < 540 ? 2 : (w < 900 ? 3 : 6);
        final spacing = 12.0;
        final itemW = (w - spacing * (soCot - 1)) / soCot;

        final items = [
          _StatData(
            'Khóa đã đăng ký',
            '$daDangKy',
            Icons.school_outlined,
            const Color(0xFF1E40AF),
          ),
          _StatData(
            'Đã hoàn thành',
            '$daHoanThanh',
            Icons.check_circle_outline,
            const Color(0xFF10B981),
          ),
          _StatData(
            'Chuỗi hoạt động',
            '$chuoiHienTai ngày',
            Icons.local_fire_department,
            const Color(0xFFF97316),
          ),
          _StatData(
            'Cấp độ & XP',
            'Lv.$capHienTai ($tongXp)',
            Icons.military_tech_outlined,
            const Color(0xFF8B5CF6),
          ),
          _StatData(
            'Số dư Coin',
            soDuCoin == null ? '–' : '$soDuCoin Coin',
            Icons.monetization_on_outlined,
            const Color(0xFFF59E0B),
          ),
          _StatData(
            'Thời lượng học',
            dd.thoiLuong(giayDaHoc),
            Icons.timer_outlined,
            const Color(0xFF06B6D4),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemW,
                child: _TheThongKeItem(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _TheThongKeItem extends StatelessWidget {
  final _StatData data;
  const _TheThongKeItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mau.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: t.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: t.bodySmall?.copyWith(
              color: mau.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. DAILY LEARNING GOAL CARD
// ═════════════════════════════════════════════════════════════════════════════

class _MucTieuHangNgayCard extends ConsumerWidget {
  final ChuoiHoc chuoiHoc;
  final NhatKyNgay nhatKy;

  const _MucTieuHangNgayCard({required this.chuoiHoc, required this.nhatKy});

  void _doiMucTieu(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn mục tiêu học tập hàng ngày'),
        children: [
          for (final phut in [5, 10, 15, 20, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () {
                ref.read(chuoiHocProvider.notifier).datMucTieu(phut);
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '$phut phút / ngày',
                      style: TextStyle(
                        fontWeight: chuoiHoc.mucTieuPhutMoiNgay == phut
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (chuoiHoc.mucTieuPhutMoiNgay == phut) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final mucTieu = chuoiHoc.mucTieuPhutMoiNgay;
    final daHoc = nhatKy.thoiGianHocPhut;
    final tiLe = (daHoc / mucTieu).clamp(0.0, 1.0);
    final datMoc = daHoc >= mucTieu;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: datMoc
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : mau.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (datMoc
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF97316))
                          .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  datMoc ? Icons.check_circle : Icons.track_changes,
                  color: datMoc
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      datMoc
                          ? '🎉 Đã hoàn thành mục tiêu hôm nay!'
                          : 'Mục tiêu học tập hôm nay',
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      datMoc
                          ? 'Tuyệt vời! Bạn đã duy trì được thói quen học tập xuất sắc.'
                          : 'Học thêm ${mucTieu - daHoc} phút nữa để đạt mục tiêu ngày và bảo vệ chuỗi Streak.',
                      style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _doiMucTieu(context, ref),
                icon: const Icon(Icons.tune, size: 16),
                label: Text(
                  '${mucTieu}p/ngày',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tiLe,
              minHeight: 8,
              backgroundColor: mau.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                datMoc ? const Color(0xFF10B981) : const Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã học: $daHoc phút',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mau.onSurfaceVariant,
                ),
              ),
              Text(
                '${(tiLe * 100).toInt()}% hoàn thành',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: datMoc
                      ? const Color(0xFF10B981)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. EMPTY CONTINUE LEARNING CARD
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyContinueLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mau.outlineVariant),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: mau.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa bắt đầu khóa học nào',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                'Khám phá hơn 15 khóa học chuẩn công nghiệp từ cơ bản đến nâng cao để bắt đầu hành trình lập trình của bạn ngay hôm nay.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(DuongDan.danhSach),
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: const Text('Bắt đầu khóa học đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. MOTIVATION CARD
// ═════════════════════════════════════════════════════════════════════════════

class _LearningMotivationCard extends StatelessWidget {
  const _LearningMotivationCard();

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mau.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mau.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Lời khuyên học tập',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Duy trì tối thiểu 15 phút học và thực hành mỗi ngày hiệu quả hơn học dồn 5 tiếng cuối tuần. '
                  'Hãy tích lũy điểm XP để mở khóa khiên Freeze bảo vệ chuỗi Streak của bạn!',
                  style: TextStyle(fontSize: 12, color: mau.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TheChuDe extends StatelessWidget {
  final String ten;
  final VoidCallback onTap;

  const _TheChuDe({required this.ten, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nen = ChuDe.mauDanhMuc[ten] ?? ChuDe.mauGoc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: nen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: nen.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: nen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              ten,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: nen,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
