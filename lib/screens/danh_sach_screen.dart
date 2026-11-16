import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/bo_loc.dart';
import '../viewmodels/providers.dart';
import '../widgets/luoi_khoa_hoc.dart';
import '../widgets/thanh_loc.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Danh sách khoá học có lọc và sắp xếp.
///
/// ## Bài học chính của trang này: URL là nguồn sự thật
///
/// Bộ lọc **không** nằm trong `State` của widget. Nó nằm trong tham số truy
/// vấn của URL. Luồng dữ liệu đi một chiều:
///
/// ```
/// người dùng bấm chip
///        ↓
/// context.go('/khoa-hoc?danh-muc=Web')      ← đổi URL
///        ↓
/// go_router dựng lại DanhSachScreen với thamSo mới
///        ↓
/// BoLoc.tuThamSo(thamSo) → BoLoc.apDung(danh sách)
/// ```
///
/// Nhờ vậy ba việc sau tự nhiên đúng mà không phải viết thêm dòng nào: bấm
/// Back quay lại bộ lọc trước, F5 giữ nguyên bộ lọc, và sao chép link gửi
/// cho người khác thì họ thấy đúng những gì mình thấy.
///
/// Sách viết trên Navigator 2.0 tự dựng nên phần này chiếm gần một chương;
/// với go_router nó còn lại chừng hai chục dòng.
class DanhSachScreen extends ConsumerWidget {
  final Map<String, String> thamSo;

  const DanhSachScreen({super.key, required this.thamSo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bộ lọc được đọc thẳng từ URL mỗi lần dựng. Không có bản sao nào trong
    // `State` cũng không có provider nào giữ nó — vì vậy không bao giờ có
    // chuyện thanh địa chỉ nói một đằng, màn hình hiện một nẻo.
    final tuUrl = BoLoc.tuThamSo(thamSo);

    final nguon = ref.watch(danhSachKhoaHocProvider);
    final phanTram = ref.watch(phanTramTienDoProvider);
    final danhMuc = ref.watch(danhMucProvider);

    void doiLoc(BoLoc moi) => context.go(DuongDan.danhSachVoiLoc(moi));

    return Trang(
      con: [
        const TieuDeMuc(
          chu: 'Khoá học',
          phu: 'Lọc theo chủ đề, mức độ hoặc học phí. '
              'Bộ lọc nằm ngay trên thanh địa chỉ nên chia sẻ được.',
        ),
        ThanhLoc(boLoc: tuUrl, danhMuc: danhMuc, khiDoi: doiLoc),
        const SizedBox(height: 24),
        KhiAsync(
          gia: nguon,
          thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
          khiCo: (tatCa) {
            // Lọc và sắp xếp ngay tại đây: `BoLoc.apDung` là hàm thuần, chạy
            // trên 12 khoá học thì mất vài micro giây. Chỉ khi danh sách lên
            // tới hàng nghìn mới đáng bọc lại trong một provider có nhớ đệm.
            final ds = tuUrl.apDung(tatCa);
            if (ds.isEmpty) {
              return KhoiRong(
                bieuTuong: Icons.search_off,
                tieuDe: 'Không có khoá học nào khớp',
                moTa: 'Thử bỏ bớt một vài điều kiện lọc, '
                    'hoặc tìm bằng từ khoá ngắn hơn.',
                hanhDong: FilledButton.tonal(
                  onPressed: () => doiLoc(BoLoc.macDinh),
                  child: const Text('Xoá bộ lọc'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tìm thấy ${ds.length} khoá học',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                LuoiKhoaHoc(danhSach: ds, tienDo: phanTram),
              ],
            );
          },
        ),
      ],
    );
  }
}
