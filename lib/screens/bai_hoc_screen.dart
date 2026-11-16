import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
import '../data/tai_lieu_bai_hoc.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/bai_hoc.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import '../models/tien_do.dart';
import '../viewmodels/providers.dart';
import '../widgets/gia_su_ai.dart';
import '../widgets/trang_thai.dart';
import '../widgets/video_bai_hoc.dart';

/// Trang học một bài: `/khoa-hoc/<mã>/bai/<mã bài>`.
///
/// Trang này nằm ở navigator gốc nên chiếm trọn màn hình, không có thanh
/// điều hướng — giống chế độ toàn màn hình của mọi nền tảng học trực tuyến.
class BaiHocScreen extends ConsumerStatefulWidget {
  final String maKhoaHoc;
  final String maBaiHoc;

  const BaiHocScreen({
    super.key,
    required this.maKhoaHoc,
    required this.maBaiHoc,
  });

  @override
  ConsumerState<BaiHocScreen> createState() => _BaiHocScreenState();
}

class _BaiHocScreenState extends ConsumerState<BaiHocScreen> {
  @override
  void initState() {
    super.initState();
    _ghiNhoDangXem();
  }

  @override
  void didUpdateWidget(covariant BaiHocScreen cu) {
    super.didUpdateWidget(cu);
    // go_router tái sử dụng widget khi chỉ đổi tham số đường dẫn (bấm "Bài
    // sau"), nên `initState` không chạy lại. Thiếu nhánh này thì nút "Học
    // tiếp" luôn quay về bài đầu tiên đã mở trong phiên.
    if (cu.maBaiHoc != widget.maBaiHoc || cu.maKhoaHoc != widget.maKhoaHoc) {
      _ghiNhoDangXem();
    }
  }

  /// Ghi nhớ bài đang xem. Hoãn sang sau khung hình đầu vì sửa provider
  /// trong lúc dựng widget là lỗi.
  void _ghiNhoDangXem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(tienDoProvider.notifier)
          .danhDauDangXem(widget.maKhoaHoc, widget.maBaiHoc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nguon = ref.watch(danhSachKhoaHocProvider);
    final bangTienDo = ref.watch(tienDoProvider);

    return Scaffold(
      body: SafeArea(
        child: KhiAsync(
          gia: nguon,
          thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
          khiCo: (ds) {
            final k = timKhoaHoc(ds, widget.maKhoaHoc);
            final b = k?.timBaiHoc(widget.maBaiHoc);
            if (k == null || b == null) {
              return KhoiRong(
                bieuTuong: Icons.link_off,
                tieuDe: 'Không có bài học này',
                moTa:
                    'Đường dẫn "/khoa-hoc/${widget.maKhoaHoc}'
                    '/bai/${widget.maBaiHoc}" không dẫn tới bài nào.',
                hanhDong: FilledButton(
                  onPressed: () => context.go(DuongDan.danhSach),
                  child: const Text('Xem tất cả khoá học'),
                ),
              );
            }
            final td = switch (bangTienDo) {
              AsyncData(:final value) => value[k.ma],
              _ => null,
            };
            return _NoiDung(khoaHoc: k, bai: b, tienDo: td);
          },
        ),
      ),
    );
  }
}

class _NoiDung extends ConsumerWidget {
  final KhoaHoc khoaHoc;
  final BaiHoc bai;
  final TienDo? tienDo;

