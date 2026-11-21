import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/che_do_giao_dien.dart';
import '../models/chuoi_hoc.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/goi_pro.dart';
import '../models/huy_hieu.dart';
import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../viewmodels/providers.dart';
import '../widgets/huy_hieu_pro_badge.dart';
import '../widgets/lich_hoc_thang.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Hồ sơ người học: thông tin, thống kê, chế độ giao diện, đăng xuất.
class HoSoScreen extends ConsumerWidget {
  const HoSoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phien = ref.watch(phienProvider);

    return KhiAsync(
      gia: phien,
      khiCo: (nd) {
        if (nd == null) {
          // Về lý thuyết không tới được đây (redirect đã chặn), nhưng vẫn
          // xử lý: một màn hình không được sập chỉ vì giả định bị phá vỡ.
          return Trang(
            con: [
              const SizedBox(height: 40),
              KhoiRong(
                bieuTuong: Icons.lock_outline,
                tieuDe: 'Chưa đăng nhập',
                moTa: 'Đăng nhập để xem hồ sơ và tiến độ học của bạn.',
                hanhDong: FilledButton(
                  onPressed: () =>
                      context.go(DuongDan.dangNhapRoiVe(DuongDan.hoSo)),
                  child: const Text('Đăng nhập'),
                ),
              ),
            ],
          );
        }
        return _NoiDung(nguoiDung: nd);
      },
    );
  }
}

class _NoiDung extends ConsumerWidget {
  final NguoiDung nguoiDung;
  const _NoiDung({required this.nguoiDung});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    final danhSach = switch (ref.watch(danhSachKhoaHocProvider)) {
      AsyncData(:final value) => value,
      _ => const <KhoaHoc>[],
    };
    final phanTram = ref.watch(phanTramTienDoProvider);
    final cheDo = ref.watch(chuDeProvider);

    final daBatDau = phanTram.length;
    final daXong = phanTram.values.where((p) => p >= 100).length;
    final giayDaHoc = _giayDaHoc(danhSach, phanTram);
    final chuoiHoc =
        ref.watch(chuoiHocProvider).asData?.value ?? const ChuoiHoc();
    final pro = ref.watch(thanhVienProvider).asData?.value;
    final laPro = pro != null && pro.isPro && !pro.daHetHan;

