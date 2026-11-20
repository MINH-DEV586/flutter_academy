import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/mau_sac.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import 'anh_bia.dart';
import 'sao_danh_gia.dart';

/// Thẻ khoá học — widget `CourseCard` của sách, dựng lại cho 2026.
///
/// Điểm khác biệt đáng nói với bản trong sách: thẻ được bọc trong `InkWell`
/// và điều hướng bằng `context.go(...)` chứ không `Navigator.push`. Trên web,
/// `context.go` đổi luôn thanh địa chỉ, nên người dùng bấm Back là quay lại
/// đúng chỗ và có thể sao chép link gửi cho bạn.
class TheKhoaHoc extends StatelessWidget {
  final KhoaHoc khoaHoc;

  /// Phần trăm đã học, null nếu chưa bắt đầu.
  final int? phanTramTienDo;

  const TheKhoaHoc({
    super.key,
    required this.khoaHoc,
    this.phanTramTienDo,
  });

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.go(DuongDan.chiTiet(khoaHoc.ma)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AnhBia(
                  tenTep: khoaHoc.anhBia,
                  danhMuc: khoaHoc.danhMuc,
                  tieuDe: khoaHoc.tieuDe,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _Nhan(
                    chu: khoaHoc.danhMuc,
                    nen: ChuDe.mauDanhMuc[khoaHoc.danhMuc] ?? ChuDe.mauGoc,
                  ),
                ),
                if (khoaHoc.mienPhi)
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: _Nhan(chu: 'Miễn phí', nen: Color(0xFF0E7C66)),
                  ),
              ],
            ),
            if (phanTramTienDo != null)
              LinearProgressIndicator(
                value: phanTramTienDo! / 100,
                minHeight: 4,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    khoaHoc.tieuDe,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: chu.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    khoaHoc.giangVien,
                    style: chu.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  SaoDanhGia(
                    diem: khoaHoc.diemDanhGia,
                    soLuot: khoaHoc.soLuotDanhGia,
                  ),
                  const SizedBox(height: 10),
                  // `Wrap` chứ không `Row`: ở cột hẹp nhất (điện thoại dọc),
                  // ba mẩu thông tin này không đủ chỗ trên một dòng, và Row
                  // thì tràn ra ngoài kèm sọc vàng đen.
                  Wrap(
                    spacing: 12,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dd.tienVND(khoaHoc.gia),
                          style: chu.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: khoaHoc.mienPhi
                                ? const Color(0xFF0E7C66)
                                : mau.onSurface,
                          ),
                        ),
                      ),
                      if (phanTramTienDo != null)
                        Text(
                          'Đã học $phanTramTienDo%',
                          style: chu.labelMedium
                              ?.copyWith(color: mau.onSurfaceVariant),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: nen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          chu,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
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
