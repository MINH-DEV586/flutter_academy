import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/vi_coin_vm.dart';
import '../widgets/the_coin_thuong.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Màn hình Ví Coin cá nhân của học viên.
class ViCoinScreen extends ConsumerStatefulWidget {
  const ViCoinScreen({super.key});

  @override
  ConsumerState<ViCoinScreen> createState() => _ViCoinScreenState();
}

class _ViCoinScreenState extends ConsumerState<ViCoinScreen> {
  late final AppLifecycleListener _vongDoi;

  @override
  void initState() {
    super.initState();
    _vongDoi = AppLifecycleListener(
      onResume: () => ref.invalidate(donNapGanNhatProvider),
    );
  }

  @override
  void dispose() {
    _vongDoi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viAsync = ref.watch(viCoinProvider);
    final proAsync = ref.watch(thanhVienProvider);
    final donNap = ref.watch(donNapGanNhatProvider);

    return Trang(
      con: [
        TieuDeMuc(
          chu: 'Ví Coin',
          hanhDong: TextButton.icon(
            onPressed: () => context.go(DuongDan.hoSo),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Hồ sơ'),
          ),
        ),
        if (ref.watch(daDangNhapProvider)) ...[
          const TheCoinThuong(),
          const SizedBox(height: 16),
        ],
        KhiAsync(
          gia: viAsync.hasValue ? AsyncData(viAsync.value) : viAsync,
          thuLai: () => ref.invalidate(viCoinProvider),
          khiCo: (vi) {
            if (vi == null) {
              return KhoiRong(
                bieuTuong: Icons.account_balance_wallet_outlined,
                tieuDe: 'Chưa có ví',
                moTa: 'Đăng nhập để xem ví Coin của bạn.',
                hanhDong: FilledButton(
                  onPressed: () =>
                      context.go(DuongDan.dangNhapRoiVe(DuongDan.viCoin)),
                  child: const Text('Đăng nhập'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(DuongDan.napCoin),
                      icon: const Icon(Icons.add_card),
                      label: const Text('Nạp Coin'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(DuongDan.nangCapPro),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Đổi gói Pro'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (donNap.value case final don? when !don.daXong)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(don.moTaTrangThai),
                    subtitle: const Text('Xem đơn nạp Coin'),
                    onTap: () => context.go(DuongDan.napCoin),
                  ),
                _TheTrangThaiPro(proAsync: proAsync),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(DuongDan.lichSuGiaoDich),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _DanhSachGiaoDichNgan(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TheTrangThaiPro extends StatelessWidget {
  final AsyncValue<dynamic> proAsync;
  const _TheTrangThaiPro({required this.proAsync});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      color: Colors.amber.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gói thành viên Flutter Academy',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  proAsync.when(
                    data: (tv) => Text(
                      tv.isPro && !tv.daHetHan
                          ? 'Đang kích hoạt Pro (${tv.soNgayConLai} ngày còn lại)'
                          : 'Tài khoản thường (Miễn phí)',
                      style: t.bodyMedium?.copyWith(
                        color: tv.isPro
                            ? Colors.amber.shade900
                            : mau.onSurfaceVariant,
                        fontWeight: tv.isPro
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    loading: () => const Text('Đang tải...'),
                    error: (_, _) => const Text('Không tải được trạng thái'),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.go(DuongDan.nangCapPro),
              child: const Text('Nâng cấp'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DanhSachGiaoDichNgan extends ConsumerWidget {
  const _DanhSachGiaoDichNgan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lichSu = ref.watch(lichSuGiaoDichProvider);

    return lichSu.when(
      data: (ds) {
        if (ds.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Chưa có giao dịch Coin nào.')),
          );
        }
        return Column(
          children: [
            for (final gd in ds.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: gd.laCongCoin
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  child: Text(gd.type.bieuTuong),
                ),
                title: Text(
                  gd.description ?? gd.type.ten,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  gd.dangCho ? 'Đang chờ cấp Coin' : gd.createdAt,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                trailing: Text(
                  '${gd.soCoinHienThi} Coin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: gd.laCongCoin ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(lichSuGiaoDichProvider),
        child: const Text('Chưa tải được giao dịch. Thử lại'),
      ),
    );
  }
}
