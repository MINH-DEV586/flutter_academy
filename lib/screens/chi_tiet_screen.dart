import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
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
                moTa: 'Không có khoá học nào mang mã "$maKhoaHoc". '
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
    final phanTram =
        khoaHoc.soBaiHoc == 0 ? 0 : (soXong * 100 / khoaHoc.soBaiHoc).round();

    final bai = _baiTiepTheo;

    final cot1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AnhBia(
            tenTep: khoaHoc.anhBia,
            danhMuc: khoaHoc.danhMuc,
            tieuDe: khoaHoc.tieuDe,
            tiLe: 21 / 9,
          ),
        ),
        const SizedBox(height: 20),
        Text(khoaHoc.tieuDe,
            style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
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
        const SizedBox(height: 20),
        Text(khoaHoc.moTaDai, style: t.bodyLarge?.copyWith(height: 1.6)),
        const SizedBox(height: 32),
        Text('Nội dung khoá học',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '${khoaHoc.soBaiHoc} bài · '
          '${dd.thoiLuong(khoaHoc.tongThoiLuongGiay)}',
          style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _DanhSachBai(khoaHoc: khoaHoc, tienDo: tienDo),
      ],
    );

    final cot2 = _TheHanhDong(
      khoaHoc: khoaHoc,
      phanTram: phanTram,
      soXong: soXong,
      baiTiepTheo: bai,
      daBatDau: tienDo != null,
      onDatLai: tienDo == null
          ? null
          : () => ref.read(tienDoProvider.notifier).datLai(khoaHoc.ma),
    );

    return Trang(
      con: [
        TextButton.icon(
          onPressed: () => context.go(DuongDan.danhSach),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Tất cả khoá học'),
        ),
        const SizedBox(height: 8),
        if (rong)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: cot1),
              const SizedBox(width: 32),
              SizedBox(width: 320, child: cot2),
            ],
          )
        else ...[
          cot2,
          const SizedBox(height: 28),
          cot1,
        ],
      ],
    );
  }
}

class _TheHanhDong extends StatelessWidget {
  final KhoaHoc khoaHoc;
  final int phanTram;
  final int soXong;
  final BaiHoc? baiTiepTheo;
  final bool daBatDau;
  final VoidCallback? onDatLai;

  const _TheHanhDong({
    required this.khoaHoc,
    required this.phanTram,
    required this.soXong,
    required this.baiTiepTheo,
    required this.daBatDau,
    this.onDatLai,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final bai = baiTiepTheo;

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
            if (daBatDau) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: phanTram / 100,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$phanTram%', style: t.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Đã xong $soXong/${khoaHoc.soBaiHoc} bài',
                style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: bai == null
                    ? null
                    : () => context
                        .go(DuongDan.baiHoc(khoaHoc.ma, bai.ma)),
                child: Text(daBatDau ? 'Học tiếp' : 'Bắt đầu học'),
              ),
            ),
            if (bai != null) ...[
              const SizedBox(height: 8),
              Text(
                'Bài kế: ${bai.tieuDe}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
              ),
            ],
            if (onDatLai != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onDatLai,
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
            _Dong(
              bieuTuong: Icons.devices,
              chu: 'Học trên mọi thiết bị',
            ),
            const _Dong(
              bieuTuong: Icons.all_inclusive,
              chu: 'Truy cập không giới hạn',
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

  const _DanhSachBai({required this.khoaHoc, this.tienDo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mau = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < khoaHoc.baiHoc.length; i++)
            _MotBai(
              soThuTu: i + 1,
              bai: khoaHoc.baiHoc[i],
              daXong: tienDo?.daXong(khoaHoc.baiHoc[i].ma) ?? false,
              coVach: i < khoaHoc.baiHoc.length - 1,
              mau: mau,
              onMo: () => context.go(
                DuongDan.baiHoc(khoaHoc.ma, khoaHoc.baiHoc[i].ma),
              ),
              onDao: () => ref
                  .read(tienDoProvider.notifier)
                  .daoTrangThaiBai(khoaHoc.ma, khoaHoc.baiHoc[i].ma),
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
