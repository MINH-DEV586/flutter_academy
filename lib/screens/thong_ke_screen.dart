import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cap_do.dart';
import '../models/nhat_ky_ngay.dart';
import '../viewmodels/providers.dart';
import '../widgets/lich_hoc_thang.dart';

/// Màn hình Thống kê học tập cá nhân.
///
/// Hiển thị:
/// - Tổng quan (chuỗi dài nhất, tổng XP, cấp độ, tổng ngày học)
/// - Tiến độ cấp độ hiện tại (thanh XP)
/// - Lịch học tháng
/// - Phân tích thống kê: tỷ lệ duy trì streak, số tuần hoàn thành mục tiêu
class ThongKeScreen extends ConsumerStatefulWidget {
  const ThongKeScreen({super.key});

  @override
  ConsumerState<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends ConsumerState<ThongKeScreen> {
  final DateTime _bayGio = DateTime.now();
  Map<String, NhatKyNgay> _nhatKyThang = {};
  bool _dangTai = false;

  @override
  void initState() {
    super.initState();
    _taiNhatKyThang(_bayGio.year, _bayGio.month);
  }

  Future<void> _taiNhatKyThang(int nam, int thang) async {
    setState(() => _dangTai = true);
    try {
      final kq = await ref
          .read(chuoiHocProvider.notifier)
          .layNhatKyThang(nam, thang);
      if (mounted) setState(() => _nhatKyThang = kq);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chuoiAsync = ref.watch(chuoiHocProvider);
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê học tập'), centerTitle: false),
      body: chuoiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (chuoi) {
          final cap = chuoi.capDo;
          final tongNgayHoc = _nhatKyThang.values
              .where((nk) => nk.datDieuKienStreak)
              .length;
          final soTuanDatMucTieu = _tinhSoTuanDatMucTieu();
          final tiLeDuyTri = _tinhTiLeDuyTri();

          return RefreshIndicator(
            onRefresh: () => _taiNhatKyThang(_bayGio.year, _bayGio.month),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Tổng quan 4 ô ──
                _TieuDeMuc(title: ' Tổng quan'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _OThongKe(
                      icon: Icons.local_fire_department_rounded,
                      mau: Colors.orange,
                      nhan: 'Chuỗi dài nhất',
                      giaTri: '${chuoi.chuoiDaiNhat} ngày',
                    ),
                    _OThongKe(
                      icon: Icons.star_rounded,
                      mau: Colors.amber,
                      nhan: 'Tổng XP',
                      giaTri: '${chuoi.tongXp} XP',
                    ),
                    _OThongKe(
                      icon: Icons.shield_rounded,
                      mau: Colors.blue,
                      nhan: 'Khiên Freeze',
                      giaTri: '${chuoi.soKhiensFreeze} chiếc',
                    ),
                    _OThongKe(
                      icon: Icons.calendar_today_rounded,
                      mau: Colors.green,
                      nhan: 'Ngày học tháng này',
                      giaTri: '$tongNgayHoc ngày',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Cấp độ & thanh tiến trình XP ──
                _TieuDeMuc(title: ' Cấp độ hiện tại'),
                const SizedBox(height: 12),
                _TheCapDoXp(cap: cap),

                const SizedBox(height: 20),

                // ── Phân tích hành vi học tập ──
                _TieuDeMuc(title: ' Phân tích'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OThongKe(
                        icon: Icons.trending_up_rounded,
                        mau: Colors.purple,
                        nhan: 'Tỷ lệ duy trì streak',
                        giaTri: '${tiLeDuyTri.toStringAsFixed(0)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OThongKe(
                        icon: Icons.emoji_events_rounded,
                        mau: Colors.deepOrange,
                        nhan: 'Tuần đạt mục tiêu',
                        giaTri: '$soTuanDatMucTieu tuần',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Lịch học tháng ──
                _TieuDeMuc(title: ' Lịch học tháng này'),
                const SizedBox(height: 12),
                if (_dangTai)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  LichHocThang(
                    nam: _bayGio.year,
                    thang: _bayGio.month,
                    nhatKyThang: _nhatKyThang,
                    cacNgayFreeze: chuoi.cacNgayFreezeDaDung,
                    onThayDoiThang: (nam, thang) => _taiNhatKyThang(nam, thang),
                  ),

                const SizedBox(height: 20),

                // ── Huy hiệu đã đạt ──
                if (chuoi.danhSachHuyHieu.isNotEmpty) ...[
                  _TieuDeMuc(title: ' Thành tích đã đạt'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chuoi.danhSachHuyHieu.map((ma) {
                      return Chip(
                        avatar: const Icon(
                          Icons.emoji_events_rounded,
                          size: 16,
                        ),
                        label: Text(ma),
                        backgroundColor: mau.primaryContainer,
                        labelStyle: chu.labelSmall?.copyWith(
                          color: mau.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tính số tuần trong tháng mà học viên hoàn thành mục tiêu (≥5 ngày/tuần).
  int _tinhSoTuanDatMucTieu() {
    if (_nhatKyThang.isEmpty) return 0;
    final ngayHocSet = _nhatKyThang.entries
        .where((e) => e.value.datDieuKienStreak)
        .map((e) {
          final parts = e.key.split('-');
          if (parts.length != 3) return -1;
          return int.tryParse(parts[2]) ?? -1;
        })
        .toSet();

    var soTuan = 0;
    // Tháng có 4-5 tuần; kiểm tra mỗi tuần có ≥5 ngày học không
    for (var tuan = 0; tuan < 5; tuan++) {
      final ngayBatDau = tuan * 7 + 1;
      final ngayKetThuc = ngayBatDau + 6;
      final soNgayTrongTuan = ngayHocSet
          .where((n) => n >= ngayBatDau && n <= ngayKetThuc)
          .length;
      if (soNgayTrongTuan >= 5) soTuan++;
    }
    return soTuan;
  }

  /// Tính tỷ lệ duy trì streak (số ngày học / số ngày trong tháng đã qua).
  double _tinhTiLeDuyTri() {
    final ngayHomNay = _bayGio.day;
    if (ngayHomNay <= 0) return 0;
    final soNgayHoc = _nhatKyThang.values
        .where((nk) => nk.datDieuKienStreak)
        .length;
    return (soNgayHoc / ngayHomNay * 100).clamp(0, 100);
  }
}

// ---------------------------------------------------------------------------
// Các widget phụ trợ
// ---------------------------------------------------------------------------

class _TieuDeMuc extends StatelessWidget {
  final String title;
  const _TieuDeMuc({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _OThongKe extends StatelessWidget {
  final IconData icon;
  final Color mau;
  final String nhan;
  final String giaTri;

  const _OThongKe({
    required this.icon,
    required this.mau,
    required this.nhan,
    required this.giaTri,
  });

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mauApp = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: mauApp.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: mau, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  giaTri,
                  style: chu.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: mauApp.onSurface,
                  ),
                ),
                Text(
                  nhan,
                  style: chu.labelSmall?.copyWith(
                    color: mauApp.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TheCapDoXp extends StatelessWidget {
  final CapDo cap;
  const _TheCapDoXp({required this.cap});

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: mau.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mau.primary,
                  ),
                  child: Center(
                    child: Text(
                      '${cap.capHienTai}',
                      style: chu.titleLarge?.copyWith(
                        color: mau.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cap.danhHieu,
                        style: chu.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Lv.${cap.capHienTai} → Lv.${cap.capHienTai + 1}',
                        style: chu.bodySmall?.copyWith(
                          color: mau.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${cap.xpCuaCap}/${cap.xpCanThiet} XP',
                  style: chu.labelMedium?.copyWith(
                    color: mau.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: cap.tiLeTienDo,
                minHeight: 10,
                backgroundColor: mau.surfaceContainerHighest,
                color: mau.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
