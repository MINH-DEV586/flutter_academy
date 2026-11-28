import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cau_hinh/diem_ngat.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/thuong_chuoi_vm.dart';
import 'hop_thoai_len_cap.dart';
import 'huy_hieu_chuoi_header.dart';
import 'huy_hieu_pro_badge.dart';

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
                  minExtendedWidth: 220,
                  indicatorColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.12),
                  selectedIconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
                  trailingAtBottom: true,
                  trailing: kho.laManHinhRong
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: 188,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF31104B)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: Color(0xFFFFD700),
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Gói PRO VIP',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Mở khóa 15 khóa học & AI không giới hạn.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD700),
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () =>
                                        context.go(DuongDan.nangCapPro),
                                    child: const Text(
                                      'Nâng cấp',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final daDangNhap = ref.watch(daDangNhapProvider);
    final phien = ref.watch(phienProvider);
    final nguoiDung = switch (phien) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final ten = nguoiDung?.hoTen;
    final laPro = ref.watch(laThanhVienProProvider);
    final coinThuong = ref.watch(soDuCoinProvider);
    final laDienThoai = context.kho.laDienThoai;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: laDienThoai ? 8 : 24,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => context.go(DuongDan.trangChu),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(laDienThoai ? 6 : 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: laDienThoai ? 18 : 20,
                    ),
                  ),
                  if (!laDienThoai) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Flutter Academy',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!laDienThoai) ...[
            const SizedBox(width: 20),
            InkWell(
              onTap: () => context.go(DuongDan.danhSach),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: mau.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mau.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16, color: mau.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm kiếm khóa học...',
                      style: TextStyle(
                        fontSize: 13,
                        color: mau.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (daDangNhap) ...[
          // Coin Chip
          Padding(
            padding: EdgeInsets.only(right: laDienThoai ? 4 : 8),
            child: InkWell(
              onTap: () => context.go(DuongDan.viCoin),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: laDienThoai ? 6 : 10,
                  vertical: laDienThoai ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: laDienThoai ? 14 : 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 3),
                    Tooltip(
                      message: 'Số dư ví Coin',
                      child: Text(
                        '${coinThuong ?? '–'} Coin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: laDienThoai ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          HuyHieuChuoiHeader(compact: laDienThoai),
          if (!laDienThoai) const SizedBox(width: 6),
          // Nút PRO hoặc Badge
          if (laPro)
            Padding(
              padding: EdgeInsets.only(right: laDienThoai ? 4 : 8),
              child: InkWell(
                onTap: () => context.go(DuongDan.nangCapPro),
                borderRadius: BorderRadius.circular(8),
                child: HuyHieuProBadge(fontSize: 10, compact: laDienThoai),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: laDienThoai ? 4 : 8),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: laDienThoai ? 6 : 10,
                    vertical: laDienThoai ? 4 : 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFFFFF3E0),
                ),
                onPressed: () => context.go(DuongDan.nangCapPro),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: laDienThoai ? 13 : 15,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: laDienThoai ? 10 : 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // User Avatar + Dropdown Menu
          Padding(
            padding: EdgeInsets.only(right: laDienThoai ? 8 : 20),
            child: PopupMenuButton<String>(
              tooltip: 'Tài khoản',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (giaTri) async {
                switch (giaTri) {
                  case 'hoso':
                    context.go(DuongDan.hoSo);
                  case 'vicoin':
                    context.go(DuongDan.viCoin);
                  case 'pro':
                    context.go(DuongDan.nangCapPro);
                  case 'thongke':
                    context.go(DuongDan.thongKe);
                  case 'bxh':
                    context.go(DuongDan.bangXepHang);
                  case 'dangxuat':
                    await ref.read(phienProvider.notifier).dangXuat();
                    if (context.mounted) context.go(DuongDan.trangChu);
                }
              },
              itemBuilder: (ctx) => [
                // Header item
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ten ?? 'Người học',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (laPro)
                            const HuyHieuProBadge(fontSize: 9, compact: true),
                        ],
                      ),
                      Text(
                        nguoiDung?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: mau.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'hoso',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Hồ sơ cá nhân'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'vicoin',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Ví Coin & Thưởng'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pro',
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 20,
                        color: Color(0xFFE65100),
                      ),
                      SizedBox(width: 12),
                      Text('Nâng cấp PRO ⭐'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'thongke',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Thống kê học tập'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'bxh',
                  child: Row(
                    children: [
                      Icon(Icons.leaderboard_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Bảng xếp hạng'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'dangxuat',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(laPro ? 2 : 0),
                    decoration: laPro
                        ? const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            ),
                          )
                        : null,
                    child: CircleAvatar(
                      radius: laDienThoai ? 15 : 17,
                      backgroundColor: mau.primaryContainer,
                      child: Text(
                        nguoiDung?.chuVietTat ?? 'H',
                        style: TextStyle(
                          fontSize: laDienThoai ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: mau.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  if (laPro)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: Icon(
                        Icons.workspace_premium,
                        size: 13,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          if (!laDienThoai)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => context.go(DuongDan.danhSach),
                child: const Text('Khám phá'),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(right: laDienThoai ? 12 : 24),
            child: FilledButton(
              style: laDienThoai
                  ? FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    )
                  : null,
              onPressed: () =>
                  context.go(DuongDan.dangNhapRoiVe(diaChiHienTai)),
              child: const Text('Đăng nhập'),
            ),
          ),
        ],
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
