import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../cau_hinh/diem_ngat.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/goi_pro.dart';
import '../viewmodels/providers.dart';
import '../widgets/hop_thoai_chuc_mung_pro.dart';
import '../widgets/huy_hieu_pro_badge.dart';
import '../widgets/the_coin_thuong.dart';

/// Màn hình nâng cấp tài khoản Pro — thiết kế Premium.
///
/// Bố cục: Hero banner → Bảng so sánh FREE vs PRO → Danh sách gói →
/// Quyền lợi chi tiết. Toàn bộ dùng tone tối gradient để tạo cảm giác
/// cao cấp, tách biệt rõ với phần còn lại của ứng dụng.
class NangCapProScreen extends ConsumerStatefulWidget {
  const NangCapProScreen({super.key});

  @override
  ConsumerState<NangCapProScreen> createState() => _NangCapProScreenState();
}

class _NangCapProScreenState extends ConsumerState<NangCapProScreen> {
  String? _dangMuaGoiId;

  void _muaGoi(GoiPro goi, int soDuCoin) async {
    if (soDuCoin < goi.coinPrice) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không đủ Coin'),
          content: Text(
            'Bạn cần ${goi.coinPrice} Coin để đổi gói ${goi.name}, '
            'nhưng hiện tại chỉ có $soDuCoin Coin.\n\n'
            'Hãy nạp thêm Coin bằng ví MetaMask hoặc hoàn thành bài học để nhận thưởng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(DuongDan.napCoin);
              },
              child: const Text('Nạp Coin ngay'),
            ),
          ],
        ),
      );
      return;
    }

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận đổi gói ${goi.name}'),
        content: Text(
          'Hệ thống sẽ trừ ${goi.coinPrice} Coin trong ví của bạn '
          'để kích hoạt ${goi.durationDays} ngày thành viên Pro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận đổi'),
          ),
        ],
      ),
    );

    if (xacNhan != true) return;

    setState(() => _dangMuaGoiId = goi.id);
    final ketQua = await ref.read(thanhVienProvider.notifier).muaGoiPro(goi.id);
    if (!mounted) return;
    setState(() => _dangMuaGoiId = null);

    if (ketQua != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ketQua), backgroundColor: Colors.red),
      );
    } else {
      // Lấy trạng thái mới từ backend
      final trangThai = ref.read(thanhVienProvider).asData?.value;
      if (mounted && trangThai != null) {
        await HopThoaiChucMungPro.hienThi(
          context,
          tenGoi: goi.name,
          soNgay: goi.durationDays,
          hetHan: trangThai.expiresAt ?? DateTime.now(),
          coinDaTru: goi.coinPrice,
          soDuMoi: (ref.read(viCoinProvider).asData?.value?.coinBalance ?? 0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vi = ref.watch(viCoinProvider).asData?.value;
    final soDuCoin = vi?.coinBalance ?? 0;
    final trangThaiPro = ref.watch(thanhVienProvider).asData?.value;
    final dsGoiAsync = ref.watch(danhSachGoiProProvider);
    final hep = context.kho.laDienThoai;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══════════ HERO BANNER ═══════════
          _HeroBanner(trangThaiPro: trangThaiPro, hep: hep),
          // ═══════════ NỘI DUNG CHÍNH ═══════════
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: hep ? 16 : 32,
              vertical: 24,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DiemNgat.rongToiDaNoiDung,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trạng thái Pro hiện tại
                    if (trangThaiPro != null &&
                        trangThaiPro.isPro &&
                        !trangThaiPro.daHetHan)
                      _TheTrangThaiPro(trangThai: trangThaiPro),
                    // Số dư Coin
                    _TheSoDu(soDuCoin: soDuCoin),
                    const SizedBox(height: 16),
                    const TheCoinThuong(),
                    const SizedBox(height: 32),
                    // Bảng so sánh FREE vs PRO
                    const _BangSoSanh(),
                    const SizedBox(height: 32),
                    // Danh sách gói
                    Text(
                      'Chọn gói PRO phù hợp',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    dsGoiAsync.when(
                      data: (ds) {
                        final danhSach = ds.isNotEmpty ? ds : _goiMacDinh;
                        return _LuoiGoiPro(
                          danhSach: danhSach,
                          soDuCoin: soDuCoin,
                          dangMuaGoiId: _dangMuaGoiId,
                          onMua: _dangMuaGoiId == null
                              ? (goi) => _muaGoi(goi, soDuCoin)
                              : null,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) =>
                          const Text('Không tải được danh sách gói Pro.'),
                    ),
                    const SizedBox(height: 40),
                    // Quyền lợi chi tiết
                    const _QuyenLoiChiTiet(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _goiMacDinh = [
    GoiPro(
      id: 'pro_30',
      name: 'Pro 30 ngày',
      durationDays: 30,
      coinPrice: 100,
      description: 'Trải nghiệm đầy đủ quyền Pro trong 30 ngày.',
      benefits: [
        'Mở khóa toàn bộ nội dung Pro',
        'AI Tutor nâng cao không giới hạn',
        'Tài liệu code chuyên sâu',
        'Huy hiệu thành viên Pro',
      ],
    ),
    GoiPro(
      id: 'pro_90',
      name: 'Pro 90 ngày',
      durationDays: 90,
      coinPrice: 250,
      description: 'Gói tiết kiệm cho 3 tháng học tập chuyên sâu.',
      benefits: [
        'Mở khóa toàn bộ nội dung Pro',
        'AI Tutor nâng cao không giới hạn',
        'Tài liệu code chuyên sâu',
        'Huy hiệu thành viên Pro',
        'Tiết kiệm 17% Coin',
      ],
    ),
    GoiPro(
      id: 'pro_365',
      name: 'Pro 365 ngày',
      durationDays: 365,
      coinPrice: 800,
      description: 'Gói trọn năm, tối ưu chi phí nhất.',
      benefits: [
        'Mở khóa toàn bộ nội dung Pro',
        'AI Tutor nâng cao không giới hạn',
        'Tài liệu code chuyên sâu',
        'Huy hiệu thành viên Pro',
        'Tiết kiệm 34% Coin',
        'Ưu tiên hỗ trợ kỹ thuật',
      ],
    ),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO BANNER — Gradient tối + huy hiệu PRO lớn
// ═════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final TrangThaiThanhVien? trangThaiPro;
  final bool hep;

  const _HeroBanner({required this.trangThaiPro, required this.hep});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final daPro =
        trangThaiPro != null && trangThaiPro!.isPro && !trangThaiPro!.daHetHan;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        hep ? 24 : 48,
        hep ? 36 : 56,
        hep ? 24 : 48,
        hep ? 36 : 56,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0533), // Tím đậm
            Color(0xFF0D1B2A), // Đen xanh
            Color(0xFF1B0A2E), // Tím tối
          ],
        ),
      ),
      child: Column(
        children: [
          const HuyHieuProLon(size: 80),
          const SizedBox(height: 20),
          Text(
            daPro ? 'Bạn đang là thành viên PRO' : 'Nâng cấp lên PRO',
            style: (hep ? t.headlineSmall : t.headlineMedium)?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              daPro
                  ? 'Cảm ơn bạn đã đồng hành. Mua thêm gói sẽ được cộng dồn thời hạn.'
                  : 'Mở khóa toàn bộ khóa học chuyên sâu, AI Tutor nâng cao, '
                        'tài liệu code và nhiều quyền lợi độc quyền.',
              style: t.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TRẠNG THÁI PRO HIỆN TẠI
// ═════════════════════════════════════════════════════════════════════════════

class _TheTrangThaiPro extends StatelessWidget {
  final TrangThaiThanhVien trangThai;
  const _TheTrangThaiPro({required this.trangThai});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFFDE7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFFF57C00), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Đang sở hữu đặc quyền PRO',
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const HuyHieuProBadge(fontSize: 10, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Còn ${trangThai.soNgayConLai} ngày · '
                  'Hết hạn ${trangThai.expiresAt?.toString().split(' ')[0] ?? ''}',
                  style: t.bodySmall?.copyWith(color: const Color(0xFF795548)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SỐ DƯ COIN
// ═════════════════════════════════════════════════════════════════════════════

class _TheSoDu extends StatelessWidget {
  final int soDuCoin;
  const _TheSoDu({required this.soDuCoin});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      color: mau.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số dư Coin trong ứng dụng', style: t.bodySmall),
                Text(
                  '$soDuCoin Coin',
                  style: t.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mau.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: () => GoRouter.of(context).go(DuongDan.napCoin),
              child: const Text('Nạp thêm'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BẢNG SO SÁNH FREE vs PRO
// ═════════════════════════════════════════════════════════════════════════════

class _BangSoSanh extends StatelessWidget {
  const _BangSoSanh();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'So sánh FREE và PRO',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mau.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: mau.surfaceContainerHighest),
                children: [
                  _oChuong(
                    'Tính năng',
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  _oChuong(
                    'FREE',
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: mau.onSurfaceVariant,
                    ),
                    canGiua: true,
                  ),
                  _oChuongPro(
                    'PRO',
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              for (final dong in _duLieuSoSanh)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: mau.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  children: [
                    _oChuong(dong.tinhNang, style: t.bodySmall),
                    _oIcon(dong.free, mau),
                    _oIcon(dong.pro, mau, laPro: true),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _oChuong(String text, {TextStyle? style, bool canGiua = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: style,
        textAlign: canGiua ? TextAlign.center : null,
      ),
    );
  }

  Widget _oChuongPro(String text, {TextStyle? style}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: const Color(0xFFFFD700).withValues(alpha: 0.08),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  Widget _oIcon(_GiaTri gv, ColorScheme mau, {bool laPro = false}) {
    final container = laPro
        ? Container(
            color: const Color(0xFFFFD700).withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _noiDung(gv, mau),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _noiDung(gv, mau),
          );
    return container;
  }

  Widget _noiDung(_GiaTri gv, ColorScheme mau) {
    return switch (gv) {
      _GiaTri.co => const Icon(
        Icons.check_circle,
        size: 20,
        color: Color(0xFF43A047),
      ),
      _GiaTri.khong => Icon(Icons.cancel, size: 20, color: mau.outline),
      _GiaTri.gioiHan => Icon(
        Icons.remove_circle_outline,
        size: 20,
        color: Colors.orange.shade700,
      ),
      _GiaTri.khongGioiHan => const Icon(
        Icons.all_inclusive,
        size: 20,
        color: Color(0xFF43A047),
      ),
    };
  }

  static const _duLieuSoSanh = [
    _DongSoSanh('Khóa học miễn phí', _GiaTri.co, _GiaTri.co),
    _DongSoSanh('Khóa học PRO chuyên sâu', _GiaTri.khong, _GiaTri.co),
    _DongSoSanh('AI Tutor hỗ trợ học', _GiaTri.gioiHan, _GiaTri.khongGioiHan),
    _DongSoSanh('Tài liệu mã nguồn', _GiaTri.gioiHan, _GiaTri.co),
    _DongSoSanh('Huy hiệu PRO', _GiaTri.khong, _GiaTri.co),
    _DongSoSanh('Bài luyện tập nâng cao', _GiaTri.khong, _GiaTri.co),
    _DongSoSanh('Ưu tiên hỗ trợ kỹ thuật', _GiaTri.khong, _GiaTri.co),
  ];
}

enum _GiaTri { co, khong, gioiHan, khongGioiHan }

class _DongSoSanh {
  final String tinhNang;
  final _GiaTri free;
  final _GiaTri pro;
  const _DongSoSanh(this.tinhNang, this.free, this.pro);
}

// ═════════════════════════════════════════════════════════════════════════════
// LƯỚI GÓI PRO
// ═════════════════════════════════════════════════════════════════════════════

class _LuoiGoiPro extends StatelessWidget {
  final List<GoiPro> danhSach;
  final int soDuCoin;
  final String? dangMuaGoiId;
  final void Function(GoiPro)? onMua;

  const _LuoiGoiPro({
    required this.danhSach,
    required this.soDuCoin,
    this.dangMuaGoiId,
    this.onMua,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rong = constraints.maxWidth;
        final soCot = rong < 500 ? 1 : (rong < 900 ? 2 : 3);
        final spacing = 16.0;
        final widthItem = (rong - spacing * (soCot - 1)) / soCot;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final goi in danhSach)
              SizedBox(
                width: soCot == 1 ? rong : widthItem,
                child: _TheGoiPro(
                  goi: goi,
                  soDuCoin: soDuCoin,
                  dangMua: dangMuaGoiId == goi.id,
                  laNoiBat: goi.id == 'pro_90',
                  onMua: onMua != null ? () => onMua!(goi) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TheGoiPro extends StatefulWidget {
  final GoiPro goi;
  final int soDuCoin;
  final bool dangMua;
  final bool laNoiBat;
  final VoidCallback? onMua;

  const _TheGoiPro({
    required this.goi,
    required this.soDuCoin,
    required this.dangMua,
    required this.laNoiBat,
    required this.onMua,
  });

  @override
  State<_TheGoiPro> createState() => _TheGoiProState();
}

class _TheGoiProState extends State<_TheGoiPro> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final duCoin = widget.soDuCoin >= widget.goi.coinPrice;

    return MouseRegion(
      onEnter: (_) {
        if (mounted && !_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (mounted && _hovering) setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.laNoiBat
              ? const Color(0xFF1A0533).withValues(alpha: 0.06)
              : mau.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.laNoiBat
                ? const Color(0xFFFFD700)
                : mau.outlineVariant,
            width: widget.laNoiBat ? 2 : 1,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color:
                        (widget.laNoiBat
                                ? const Color(0xFFFFD700)
                                : mau.primary)
                            .withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.laNoiBat)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '⭐ PHỔ BIẾN NHẤT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            Text(
              widget.goi.name,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.goi.coinPrice}',
                  style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: widget.laNoiBat
                        ? const Color(0xFFE65100)
                        : mau.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Coin', style: t.bodyMedium),
                const Text(' / '),
                Text('${widget.goi.durationDays} ngày', style: t.bodyMedium),
              ],
            ),
            if (widget.goi.durationDays >= 90)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '~ ${(widget.goi.coinPrice / (widget.goi.durationDays / 30)).toStringAsFixed(0)} Coin/tháng',
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF43A047),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              widget.goi.description,
              style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
            ),
            const Divider(height: 24),
            for (final b in widget.goi.benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF43A047),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: widget.laNoiBat
                    ? FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                      )
                    : null,
                onPressed: widget.onMua,
                child: widget.dangMua
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(duCoin ? 'Đổi gói ngay' : 'Không đủ Coin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUYỀN LỢI CHI TIẾT
// ═════════════════════════════════════════════════════════════════════════════

class _QuyenLoiChiTiet extends StatelessWidget {
  const _QuyenLoiChiTiet();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quyền lợi thành viên PRO',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final rong = constraints.maxWidth;
            final soCot = rong < 600 ? 1 : 2;
            final spacing = 16.0;
            final w = (rong - spacing * (soCot - 1)) / soCot;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final ql in _danhSachQuyenLoi)
                  SizedBox(
                    width: soCot == 1 ? rong : w,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: mau.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ql.mau.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(ql.bieuTuong, size: 24, color: ql.mau),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ql.tieuDe,
                                  style: t.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ql.moTa,
                                  style: t.bodySmall?.copyWith(
                                    color: mau.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static const _danhSachQuyenLoi = [
    _QuyenLoi(
      Icons.school,
      'Khóa học PRO chuyên sâu',
      'Truy cập toàn bộ khóa học dành riêng cho thành viên PRO: Clean Architecture, Web3, AI Agent, Security, CI/CD...',
      Color(0xFF1976D2),
    ),
    _QuyenLoi(
      Icons.smart_toy,
      'AI Tutor không giới hạn',
      'Hỏi đáp với AI Tutor ở mức chuyên sâu, không giới hạn số lượt mỗi ngày.',
      Color(0xFF7B1FA2),
    ),
    _QuyenLoi(
      Icons.code,
      'Tài liệu mã nguồn',
      'Truy cập mã nguồn hoàn chỉnh, bài tập nâng cao và đáp án chi tiết.',
      Color(0xFF43A047),
    ),
    _QuyenLoi(
      Icons.workspace_premium,
      'Huy hiệu PRO',
      'Huy hiệu PRO hiển thị trên hồ sơ, header và lịch sử hoạt động.',
      Color(0xFFF57C00),
    ),
    _QuyenLoi(
      Icons.support_agent,
      'Ưu tiên hỗ trợ',
      'Được ưu tiên hỗ trợ kỹ thuật khi gặp vấn đề trong quá trình học tập.',
      Color(0xFFE53935),
    ),
    _QuyenLoi(
      Icons.sync,
      'Đồng bộ tiến độ',
      'Lưu và đồng bộ tiến độ học tập trên tất cả thiết bị, không lo mất dữ liệu.',
      Color(0xFF00897B),
    ),
  ];
}

class _QuyenLoi {
  final IconData bieuTuong;
  final String tieuDe;
  final String moTa;
  final Color mau;
  const _QuyenLoi(this.bieuTuong, this.tieuDe, this.moTa, this.mau);
}
