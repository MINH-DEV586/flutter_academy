import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
import '../data/gioi_thieu_khoa_hoc.dart';
import '../data/kho_du_lieu.dart';
import '../data/tai_lieu_bai_hoc.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/bai_hoc.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import '../models/tien_do.dart';
import '../viewmodels/providers.dart';
import '../widgets/anh_bia.dart';
import '../widgets/sao_danh_gia.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';
import '../widgets/video_bai_hoc.dart';

/// Trang chi tiết một khoá học: `/khoa-hoc/<mã>`.
///
/// Mã khoá học lấy từ **tham số đường dẫn**, không truyền qua hàm dựng của
/// widget. Đó là điều kiện để URL dán vào trình duyệt là mở đúng trang —
/// truyền đối tượng `KhoaHoc` qua `Navigator.push` như ứng dụng di động thì
/// URL mở trực tiếp sẽ ra màn hình trắng.
class ChiTietScreen extends ConsumerWidget {
  final String maKhoaHoc;

  const ChiTietScreen({super.key, required this.maKhoaHoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nguon = ref.watch(danhSachKhoaHocProvider);
    final bangTienDo = ref.watch(tienDoProvider);

    return KhiAsync(
      gia: nguon,
      thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
      khiCo: (ds) {
        final k = timKhoaHoc(ds, maKhoaHoc);
        if (k == null) {
          // Mã hợp lệ về mặt cú pháp nhưng không có thật: người dùng dán một
          // link cũ. Không dùng trang 404 chung vì ở đây ta biết rõ hơn
          // chuyện gì đã xảy ra, và gợi ý được chỗ đi tiếp.
          return Trang(
            con: [
              const SizedBox(height: 40),
              KhoiRong(
                bieuTuong: Icons.link_off,
                tieuDe: 'Khoá học không tồn tại',
                moTa:
                    'Không có khoá học nào mang mã "$maKhoaHoc". '
                    'Có thể khoá học đã bị gỡ hoặc link đã cũ.',
                hanhDong: FilledButton(
                  onPressed: () => context.go(DuongDan.danhSach),
                  child: const Text('Xem tất cả khoá học'),
                ),
              ),
            ],
          );
        }

        final td = switch (bangTienDo) {
          AsyncData(:final value) => value[k.ma],
          _ => null,
        };
        return _NoiDung(khoaHoc: k, tienDo: td);
      },
    );
  }
}

class _NoiDung extends ConsumerWidget {
  final KhoaHoc khoaHoc;
  final TienDo? tienDo;

  const _NoiDung({required this.khoaHoc, this.tienDo});