    return Trang(
      con: [
        const TieuDeMuc(chu: 'Hồ sơ'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(laPro ? 3 : 0),
                      decoration: laPro
                          ? const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                              ),
                            )
                          : null,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: mau.primaryContainer,
                        child: Text(
                          nguoiDung.chuVietTat,
                          style: t.titleLarge?.copyWith(
                            color: mau.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (laPro)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: Icon(Icons.workspace_premium,
                            color: Color(0xFFFFD700), size: 22),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nguoiDung.hoTen,
                              style: t.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (laPro) ...[
                            const SizedBox(width: 8),
                            const HuyHieuProBadge(fontSize: 11),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nguoiDung.email,
                        style: t.bodyMedium?.copyWith(
                          color: mau.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final daXuat = await ref
                        .read(phienProvider.notifier)
                        .dangXuat();
                    if (!context.mounted) return;
                    if (daXuat) {
                      context.go(DuongDan.trangChu);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chưa đăng xuất được. Vui lòng thử lại.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _TheThanhVienProHoSo(pro: pro, laPro: laPro),
        const SizedBox(height: 16),
        const _TheViCoinHoSo(),
        const SizedBox(height: 16),
        _TheCapDoVaStreak(chuoiHoc: chuoiHoc),
        const SizedBox(height: 24),
        Text(
          'Thống kê học tập',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _O(so: '${chuoiHoc.chuoiHienTai} ngày', nhan: 'Chuỗi hiện tại '),
            _O(
              so: '${chuoiHoc.chuoiDaiNhat} ngày',
              nhan: 'Kỷ lục chuỗi dài nhất ',
            ),
            _O(so: '${chuoiHoc.tongXp} XP', nhan: 'Tổng điểm kinh nghiệm '),
            _O(so: '$daBatDau', nhan: 'Khoá đã bắt đầu'),
            _O(so: '$daXong', nhan: 'Khoá đã hoàn thành'),
            _O(so: dd.thoiLuong(giayDaHoc), nhan: 'Thời lượng đã học'),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Bộ sưu tập huy hiệu Streak',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _BoSuuTapHuyHieu(chuoiHoc: chuoiHoc),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => context.go(DuongDan.thongKe),
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: const Text('Xem thống kê chi tiết'),
        ),
        const SizedBox(height: 32),
        Text(
          'Lịch sử học tập',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const LichHocThang(),
        const SizedBox(height: 32),
        Text(
          'Giao diện',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SegmentedButton<CheDoGiaoDien>(
          segments: const [
            ButtonSegment(
              value: CheDoGiaoDien.theoHeThong,
              icon: Icon(Icons.brightness_auto),
              label: Text('Theo hệ thống'),
            ),
            ButtonSegment(
              value: CheDoGiaoDien.sang,
              icon: Icon(Icons.light_mode),
              label: Text('Sáng'),
            ),
            ButtonSegment(
              value: CheDoGiaoDien.toi,
              icon: Icon(Icons.dark_mode),
              label: Text('Tối'),
            ),
          ],
          selected: {cheDo},
          onSelectionChanged: (v) =>
              ref.read(chuDeProvider.notifier).dat(v.first),
        ),
        const SizedBox(height: 12),
        Text(
          'Lựa chọn này không được lưu: nó là ví dụ cho `Notifier` đồng bộ, '
          'chỉ sống trong bộ nhớ. Muốn giữ lại sau khi tải lại trang thì ghi '
          'thêm một dòng vào hộp Hive — xem README mục "Bài tập mở rộng".',
          style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Ước lượng thời lượng đã học: cộng thời lượng các bài đã đánh dấu xong.
  int _giayDaHoc(List<KhoaHoc> danhSach, Map<String, int> phanTram) {
    var tong = 0;
    for (final k in danhSach) {
      final p = phanTram[k.ma];
      if (p == null) continue;
      final soXong = (k.soBaiHoc * p / 100).round();
      if (k.soBaiHoc == 0) continue;
      tong += (k.tongThoiLuongGiay * soXong / k.soBaiHoc).round();
    }
    return tong;
  }
}

class _O extends StatelessWidget {
  final String so;
  final String nhan;
  const _O({required this.so, required this.nhan});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mau.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            so,
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: mau.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(nhan, style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TheCapDoVaStreak extends ConsumerWidget {
  const _TheCapDoVaStreak({required this.chuoiHoc});

  final ChuoiHoc chuoiHoc;

  void _muaFreeze(BuildContext context, WidgetRef ref) async {
    final thanhCong = await ref
        .read(chuoiHocProvider.notifier)
        .muaFreeze(giaXp: 100, toiDa: 3);
    if (!context.mounted) return;
    if (thanhCong) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi thành công 1 Khiên Freeze 🛡️ (-100 XP)'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể đổi: Bạn cần tối thiểu 100 XP hoặc đã đạt tối đa 3 Khiên.',
          ),
        ),
      );
    }
  }

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
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final capDo = chuoiHoc.capDo;

    return Card(
      elevation: 0,
      color: mau.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: mau.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: mau.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lv.${capDo.capHienTai}',
                    style: t.labelLarge?.copyWith(
                      color: mau.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  capDo.danhHieu,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${capDo.xpCuaCap} / ${capDo.xpCanThiet} XP',
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mau.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: capDo.tiLeTienDo,
                minHeight: 10,
                backgroundColor: mau.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(mau.primary),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Text('🛡️'),
                  label: Text('${chuoiHoc.soKhiensFreeze} / 3 Khiên Freeze'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _muaFreeze(context, ref),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Đổi Khiên (100 XP)'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.track_changes, size: 18),
                  label: Text('Mục tiêu: ${chuoiHoc.mucTieuPhutMoiNgay}p/ngày'),
                  onPressed: () => _doiMucTieu(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoSuuTapHuyHieu extends StatelessWidget {
  const _BoSuuTapHuyHieu({required this.chuoiHoc});

  final ChuoiHoc chuoiHoc;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final h in HuyHieu.tatCaMoc)
          _TheHuyHieu(
            huyHieu: h,
            daMo: chuoiHoc.danhSachHuyHieu.contains(h.ma),
            t: t,
            mau: mau,
          ),
      ],
    );
  }
}

class _TheHuyHieu extends StatelessWidget {
  const _TheHuyHieu({
    required this.huyHieu,
    required this.daMo,
    required this.t,
    required this.mau,
  });

  final HuyHieu huyHieu;
  final bool daMo;
  final TextTheme t;
  final ColorScheme mau;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: daMo
            ? Colors.amber.withValues(alpha: 0.1)
            : mau.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: daMo ? Colors.amber.shade700 : mau.outlineVariant,
          width: daMo ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                huyHieu.bieuTuong,
                style: TextStyle(
                  fontSize: 26,
                  color: daMo ? null : Colors.grey,
                ),
              ),
              const Spacer(),
              if (daMo)
                const Icon(Icons.verified, size: 18, color: Colors.amber)
              else
                Icon(Icons.lock_outline, size: 16, color: mau.outline),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            huyHieu.tieuDe,
            style: t.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: daMo ? null : mau.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${huyHieu.mocNgay} ngày liên tục',
            style: t.bodySmall?.copyWith(
              color: daMo ? mau.primary : mau.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            huyHieu.moTa,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(
              color: mau.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TheViCoinHoSo extends ConsumerWidget {
  const _TheViCoinHoSo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vi = ref.watch(viCoinProvider).asData?.value;
    final pro = ref.watch(thanhVienProvider).asData?.value;
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: mau.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: mau.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Ví Coin & Blockchain',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (pro != null && pro.isPro && !pro.daHetHan)
                  const HuyHieuProBadge(fontSize: 11),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số dư: ${vi?.coinBalance ?? 0} Coin',
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: mau.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vi?.daLienKetVi == true
                            ? 'MetaMask: ${vi!.diaChiRutGon}'
                            : 'Chưa liên kết ví MetaMask',
                        style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.go(DuongDan.viCoin),
                      child: const Text('Mở Ví Coin'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => context.go(DuongDan.nangCapPro),
                      child: const Text('Nâng cấp Pro'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TheThanhVienProHoSo extends StatelessWidget {
  final TrangThaiThanhVien? pro;
  final bool laPro;

  const _TheThanhVienProHoSo({required this.pro, required this.laPro});

  void _hienThiLichSu(BuildContext context) {
    final lichSu = pro?.history ?? [];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Lịch sử đăng ký PRO'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: lichSu.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Chưa có lịch sử giao dịch gói Pro nào.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: lichSu.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = lichSu[i];
                    final startStr = item.startedAt.toString().split(' ')[0];
                    final endStr = item.expiresAt.toString().split(' ')[0];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x20FFD700),
                        child: Icon(Icons.workspace_premium,
                            color: Color(0xFFFFD700), size: 20),
                      ),
                      title: Text(item.packageName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('$startStr → $endStr',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.laHieuLuc
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.laHieuLuc ? 'Hiệu lực' : 'Đã qua',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.laHieuLuc
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!laPro) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0533), Color(0xFF2C1654)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A0533).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ),
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.black87, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trải nghiệm tài khoản PRO VIP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mở khóa toàn bộ 5+ khóa học cao cấp, AI Tutor chuyên sâu và tài liệu mã nguồn.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => context.go(DuongDan.nangCapPro),
              child: const Text('Nâng cấp ngay',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final hetHanStr = pro?.expiresAt?.toString().split(' ')[0] ?? '';
    final soNgay = pro?.soNgayConLai ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16082F),
            Color(0xFF240E48),
            Color(0xFF120326),
          ],
        ),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFD700),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 10),
              const Text(
                'THẺ THÀNH VIÊN PRO VIP',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.greenAccent),
                    SizedBox(width: 4),
                    Text(
                      'ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời hạn còn lại',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$soNgay ngày',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hết hạn vào',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hetHanStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () => _hienThiLichSu(context),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Lịch sử gia hạn PRO'),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => context.go(DuongDan.nangCapPro),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Gia hạn thêm gói PRO',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