  const _NoiDung({required this.khoaHoc, required this.bai, this.tienDo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    final rong = !context.kho.laDienThoai;

    final viTri = khoaHoc.viTriBaiHoc(bai.ma);
    final truoc = viTri > 0 ? khoaHoc.baiHoc[viTri - 1] : null;
    final sau = viTri >= 0 && viTri < khoaHoc.baiHoc.length - 1
        ? khoaHoc.baiHoc[viTri + 1]
        : null;
    final daXong = tienDo?.daXong(bai.ma) ?? false;
    final maTaiLieu = '${khoaHoc.ma}/${bai.ma}';
    final taiLieu = ref.watch(taiLieuBaiHocProvider);
    final taiLieuBai = taiLieu.asData?.value[maTaiLieu];
    final youtubeId = taiLieuBai?.youtubeId;

    final khungPhat = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (youtubeId != null)
          VideoBaiHoc(key: ValueKey(youtubeId), youtubeId: youtubeId)
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mau.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mau.outlineVariant),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 56,
                      color: mau.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Video bài học',
                      style: t.titleSmall?.copyWith(
                        color: mau.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bài này chưa có video.',
                      style: t.bodySmall?.copyWith(color: mau.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Bài ${viTri + 1} · ${dd.thoiLuong(bai.thoiLuongGiay)}',
          style: t.labelMedium?.copyWith(color: mau.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          bai.tieuDe,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => ref
                  .read(tienDoProvider.notifier)
                  .daoTrangThaiBai(khoaHoc.ma, bai.ma),
              icon: Icon(daXong ? Icons.undo : Icons.check),
              label: Text(daXong ? 'Bỏ đánh dấu' : 'Đánh dấu đã xong'),
            ),
            if (truoc != null)
              TextButton.icon(
                onPressed: () =>
                    context.go(DuongDan.baiHoc(khoaHoc.ma, truoc.ma)),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Bài trước'),
              ),
            if (sau != null)
              TextButton.icon(
                onPressed: () =>
                    context.go(DuongDan.baiHoc(khoaHoc.ma, sau.ma)),
                icon: const Icon(Icons.chevron_right),
                iconAlignment: IconAlignment.end,
                label: const Text('Bài sau'),
              ),
          ],
        ),
        if (taiLieu.isLoading)
          const LinearProgressIndicator(semanticsLabel: 'Đang tải tài liệu')
        else if (taiLieu.hasError)
          TextButton(
            onPressed: () => ref.invalidate(taiLieuBaiHocProvider),
            child: const Text('Tải lại tài liệu bài học'),
          )
        else if (taiLieuBai != null) ...[
          const SizedBox(height: 24),
          Text('Nội dung bài học', style: t.titleLarge),
          const SizedBox(height: 8),
          SelectableText(taiLieuBai.noiDung),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mau.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              taiLieuBai.code,
              style: t.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 24),
          GiaSuAi(
            key: ValueKey(maTaiLieu),
            maBai: maTaiLieu,
            tenBai: bai.tieuDe,
          ),
        ],
      ],
    );

    final mucLuc = _MucLuc(khoaHoc: khoaHoc, bai: bai, tienDo: tienDo);

    return Column(
      children: [
        _ThanhTren(khoaHoc: khoaHoc),
        const Divider(height: 1),
        Expanded(
          child: rong
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: khungPhat,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 320, child: mucLuc),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [khungPhat, const SizedBox(height: 24), mucLuc],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ThanhTren extends StatelessWidget {
  final KhoaHoc khoaHoc;
  const _ThanhTren({required this.khoaHoc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Về trang khoá học',
            icon: const Icon(Icons.close),
            // `context.go` chứ không `context.pop`: người dùng có thể mở
            // thẳng URL bài học trong tab mới, lúc đó không có gì để pop.
            onPressed: () => context.go(DuongDan.chiTiet(khoaHoc.ma)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              khoaHoc.tieuDe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MucLuc extends StatelessWidget {
  final KhoaHoc khoaHoc;
  final BaiHoc bai;
  final TienDo? tienDo;

  const _MucLuc({required this.khoaHoc, required this.bai, this.tienDo});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Nội dung khoá học',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (var i = 0; i < khoaHoc.baiHoc.length; i++)
          _MucBai(
            soThuTu: i + 1,
            bai: khoaHoc.baiHoc[i],
            dangXem: khoaHoc.baiHoc[i].ma == bai.ma,
            daXong: tienDo?.daXong(khoaHoc.baiHoc[i].ma) ?? false,
            onMo: () =>
                context.go(DuongDan.baiHoc(khoaHoc.ma, khoaHoc.baiHoc[i].ma)),
          ),
      ],
    );
  }
}

class _MucBai extends StatelessWidget {
  final int soThuTu;
  final BaiHoc bai;
  final bool dangXem;
  final bool daXong;
  final VoidCallback onMo;

  const _MucBai({
    required this.soThuTu,
    required this.bai,
    required this.dangXem,
    required this.daXong,
    required this.onMo,
  });

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      selected: dangXem,
      selectedTileColor: mau.primaryContainer.withValues(alpha: 0.5),
      leading: Icon(
        daXong ? Icons.check_circle : Icons.play_circle_outline,
        size: 20,
        color: daXong ? const Color(0xFF0E7C66) : mau.outline,
      ),
      title: Text(
        '$soThuTu. ${bai.tieuDe}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: dangXem ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        dd.thoiLuong(bai.thoiLuongGiay),
        style: const TextStyle(fontSize: 11),
      ),
      onTap: dangXem ? null : onMo,
    );
  }
}
