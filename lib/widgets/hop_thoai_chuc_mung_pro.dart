import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/bo_loc.dart';
import 'huy_hieu_pro_badge.dart';

/// Hộp thoại chúc mừng hiện khi người dùng nâng cấp PRO thành công.
///
/// Được gọi từ [NangCapProScreen] sau khi backend xác nhận giao dịch.
class HopThoaiChucMungPro {
  HopThoaiChucMungPro._();

  static Future<void> hienThi(
    BuildContext context, {
    required String tenGoi,
    required int soNgay,
    required DateTime hetHan,
    required int coinDaTru,
    required int soDuMoi,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NoiDungChucMung(
        tenGoi: tenGoi,
        soNgay: soNgay,
        hetHan: hetHan,
        coinDaTru: coinDaTru,
        soDuMoi: soDuMoi,
      ),
    );
  }
}

class _NoiDungChucMung extends StatefulWidget {
  final String tenGoi;
  final int soNgay;
  final DateTime hetHan;
  final int coinDaTru;
  final int soDuMoi;

  const _NoiDungChucMung({
    required this.tenGoi,
    required this.soNgay,
    required this.hetHan,
    required this.coinDaTru,
    required this.soDuMoi,
  });

  @override
  State<_NoiDungChucMung> createState() => _NoiDungChucMungState();
}

class _NoiDungChucMungState extends State<_NoiDungChucMung>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _dinhDangNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return HieuUngChucMung(
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => FadeTransition(
            opacity: _fadeIn,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A0533),
                      Color(0xFF0D1B2A),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Huy hiệu PRO lớn với animation
                      ScaleTransition(
                        scale: _badgeScale,
                        child: const HuyHieuProLon(size: 100),
                      ),
                      const SizedBox(height: 24),
                      // Tiêu đề
                      Text(
                        '🎉 Chúc mừng!',
                        style: t.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bạn đã trở thành thành viên PRO!',
                        style: t.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Thông tin gói
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _DongThongTin(
                              nhan: 'Gói đã kích hoạt',
                              gia: widget.tenGoi,
                              bieuTuong: Icons.card_membership,
                            ),
                            const SizedBox(height: 10),
                            _DongThongTin(
                              nhan: 'Thời hạn',
                              gia: '${widget.soNgay} ngày',
                              bieuTuong: Icons.schedule,
                            ),
                            const SizedBox(height: 10),
                            _DongThongTin(
                              nhan: 'Hết hạn ngày',
                              gia: _dinhDangNgay(widget.hetHan),
                              bieuTuong: Icons.event,
                            ),
                            const SizedBox(height: 10),
                            _DongThongTin(
                              nhan: 'Đã trừ',
                              gia: '${widget.coinDaTru} Coin',
                              bieuTuong: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Quyền lợi đã mở khóa
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF43A047).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔓 Quyền lợi vừa mở khóa',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF81C784),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final ql in _quyenLoi)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Color(0xFF81C784),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ql,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Nút hành động
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go(
                              DuongDan.danhSachVoiLoc(
                                const BoLoc(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.explore, size: 20),
                          label: const Text(
                            'Khám phá khóa học PRO',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Quay về trang chủ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _quyenLoi = [
    'Mở khóa toàn bộ khóa học PRO',
    'AI Tutor nâng cao không giới hạn',
    'Tài liệu và mã nguồn chuyên sâu',
    'Huy hiệu PRO trên hồ sơ',
    'Ưu tiên hỗ trợ kỹ thuật',
  ];
}

class _DongThongTin extends StatelessWidget {
  final String nhan;
  final String gia;
  final IconData bieuTuong;

  const _DongThongTin({
    required this.nhan,
    required this.gia,
    required this.bieuTuong,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(bieuTuong, size: 16, color: const Color(0xFFFFD700).withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          nhan,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          gia,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
