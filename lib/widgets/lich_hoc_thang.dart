import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chuoi_hoc.dart';
import '../models/nhat_ky_ngay.dart';
import '../viewmodels/providers.dart';

/// Lịch học theo tháng tương tác:
/// - Chuyển đổi giữa các tháng (Tháng trước / Tháng sau).
/// - Đánh dấu trực quan ngày đã học (🟢), ngày dùng Freeze (❄️), ngày chưa học (⚪).
/// - Nhấn vào một ngày để xem chi tiết thời gian, số bài hoàn thành, khóa học, XP và hoạt động duy trì chuỗi.
class LichHocThang extends ConsumerStatefulWidget {
  const LichHocThang({super.key});

  @override
  ConsumerState<LichHocThang> createState() => _LichHocThangState();
}

class _LichHocThangState extends ConsumerState<LichHocThang> {
  late DateTime _thangHienTai;

  @override
  void initState() {
    super.initState();
    final now = ChuoiHoc.gioVietNam();
    _thangHienTai = DateTime.utc(now.year, now.month);
  }

  void _doiThang(int buoc) {
    setState(() {
      _thangHienTai = DateTime.utc(
        _thangHienTai.year,
        _thangHienTai.month + buoc,
      );
    });
  }

  void _hienChiTietNgay(
    BuildContext context,
    DateTime ngay,
    NhatKyNgay? nk,
    bool dungFreeze,
  ) {
    final text = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final ngayStr = ChuoiHoc.dinhDangNgay(ngay);
    var nhatKy = nk ?? NhatKyNgay(ngay: ngayStr);
    if (!nhatKy.dungFreeze && dungFreeze) {
      nhatKy = nhatKy.danhDauDungFreeze();
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(
              'Ngày $ngayStr',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (nhatKy.dungFreeze)
              const Chip(
                avatar: Text('❄️'),
                label: Text('Dùng Freeze'),
                visualDensity: VisualDensity.compact,
              )
            else if (nhatKy.datDieuKienStreak)
              Chip(
                avatar: const Text('🔥'),
                label: const Text('Đạt Streak'),
                backgroundColor: Colors.green.withValues(alpha: 0.15),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DongChiTiet(
              icon: Icons.timer_outlined,
              tieuDe: 'Thời gian học thực tế',
              noiDung:
                  '${nhatKy.thoiGianHocPhut} phút (${nhatKy.thoiGianHocGiay} giây)',
            ),
            const SizedBox(height: 10),
            _DongChiTiet(
              icon: Icons.check_circle_outline,
              tieuDe: 'Bài học đã hoàn thành',
              noiDung: nhatKy.baiDaHoanThanh.isEmpty
                  ? 'Chưa hoàn thành bài nào'
                  : '${nhatKy.baiDaHoanThanh.length} bài (${nhatKy.baiDaHoanThanh.join(', ')})',
            ),
            const SizedBox(height: 10),
            _DongChiTiet(
              icon: Icons.school_outlined,
              tieuDe: 'Khóa học tham gia',
              noiDung: nhatKy.khoaHocDaThamGia.isEmpty
                  ? 'Không có hoạt động'
                  : nhatKy.khoaHocDaThamGia.join(', '),
            ),
            const SizedBox(height: 10),
            _DongChiTiet(
              icon: Icons.stars_rounded,
              tieuDe: 'Điểm kinh nghiệm (XP)',
              noiDung: '+${nhatKy.xpNhanDuoc} XP',
              mauChu: mau.primary,
            ),
            const SizedBox(height: 10),
            _DongChiTiet(
              icon: Icons.local_fire_department_rounded,
              tieuDe: 'Hoạt động duy trì Streak',
              noiDung:
                  nhatKy.hoatDongDuyTri ??
                  (nhatKy.datDieuKienStreak
                      ? 'Đạt chỉ tiêu học trong ngày'
                      : 'Chưa đủ điều kiện (cần 10p hoặc 1 bài)'),
            ),
          ],
        ),
        actions: [
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
    final thang = nhatKyThangProvider((
      _thangHienTai.year,
      _thangHienTai.month,
    ));
    final nhatKyThang = ref.watch(thang);
    final cacNgayFreeze = ref
        .watch(chuoiHocProvider)
        .asData
        ?.value
        .cacNgayFreezeDaDung;

    final soNgayTrongThang = DateUtils.getDaysInMonth(
      _thangHienTai.year,
      _thangHienTai.month,
    );
    final ngayDauThang = DateTime(_thangHienTai.year, _thangHienTai.month, 1);
    // Thứ Hai = 1, Chủ Nhật = 7. Chuyển để T2 là cột 0, CN là cột 6.
    final viTriCotDau = (ngayDauThang.weekday - 1) % 7;

    final homNay = ChuoiHoc.gioVietNam();
    final homNayStr = ChuoiHoc.dinhDangNgay(homNay);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh chuyển đổi tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _doiThang(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Tháng trước',
                ),
                Text(
                  'Tháng ${_thangHienTai.month} / ${_thangHienTai.year}',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _doiThang(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Tháng sau',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hàng thứ trong tuần
            const Row(
              children: [
                _TieuDeThu('T2'),
                _TieuDeThu('T3'),
                _TieuDeThu('T4'),
                _TieuDeThu('T5'),
                _TieuDeThu('T6'),
                _TieuDeThu('T7'),
                _TieuDeThu('CN'),
              ],
            ),
            const SizedBox(height: 8),

            // Lưới các ngày
            if (nhatKyThang.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (nhatKyThang.hasError)
              TextButton(
                onPressed: () => ref.invalidate(thang),
                child: const Text('Chưa tải được lịch học. Thử lại'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: viTriCotDau + soNgayTrongThang,
                itemBuilder: (context, index) {
                  if (index < viTriCotDau) {
                    return const SizedBox.shrink();
                  }

                  final ngaySo = index - viTriCotDau + 1;
                  final ngayDate = DateTime(
                    _thangHienTai.year,
                    _thangHienTai.month,
                    ngaySo,
                  );
                  final ngayStr = ChuoiHoc.dinhDangNgay(ngayDate);
                  final laHomNay = ngayStr == homNayStr;
                  final nhatKy = nhatKyThang.requireValue[ngayStr];
                  final ngayDungFreeze =
                      nhatKy?.dungFreeze == true ||
                      (cacNgayFreeze?.contains(ngayStr) ?? false);

                  Color? nen;
                  Color? vien;
                  Widget? iconNho;

                  if (ngayDungFreeze) {
                    // Dùng Freeze
                    nen = Colors.cyan.withValues(alpha: 0.18);
                    vien = Colors.cyan.shade600;
                    iconNho = const Text('❄️', style: TextStyle(fontSize: 10));
                  } else if (nhatKy != null && nhatKy.datDieuKienStreak) {
                    // Đã học đạt điều kiện
                    nen = Colors.green.withValues(alpha: 0.2);
                    vien = Colors.green.shade600;
                    iconNho = const Text('🔥', style: TextStyle(fontSize: 10));
                  } else if (laHomNay) {
                    vien = mau.primary;
                  }

                  return InkWell(
                    onTap: () => _hienChiTietNgay(
                      context,
                      ngayDate,
                      nhatKy,
                      ngayDungFreeze,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            nen ??
                            mau.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: vien ?? Colors.transparent,
                          width: laHomNay ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$ngaySo',
                            style: text.bodyMedium?.copyWith(
                              fontWeight: laHomNay
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: laHomNay ? mau.primary : null,
                            ),
                          ),
                          if (iconNho != null)
                            Positioned(top: 2, right: 2, child: iconNho),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Chú thích màu sắc
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ChuThichMau(mau: Colors.green, nhan: 'Đã học (Đạt streak)'),
                _ChuThichMau(mau: Colors.cyan, nhan: 'Khiên Freeze bảo vệ'),
                _ChuThichMau(mau: Colors.grey, nhan: 'Chưa học'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TieuDeThu extends StatelessWidget {
  const _TieuDeThu(this.thu);
  final String thu;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          thu,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _ChuThichMau extends StatelessWidget {
  const _ChuThichMau({required this.mau, required this.nhan});
  final Color mau;
  final String nhan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: mau.withValues(alpha: 0.3),
            border: Border.all(color: mau, width: 1.2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(nhan, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DongChiTiet extends StatelessWidget {
  const _DongChiTiet({
    required this.icon,
    required this.tieuDe,
    required this.noiDung,
    this.mauChu,
  });

  final IconData icon;
  final String tieuDe;
  final String noiDung;
  final Color? mauChu;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: mau.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tieuDe,
                style: text.labelSmall?.copyWith(color: mau.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                noiDung,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: mauChu,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
