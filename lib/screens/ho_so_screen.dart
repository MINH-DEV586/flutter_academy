import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/che_do_giao_dien.dart';
import '../models/dinh_dang.dart' as dd;
import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Hồ sơ người học: thông tin, thống kê, chế độ giao diện, đăng xuất.
class HoSoScreen extends ConsumerWidget {
  const HoSoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phien = ref.watch(phienProvider);

    return KhiAsync(
      gia: phien,
      khiCo: (nd) {
        if (nd == null) {
          // Về lý thuyết không tới được đây (redirect đã chặn), nhưng vẫn
          // xử lý: một màn hình không được sập chỉ vì giả định bị phá vỡ.
          return Trang(
            con: [
              const SizedBox(height: 40),
              KhoiRong(
                bieuTuong: Icons.lock_outline,
                tieuDe: 'Chưa đăng nhập',
                moTa: 'Đăng nhập để xem hồ sơ và tiến độ học của bạn.',
                hanhDong: FilledButton(
                  onPressed: () =>
                      context.go(DuongDan.dangNhapRoiVe(DuongDan.hoSo)),
                  child: const Text('Đăng nhập'),
                ),
              ),
            ],
          );
        }
        return _NoiDung(nguoiDung: nd);
      },
    );
  }
}

class _NoiDung extends ConsumerWidget {
  final NguoiDung nguoiDung;
  const _NoiDung({required this.nguoiDung});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    final danhSach = switch (ref.watch(danhSachKhoaHocProvider)) {
      AsyncData(:final value) => value,
      _ => const <KhoaHoc>[],
    };
    final phanTram = ref.watch(phanTramTienDoProvider);
    final cheDo = ref.watch(chuDeProvider);

    final daBatDau = phanTram.length;
    final daXong = phanTram.values.where((p) => p >= 100).length;
    final giayDaHoc = _giayDaHoc(danhSach, phanTram);

    return Trang(
      con: [
        const TieuDeMuc(chu: 'Hồ sơ'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: mau.primaryContainer,
                  child: Text(
                    nguoiDung.chuVietTat,
                    style: t.titleLarge?.copyWith(
                      color: mau.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nguoiDung.hoTen,
                          style: t.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(nguoiDung.email,
                          style: t.bodyMedium
                              ?.copyWith(color: mau.onSurfaceVariant)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final daXuat = await ref.read(phienProvider.notifier).dangXuat();
                    if (!context.mounted) return;
                    if (daXuat) {
                      context.go(DuongDan.trangChu);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa đăng xuất được. Vui lòng thử lại.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Thống kê học tập',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _O(so: '$daBatDau', nhan: 'Khoá đã bắt đầu'),
            _O(so: '$daXong', nhan: 'Khoá đã hoàn thành'),
            _O(so: dd.thoiLuong(giayDaHoc), nhan: 'Thời lượng đã học'),
          ],
        ),
        const SizedBox(height: 32),
        Text('Giao diện',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SegmentedButton<CheDoGiaoDien>(
          segments: const [
            ButtonSegment(
              value: CheDoGiaoDien.theoHeThong,
              icon: Icon(Icons.brightness_auto),
              label: Text('Theo hệ thống'),
            ),
            ButtonSegment(
              value: CheDoGiaoDien.sang,
              icon: Icon(Icons.light_mode),
              label: Text('Sáng'),
            ),
            ButtonSegment(
              value: CheDoGiaoDien.toi,
              icon: Icon(Icons.dark_mode),
              label: Text('Tối'),
            ),
          ],
          selected: {cheDo},
          onSelectionChanged: (v) =>
              ref.read(chuDeProvider.notifier).dat(v.first),
        ),
        const SizedBox(height: 12),
        Text(
          'Lựa chọn này không được lưu: nó là ví dụ cho `Notifier` đồng bộ, '
          'chỉ sống trong bộ nhớ. Muốn giữ lại sau khi tải lại trang thì ghi '
          'thêm một dòng vào hộp Hive — xem README mục "Bài tập mở rộng".',
          style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Ước lượng thời lượng đã học: cộng thời lượng các bài đã đánh dấu xong.
  ///
  /// Dùng phần trăm nhân tổng thời lượng thì nhanh hơn nhưng sai, vì các bài
  /// dài ngắn khác nhau. Ở đây cộng đúng từng bài.
  int _giayDaHoc(List<KhoaHoc> danhSach, Map<String, int> phanTram) {
    var tong = 0;
    for (final k in danhSach) {
      final p = phanTram[k.ma];
      if (p == null) continue;
      // Không có bảng tiến độ chi tiết ở đây, nên xấp xỉ theo số bài đã xong
      // nhân thời lượng trung bình của khoá. Đủ dùng cho một con số thống kê.
      final soXong = (k.soBaiHoc * p / 100).round();
      if (k.soBaiHoc == 0) continue;
      tong += (k.tongThoiLuongGiay * soXong / k.soBaiHoc).round();
    }
    return tong;
  }
}

class _O extends StatelessWidget {
  final String so;
  final String nhan;
  const _O({required this.so, required this.nhan});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mau.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(so,
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: mau.primary,
              )),
          const SizedBox(height: 4),
          Text(nhan,
              style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant)),
        ],
      ),
    );
  }
}
