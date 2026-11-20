import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
import '../cau_hinh/mau_sac.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/bo_loc.dart';
import '../models/khoa_hoc.dart';
import '../viewmodels/providers.dart';
import '../widgets/banner_nhac_nho_streak.dart';
import '../widgets/muc_noi_bat.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Trang chủ.
///
/// Bố cục theo đúng mạch của sách: một mảng giới thiệu ở trên, rồi tới các
/// dải khoá học cuộn ngang. Phần thêm vào so với sách là dải "Tiếp tục học",
/// chỉ hiện khi người dùng đã bắt đầu một khoá nào đó — nó cho thấy dữ liệu
/// cục bộ (Hive) và trạng thái phiên phối hợp với nhau ra sao.
class TrangChuScreen extends ConsumerWidget {
  const TrangChuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noiBat = ref.watch(khoaHocNoiBatProvider);
    final dangHoc = switch (ref.watch(khoaHocDangHocProvider)) {
      AsyncData(:final value) => value,
      _ => const <KhoaHoc>[],
    };
    final phanTram = ref.watch(phanTramTienDoProvider);
    final danhMuc = ref.watch(danhMucProvider);

    return Trang(
      con: [
        const _Mang(),
        const SizedBox(height: 32),
        const BannerNhacNhoStreak(),
        if (dangHoc.isNotEmpty) ...[
          MucNoiBat(
            tieuDe: 'Tiếp tục học',
            moTa: 'Bạn đang dở ${dangHoc.length} khoá học.',
            danhSach: dangHoc,
            tienDo: phanTram,
            hanhDong: TextButton(
              onPressed: () => context.go(DuongDan.cuaToi),
              child: const Text('Xem tất cả'),
            ),
          ),
          const SizedBox(height: 40),
        ],
        KhiAsync(
          gia: noiBat,
          thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
          khiCo: (ds) => MucNoiBat(
            tieuDe: 'Khoá học nổi bật',
            moTa: 'Những khoá được học nhiều nhất trong học kỳ này.',
            danhSach: ds,
            tienDo: phanTram,
            hanhDong: TextButton(
              onPressed: () => context.go(DuongDan.danhSach),
              child: const Text('Tất cả khoá học'),
            ),
          ),
        ),
        const SizedBox(height: 44),
        if (danhMuc.isNotEmpty) ...[
          const TieuDeMuc(
            chu: 'Chủ đề',
            phu: 'Bấm vào một chủ đề để lọc danh sách khoá học.',
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final d in danhMuc)
                _TheChuDe(
                  ten: d,
                  onTap: () => context.go(
                    DuongDan.danhSachVoiLoc(BoLoc(danhMuc: d)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Mảng giới thiệu ở đầu trang.
class _Mang extends StatelessWidget {
  const _Mang();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hep = context.kho.laDienThoai;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hep ? 24 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChuDe.mauGoc,
            Color.lerp(ChuDe.mauGoc, Colors.black, 0.4)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Học Flutter cho web,\ntừ widget tới bản triển khai',
            style: (hep ? t.headlineSmall : t.displaySmall)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Mười hai khoá học bám sát học phần INT1449. Tiến độ được lưu '
              'ngay trên máy bạn, không cần tài khoản để bắt đầu.',
              style: t.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ChuDe.mauGoc,
                ),
                onPressed: () => context.go(DuongDan.danhSach),
                child: const Text('Bắt đầu học'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go(
                  DuongDan.danhSachVoiLoc(const BoLoc(chiMienPhi: true)),
                ),
                child: const Text('Xem khoá miễn phí'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TheChuDe extends StatelessWidget {
  final String ten;
  final VoidCallback onTap;

  const _TheChuDe({required this.ten, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nen = ChuDe.mauDanhMuc[ten] ?? ChuDe.mauGoc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: nen.withValues(alpha: 0.10),
          border: Border.all(color: nen.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: nen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ten,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
