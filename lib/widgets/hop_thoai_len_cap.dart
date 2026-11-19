import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/cap_do.dart';

/// Hộp thoại chúc mừng khi học viên thăng cấp (Level Up).
///
/// Hiển thị:
/// - Số cấp mới đạt được.
/// - Danh hiệu tương ứng với cấp mới.
/// - Hiệu ứng ngôi sao nổ / pháo hoa đơn giản.
/// - Nút "Tiếp tục" để đóng hộp thoại.
///
/// Cách gọi:
/// ```dart
/// HopThoaiLenCap.hienThi(context, capMoi: capDo);
/// ```
class HopThoaiLenCap extends StatefulWidget {
  final CapDo capMoi;

  const HopThoaiLenCap({super.key, required this.capMoi});

  /// Hiển thị hộp thoại thăng cấp. Tự động đóng sau 8 giây nếu người dùng
  /// không tương tác.
  static Future<void> hienThi(
    BuildContext context, {
    required CapDo capMoi,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HopThoaiLenCap(capMoi: capMoi),
    );
  }

  @override
  State<HopThoaiLenCap> createState() => _HopThoaiLenCapState();
}

class _HopThoaiLenCapState extends State<HopThoaiLenCap>
    with TickerProviderStateMixin {
  late final AnimationController _boPhanNhayBuot;
  late final AnimationController _boPhanSao;
  late final Animation<double> _doTrongSuot;
  late final Animation<double> _tiLeThu;
  late final Animation<double> _tiLeXoay;

  static const int _soHatPhaoCong = 18;
  final math.Random _ngauNhien = math.Random();
  late final List<_HatPhao> _dsHatPhao;

  @override
  void initState() {
    super.initState();

    // Animation hiện hộp thoại: fade-in + scale-up
    _boPhanNhayBuot = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _doTrongSuot = CurvedAnimation(
      parent: _boPhanNhayBuot,
      curve: Curves.easeOut,
    );
    _tiLeThu = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _boPhanNhayBuot, curve: Curves.elasticOut),
    );

    // Animation xoay huy hiệu cấp độ
    _boPhanSao = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _tiLeXoay = Tween<double>(begin: 0, end: 1).animate(_boPhanSao);

    // Tạo danh sách hạt pháo hoa ngẫu nhiên
    _dsHatPhao = List.generate(_soHatPhaoCong, (i) {
      final goc = (i / _soHatPhaoCong) * 2 * math.pi;
      return _HatPhao(
        goc: goc + (_ngauNhien.nextDouble() - 0.5) * 0.5,
        khoangCach: 80 + _ngauNhien.nextDouble() * 60,
        mau: _mauPhaoCong[i % _mauPhaoCong.length],
        kichThuoc: 4 + _ngauNhien.nextDouble() * 6,
      );
    });
  }

  static const List<Color> _mauPhaoCong = [
    Color(0xFFFFD700), // Vàng
    Color(0xFFFF6B6B), // Hồng đỏ
    Color(0xFF4ECDC4), // Xanh lá biển
    Color(0xFFFFE66D), // Vàng nhạt
    Color(0xFF6BCB77), // Xanh lá
    Color(0xFF4D96FF), // Xanh dương
    Color(0xFFFF9A3C), // Cam
  ];

  @override
  void dispose() {
    _boPhanNhayBuot.dispose();
    _boPhanSao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _doTrongSuot,
      child: ScaleTransition(
        scale: _tiLeThu,
        child: AlertDialog(
          backgroundColor: mau.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mau.primaryContainer.withAlpha(200),
                  mau.surface,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề
                Text(
                  '🎉 Thăng Cấp!',
                  style: chu.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: mau.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chúc mừng bạn đã lên cấp mới!',
                  textAlign: TextAlign.center,
                  style: chu.bodyMedium?.copyWith(color: mau.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                // Huy hiệu cấp độ với hiệu ứng pháo hoa
                SizedBox(
                  width: 160,
                  height: 160,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_boPhanNhayBuot, _boPhanSao]),
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Hạt pháo hoa xung quanh
                          ..._dsHatPhao.map(
                            (h) => _HatPhaoCong(
                              hat: h,
                              tienTrinh: _boPhanNhayBuot.value,
                            ),
                          ),

                          // Vòng sáng xoay
                          Transform.rotate(
                            angle: _tiLeXoay.value * 2 * math.pi,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    mau.primary.withAlpha(0),
                                    mau.primary.withAlpha(100),
                                    mau.primary.withAlpha(0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Huy hiệu trung tâm
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mau.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: mau.primary.withAlpha(120),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LV',
                                  style: chu.labelSmall?.copyWith(
                                    color: mau.onPrimary.withAlpha(200),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  '${widget.capMoi.capHienTai}',
                                  style: chu.displaySmall?.copyWith(
                                    color: mau.onPrimary,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Danh hiệu
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: mau.primaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    widget.capMoi.danhHieu,
                    style: chu.titleMedium?.copyWith(
                      color: mau.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Thông tin XP cần cho cấp tiếp
                Text(
                  'Cần thêm ${widget.capMoi.xpCanThiet} XP để lên Lv.${widget.capMoi.capHienTai + 1}',
                  style: chu.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                ),

                const SizedBox(height: 28),

                // Nút tiếp tục
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Tiếp tục học!'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(180, 48),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thông tin một hạt pháo hoa.
class _HatPhao {
  final double goc;
  final double khoangCach;
  final Color mau;
  final double kichThuoc;

  const _HatPhao({
    required this.goc,
    required this.khoangCach,
    required this.mau,
    required this.kichThuoc,
  });
}

/// Widget vẽ một hạt pháo hoa bay ra từ trung tâm.
class _HatPhaoCong extends StatelessWidget {
  final _HatPhao hat;
  final double tienTrinh; // 0.0 → 1.0

  const _HatPhaoCong({required this.hat, required this.tienTrinh});

  @override
  Widget build(BuildContext context) {
    // Hạt chỉ bắt đầu bay sau khi animation chính đạt 50%
    final t = ((tienTrinh - 0.4) / 0.6).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final kc = hat.khoangCach * t;
    final dx = kc * math.cos(hat.goc);
    final dy = kc * math.sin(hat.goc);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: (1.0 - t * 0.5).clamp(0.0, 1.0),
        child: Container(
          width: hat.kichThuoc,
          height: hat.kichThuoc,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hat.mau,
          ),
        ),
      ),
    );
  }
}