  /// Bài học nên mở khi bấm nút chính: bài đang xem dở, hoặc bài chưa xong
  /// đầu tiên, hoặc bài đầu tiên.
  BaiHoc? get _baiTiepTheo {
    if (khoaHoc.baiHoc.isEmpty) return null;
    final td = tienDo;
    if (td != null) {
      final dangXem = td.baiDangXem;
      if (dangXem != null) {
        final b = khoaHoc.timBaiHoc(dangXem);
        if (b != null) return b;
      }
      for (final b in khoaHoc.baiHoc) {
        if (!td.daXong(b.ma)) return b;
      }
    }
    return khoaHoc.baiHoc.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final rong = context.kho.laManHinhRong;

    final soXong = tienDo == null
        ? 0
        : khoaHoc.baiHoc.where((b) => tienDo!.daXong(b.ma)).length;
    final phanTram = khoaHoc.soBaiHoc == 0
        ? 0
        : (soXong * 100 / khoaHoc.soBaiHoc).round();

    final bai = _baiTiepTheo;
    final gioiThieu = GioiThieuKhoaHoc.cua(khoaHoc.ma);
    final chuong =
        gioiThieu?.chiaChuong(khoaHoc) ?? {'Danh sách bài học': khoaHoc.baiHoc};

    final tieuDe = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          khoaHoc.tieuDe,
          style: (rong ? t.displaySmall : t.headlineMedium)?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(khoaHoc.moTaNgan, style: t.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(khoaHoc.giangVien, style: t.bodyMedium),
            SaoDanhGia(
              diem: khoaHoc.diemDanhGia,
              soLuot: khoaHoc.soLuotDanhGia,
              coChu: 14,
            ),
            Chip(
              label: Text(khoaHoc.mucDo.nhan),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text(khoaHoc.danhMuc),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );

    final cot1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gioiThieu != null) ...[
          _DanhSachGioiThieu(
            tieuDe: 'Bạn sẽ học được gì',
            dong: gioiThieu.mucTieu,
            bieuTuong: Icons.check_circle_outline,
          ),
          const SizedBox(height: 28),
        ],
        Text(
          'Về khóa học',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(khoaHoc.moTaDai, style: t.bodyLarge?.copyWith(height: 1.5)),
        if (gioiThieu != null) ...[
          const SizedBox(height: 28),
          _DanhSachGioiThieu(
            tieuDe: 'Yêu cầu đầu vào',
            dong: gioiThieu.yeuCau,
            bieuTuong: Icons.circle_outlined,
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'Chương trình khóa học',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${chuong.length} phần · ${khoaHoc.soBaiHoc} bài · '
          '${dd.thoiLuong(khoaHoc.tongThoiLuongGiay)}',
          style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _DanhSachBai(khoaHoc: khoaHoc, tienDo: tienDo, chuong: chuong),
      ],
    );

    final hanhDong = _TheHanhDong(
      key: ValueKey(khoaHoc.ma),
      khoaHoc: khoaHoc,
      phanTram: phanTram,
      soXong: soXong,
      baiTiepTheo: bai,
      daBatDau: tienDo != null,
      onDatLai: tienDo == null
          ? null
          : () => ref.read(tienDoProvider.notifier).datLai(khoaHoc.ma),
    );
    final xemTruoc = _XemTruoc(khoaHoc: khoaHoc);

    return Trang(
      con: [
        TextButton.icon(
          onPressed: () => context.go(DuongDan.danhSach),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Tất cả khoá học'),
        ),
        const SizedBox(height: 8),
        tieuDe,
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, khung) {
            if (khung.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hanhDong,
                  const SizedBox(height: 16),
                  xemTruoc,
                  const SizedBox(height: 28),
                  cot1,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cot1),
                const SizedBox(width: 24),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [xemTruoc, const SizedBox(height: 12), hanhDong],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DanhSachGioiThieu extends StatelessWidget {
  const _DanhSachGioiThieu({
    required this.tieuDe,
    required this.dong,
    required this.bieuTuong,
  });

  final String tieuDe;
  final List<String> dong;
  final IconData bieuTuong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              tieuDe,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final noiDung in dong)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(bieuTuong, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(noiDung)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _XemTruoc extends ConsumerWidget {
  const _XemTruoc({required this.khoaHoc});

  final KhoaHoc khoaHoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taiLieu = ref.watch(taiLieuBaiHocProvider).asData?.value;
    final bai = khoaHoc.baiHoc.where((b) => b.xemThu).firstOrNull;
    final video = taiLieu?['${khoaHoc.ma}/${bai?.ma}'];
    final youtubeId = video?.youtubeId;
    final anhBia = AnhBia(
      tenTep: khoaHoc.anhBia,
      danhMuc: khoaHoc.danhMuc,
      tieuDe: khoaHoc.tieuDe,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          anhBia,
          if (bai != null && youtubeId != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Dialog(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        bai.tieuDe,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Đóng video xem trước',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                VideoBaiHoc(
                                  youtubeId: youtubeId,
                                  kenhYouTube: video?.kenhYouTube,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Xem trước khóa học'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TheHanhDong extends ConsumerStatefulWidget {
  final KhoaHoc khoaHoc;
  final int phanTram;
  final int soXong;
  final BaiHoc? baiTiepTheo;
  final bool daBatDau;
  final VoidCallback? onDatLai;

  const _TheHanhDong({
    super.key,
    required this.khoaHoc,
    required this.phanTram,
    required this.soXong,
    required this.baiTiepTheo,
    required this.daBatDau,
    this.onDatLai,
  });

  @override
  ConsumerState<_TheHanhDong> createState() => _TheHanhDongState();
}

class _TheHanhDongState extends ConsumerState<_TheHanhDong> {
  bool _dangGui = false;

  Future<void> _dangKy() async {
    final maKhoaHoc = widget.khoaHoc.ma;
    if (!ref.read(daDangNhapProvider)) {
      context.go(DuongDan.dangNhapRoiVe(DuongDan.chiTiet(maKhoaHoc)));
      return;
    }
    setState(() => _dangGui = true);
    try {
      await ref.read(dangKyKhoaHocProvider.notifier).dangKy(maKhoaHoc);
      if (!mounted) return;
      _thongBao('Đã đăng ký khóa học. Hãy xem trong Khóa học của tôi.');
    } catch (loi) {
      if (!mounted) return;
      _thongBao(
        loi is LoiTaiKhoan
            ? loi.thongBao
            : 'Chưa đăng ký được khóa học. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  void _thongBao(String noiDung) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(noiDung)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final khoaHoc = widget.khoaHoc;
    final bai = widget.baiTiepTheo;
    final daDangNhap = ref.watch(daDangNhapProvider);
    final dangKy = ref.watch(dangKyKhoaHocProvider);
    final daDangKy =
        daDangNhap && (dangKy.asData?.value.contains(khoaHoc.ma) ?? false);
    final dangTai = daDangNhap && dangKy.isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dd.tienVND(khoaHoc.gia),
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: khoaHoc.mienPhi ? const Color(0xFF0E7C66) : null,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.daBatDau && daDangKy) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.phanTram / 100,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${widget.phanTram}%', style: t.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Đã xong ${widget.soXong}/${khoaHoc.soBaiHoc} bài',
                style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            if (!daDangKy)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _dangGui || dangTai ? null : _dangKy,
                  child: Text(_dangGui ? 'Đang đăng ký…' : 'Đăng ký khóa học'),
                ),
              )
            else
              const Text('Đã đăng ký khóa học'),
            if (bai != null) const SizedBox(height: 8),
            if (daDangKy)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: bai == null
                      ? null
                      : () => context.go(DuongDan.baiHoc(khoaHoc.ma, bai.ma)),
                  child: Text(widget.daBatDau ? 'Học tiếp' : 'Bắt đầu học'),
                ),
              )
            else if (bai != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      context.go(DuongDan.baiHoc(khoaHoc.ma, bai.ma)),
                  child: const Text('Xem bài học'),
                ),
              ),
            if (bai != null && daDangKy) ...[
              const SizedBox(height: 8),
              Text(
                'Bài kế: ${bai.tieuDe}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
              ),
            ],
            if (widget.onDatLai != null && daDangKy) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: widget.onDatLai,
                child: const Text('Đặt lại tiến độ'),
              ),
            ],
            const Divider(height: 28),
            _Dong(
              bieuTuong: Icons.play_circle_outline,
              chu: '${khoaHoc.soBaiHoc} bài giảng',
            ),
            _Dong(
              bieuTuong: Icons.schedule,
              chu: dd.thoiLuong(khoaHoc.tongThoiLuongGiay),
            ),
            const _Dong(
              bieuTuong: Icons.smart_display_outlined,
              chu: 'Video tiếng Anh',
            ),
            const _Dong(
              bieuTuong: Icons.translate,
              chu: 'Bài viết và ví dụ tiếng Việt',
            ),
          ],
        ),
      ),
    );
  }
}

