import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/mau_sac.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import 'anh_bia.dart';
import 'sao_danh_gia.dart';

/// Thẻ khoá học — thiết kế EdTech hiện đại, hover mượt mà và thông tin rõ ràng.
class TheKhoaHoc extends StatefulWidget {
  final KhoaHoc khoaHoc;

  /// Phần trăm đã học, null nếu chưa bắt đầu.
  final int? phanTramTienDo;

  const TheKhoaHoc({
    super.key,
    required this.khoaHoc,
    this.phanTramTienDo,
  });

  @override
  State<TheKhoaHoc> createState() => _TheKhoaHocState();
}

class _TheKhoaHocState extends State<TheKhoaHoc> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final khoaHoc = widget.khoaHoc;
    final phanTramTienDo = widget.phanTramTienDo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hovering
              ? mau.primary.withValues(alpha: 0.6)
              : mau.outlineVariant,
          width: _hovering ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _hovering
                ? mau.primary.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _hovering ? 16 : 8,
            offset: Offset(0, _hovering ? 6 : 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(DuongDan.chiTiet(khoaHoc.ma)),
        onHover: (hovering) {
          if (mounted && _hovering != hovering) {
            setState(() => _hovering = hovering);
          }
        },
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AnhBia(
                    tenTep: khoaHoc.anhBia,
                    danhMuc: khoaHoc.danhMuc,
                    tieuDe: khoaHoc.tieuDe,
                    chieuCao: 155,
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Nhan(
                      chu: khoaHoc.danhMuc,
                      nen: ChuDe.mauDanhMuc[khoaHoc.danhMuc] ?? ChuDe.mauGoc,
                    ),
                  ),
                  if (khoaHoc.laPro)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: _NhanPro(),
                    )
                  else if (khoaHoc.mienPhi)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: _NhanMienPhi(),
                    ),
                ],
              ),
              if (phanTramTienDo != null)
                LinearProgressIndicator(
                  value: phanTramTienDo / 100,
                  minHeight: 4,
                  backgroundColor: mau.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    phanTramTienDo >= 100
                        ? const Color(0xFF10B981)
                        : mau.primary,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      khoaHoc.tieuDe,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: chu.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      khoaHoc.giangVien,
                      style: chu.bodySmall?.copyWith(
                        color: mau.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    SaoDanhGia(
                      diem: khoaHoc.diemDanhGia,
                      soLuot: khoaHoc.soLuotDanhGia,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MauTin(
                          bieuTuong: Icons.play_circle_outline,
                          chu: '${khoaHoc.soBaiHoc} bài',
                        ),
                        _MauTin(
                          bieuTuong: Icons.schedule,
                          chu: dd.thoiLuong(khoaHoc.tongThoiLuongGiay),
                        ),
                        _MauTin(
                          bieuTuong: Icons.signal_cellular_alt,
                          chu: khoaHoc.mucDo.nhan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            khoaHoc.laPro
                                ? 'Thành viên PRO'
                                : dd.tienVND(khoaHoc.gia),
                            style: chu.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: khoaHoc.laPro
                                  ? const Color(0xFFE65100)
                                  : (khoaHoc.mienPhi
                                      ? const Color(0xFF059669)
                                      : mau.onSurface),
                            ),
                          ),
                        ),
                        if (phanTramTienDo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (phanTramTienDo >= 100
                                      ? const Color(0xFF10B981)
                                      : mau.primary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$phanTramTienDo%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: phanTramTienDo >= 100
                                    ? const Color(0xFF059669)
                                    : mau.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _Nhan extends StatelessWidget {
  final String chu;
  final Color nen;
  const _Nhan({required this.chu, required this.nen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: nen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        chu,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NhanPro extends StatelessWidget {
  const _NhanPro();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FFD700),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 13, color: Colors.black87),
          SizedBox(width: 3),
          Text(
            'PRO ⭐',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NhanMienPhi extends StatelessWidget {
  const _NhanMienPhi();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33059669),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: const Text(
        'Miễn phí',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MauTin extends StatelessWidget {
  final IconData bieuTuong;
  final String chu;
  const _MauTin({required this.bieuTuong, required this.chu});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(bieuTuong, size: 14, color: mau),
        const SizedBox(width: 4),
        Text(chu, style: TextStyle(fontSize: 12, color: mau)),
      ],
    );
  }
}
