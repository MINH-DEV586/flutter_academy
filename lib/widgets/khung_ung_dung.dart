import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import 'hop_thoai_len_cap.dart';
import 'huy_hieu_chuoi_header.dart';

/// Khung bao quanh mọi trang: thanh trên, thanh điều hướng, vùng nội dung.
///
/// Đây là phần **thích ứng** (adaptive) của ứng dụng — không chỉ co giãn mà
/// đổi hẳn dạng điều hướng theo khổ màn hình:
///
/// | Khổ | Điều hướng |
/// |---|---|
/// | Điện thoại | `NavigationBar` dưới đáy |
/// | Máy tính bảng | `NavigationRail` thu gọn bên trái |
/// | Màn hình rộng | `NavigationRail` mở rộng, có nhãn chữ |
///
/// Widget này được go_router dựng một lần qua `ShellRoute` và **giữ nguyên**
/// khi chuyển trang con. Nhờ vậy thanh điều hướng không nhấp nháy, và trạng
/// thái cuộn của khung được giữ.
class KhungUngDung extends ConsumerWidget {
  final Widget child;
  final String diaChiHienTai;

  const KhungUngDung({
    super.key,
    required this.child,
    required this.diaChiHienTai,
  });

  static const List<({IconData bieuTuong, IconData bieuTuongDac, String nhan})>
  _muc = [
    (
      bieuTuong: Icons.home_outlined,
      bieuTuongDac: Icons.home,
      nhan: 'Trang chủ',
    ),
    (
      bieuTuong: Icons.grid_view_outlined,
      bieuTuongDac: Icons.grid_view,
      nhan: 'Khoá học',
    ),
    (
      bieuTuong: Icons.bookmark_outline,
      bieuTuongDac: Icons.bookmark,
      nhan: 'Của tôi',
    ),
    (
      bieuTuong: Icons.person_outline,
      bieuTuongDac: Icons.person,
      nhan: 'Hồ sơ',
    ),
  ];

  void _chon(BuildContext context, int i) => context.go(DuongDan.tabChinh[i]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kho = context.kho;
    final chiSo = DuongDan.chiSoTab(diaChiHienTai);

    final noiDung = _GiamSatLenCap(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DiemNgat.rongToiDaNoiDung,
          ),
          child: child,
        ),
      ),
    );

    return Scaffold(
      appBar: _ThanhTren(diaChiHienTai: diaChiHienTai),
      body: kho.coThanhBen
          ? Row(
              children: [
                NavigationRail(
                  // -1 nghĩa là không ở trang nào trong thanh điều hướng.
                  // NavigationRail không nhận null cho `selectedIndex` kèm
                  // nhãn, nên truyền null và không sáng mục nào.
                  selectedIndex: chiSo < 0 ? null : chiSo,
                  onDestinationSelected: (i) => _chon(context, i),
                  extended: kho.laManHinhRong,
                  minExtendedWidth: 208,
                  labelType: kho.laManHinhRong
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final m in _muc)
                      NavigationRailDestination(
                        icon: Icon(m.bieuTuong),
                        selectedIcon: Icon(m.bieuTuongDac),
                        label: Text(m.nhan),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: noiDung),
              ],
            )
          : noiDung,
      bottomNavigationBar: kho.coThanhBen
          ? null
          : NavigationBar(
              // NavigationBar bắt buộc có chỉ số hợp lệ, nên khi đang ở trang
              // ngoài thanh (đăng nhập, 404) thì tạm sáng "Trang chủ".
              selectedIndex: chiSo < 0 ? 0 : chiSo,
              onDestinationSelected: (i) => _chon(context, i),
              destinations: [
                for (final m in _muc)
                  NavigationDestination(
                    icon: Icon(m.bieuTuong),
                    selectedIcon: Icon(m.bieuTuongDac),
                    label: m.nhan,
                  ),
              ],
            ),
    );
  }
}

class _ThanhTren extends ConsumerWidget implements PreferredSizeWidget {
  final String diaChiHienTai;
  const _ThanhTren({required this.diaChiHienTai});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mau = Theme.of(context).colorScheme;
    final daDangNhap = ref.watch(daDangNhapProvider);
    final phien = ref.watch(phienProvider);
    final ten = switch (phien) {
      AsyncData(:final value) => value?.hoTen,
      _ => null,
    };

    return AppBar(
      automaticallyImplyLeading: false,
      title: InkWell(
        onTap: () => context.go(DuongDan.trangChu),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, color: mau.primary),
              const SizedBox(width: 10),
              Text(
                'Flutter Academy',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      actions: [
        const HuyHieuChuoiHeader(),
        if (daDangNhap)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.go(DuongDan.hoSo),
              icon: const Icon(Icons.account_circle_outlined, size: 20),
              label: Text(ten ?? 'Hồ sơ'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              // Ghi lại trang đang đứng để đăng nhập xong quay về đúng chỗ.
              onPressed: () =>
                  context.go(DuongDan.dangNhapRoiVe(diaChiHienTai)),
              child: const Text('Đăng nhập'),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget giám sát thăng cấp — đặt ở đây để bao phủ toàn bộ ứng dụng.
// ---------------------------------------------------------------------------

/// Widget lắng nghe sự kiện thăng cấp từ [chuoiHocProvider] và tự động
/// hiển thị [HopThoaiLenCap] mỗi khi học viên lên cấp.
///
/// Dùng [ConsumerStatefulWidget] để [ref.listen] không bị gọi lại vô hạn:
/// [initState] chỉ đăng ký listener một lần, [build] chỉ dựng widget con.
class _GiamSatLenCap extends ConsumerStatefulWidget {
  final Widget child;
  const _GiamSatLenCap({required this.child});

  @override
  ConsumerState<_GiamSatLenCap> createState() => _GiamSatLenCapState();
}

class _GiamSatLenCapState extends ConsumerState<_GiamSatLenCap> {
  int? _capTruoc;

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi chuỗi học để phát hiện thăng cấp
    ref.listen(chuoiHocProvider, (truoc, sau) {
      final capMoiObj = sau.asData?.value.capDo;
      final capTruocObj = truoc?.asData?.value.capDo;
      if (capMoiObj == null) return;

      final capMoi = capMoiObj.capHienTai;
      final capTruocVal = capTruocObj?.capHienTai ?? _capTruoc;

      if (capTruocVal != null && capMoi > capTruocVal) {
        // Thăng cấp! Hiển thị hộp thoại sau 1 frame để build xong
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            HopThoaiLenCap.hienThi(context, capMoi: capMoiObj);
          }
        });
      }
      _capTruoc = capMoi;
    });

    return widget.child;
  }
}