class _Dong extends StatelessWidget {
  final IconData bieuTuong;
  final String chu;
  const _Dong({required this.bieuTuong, required this.chu});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(bieuTuong, size: 18, color: mau),
          const SizedBox(width: 10),
          Expanded(
            child: Text(chu, style: TextStyle(fontSize: 13, color: mau)),
          ),
        ],
      ),
    );
  }
}

class _DanhSachBai extends ConsumerWidget {
  final KhoaHoc khoaHoc;
  final TienDo? tienDo;
  final Map<String, List<BaiHoc>> chuong;

  const _DanhSachBai({
    required this.khoaHoc,
    required this.chuong,
    this.tienDo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mau = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (final muc in chuong.entries)
            ExpansionTile(
              key: PageStorageKey((khoaHoc.ma, muc.key)),
              initiallyExpanded: muc.key == chuong.keys.first,
              title: Text(muc.key),
              subtitle: Text(
                '${muc.value.length} bài · '
                '${dd.thoiLuong(muc.value.fold(0, (tong, bai) => tong + bai.thoiLuongGiay))}',
              ),
              children: [
                for (final bai in muc.value)
                  _MotBai(
                    soThuTu: khoaHoc.viTriBaiHoc(bai.ma) + 1,
                    bai: bai,
                    daXong: tienDo?.daXong(bai.ma) ?? false,
                    coVach: bai != muc.value.last,
                    mau: mau,
                    onMo: () => context.go(DuongDan.baiHoc(khoaHoc.ma, bai.ma)),
                    onDao: () => ref
                        .read(tienDoProvider.notifier)
                        .daoTrangThaiBai(khoaHoc.ma, bai.ma),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MotBai extends StatelessWidget {
  final int soThuTu;
  final BaiHoc bai;
  final bool daXong;
  final bool coVach;
  final ColorScheme mau;
  final VoidCallback onMo;
  final VoidCallback onDao;

  const _MotBai({
    required this.soThuTu,
    required this.bai,
    required this.daXong,
    required this.coVach,
    required this.mau,
    required this.onMo,
    required this.onDao,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onMo,
          leading: IconButton(
            tooltip: daXong ? 'Đánh dấu chưa xong' : 'Đánh dấu đã xong',
            onPressed: onDao,
            icon: Icon(
              daXong
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: daXong ? const Color(0xFF0E7C66) : mau.outline,
            ),
          ),
          title: Text(
            '$soThuTu. ${bai.tieuDe}',
            style: TextStyle(
              decoration: daXong ? TextDecoration.lineThrough : null,
              color: daXong ? mau.onSurfaceVariant : null,
            ),
          ),
          subtitle: Text(dd.thoiLuong(bai.thoiLuongGiay)),
          trailing: bai.xemThu
              ? Chip(
                  label: const Text('Xem thử'),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: mau.outlineVariant),
                )
              : const Icon(Icons.chevron_right),
        ),
        if (coVach) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
