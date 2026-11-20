import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/vi_coin.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Màn hình Ví Coin cá nhân của học viên.
class ViCoinScreen extends ConsumerWidget {
  const ViCoinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viAsync = ref.watch(viCoinProvider);
    final proAsync = ref.watch(thanhVienProvider);

    return Trang(
      con: [
        TieuDeMuc(
          chu: 'Ví Coin & Blockchain',
          hanhDong: TextButton.icon(
            onPressed: () => context.go(DuongDan.hoSo),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Hồ sơ'),
          ),
        ),
        KhiAsync(
          gia: viAsync,
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
                _TheSoDuCoin(vi: vi),
                const SizedBox(height: 16),
                _TheMetaMask(vi: vi),
                const SizedBox(height: 16),
                _TheTrangThaiPro(proAsync: proAsync),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
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

class _TheSoDuCoin extends StatelessWidget {
  final ViCoin vi;
  const _TheSoDuCoin({required this.vi});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      color: mau.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on, color: mau.onPrimaryContainer, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Số dư Coin',
                  style: t.titleMedium?.copyWith(
                    color: mau.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${vi.coinBalance} Coin',
              style: t.displaySmall?.copyWith(
                color: mau.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: mau.primary,
                    foregroundColor: mau.onPrimary,
                  ),
                  onPressed: () => context.go(DuongDan.napCoin),
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Nạp Coin (MetaMask)'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mau.onPrimaryContainer,
                    side: BorderSide(color: mau.onPrimaryContainer.withValues(alpha: 0.5)),
                  ),
                  onPressed: () => context.go(DuongDan.nangCapPro),
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('Đổi gói Pro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TheMetaMask extends ConsumerStatefulWidget {
  final ViCoin vi;
  const _TheMetaMask({required this.vi});

  @override
  ConsumerState<_TheMetaMask> createState() => _TheMetaMaskState();
}

class _TheMetaMaskState extends ConsumerState<_TheMetaMask> {
  bool _dangKetNoi = false;

  void _xuLyKetNoi() async {
    setState(() => _dangKetNoi = true);
    final loi = await ref.read(viCoinProvider.notifier).ketNoiMetaMask();
    if (!mounted) return;
    setState(() => _dangKetNoi = false);

    if (loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loi), backgroundColor: Colors.red.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kết nối ví MetaMask thành công! 🦊'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _xuLyHuyKetNoi() async {
    await ref.read(viCoinProvider.notifier).huyLienKetMetaMask();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ngắt liên kết ví MetaMask.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vi = widget.vi;
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🦊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  'Ví MetaMask (Local / Sepolia)',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (vi.daLienKetVi)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Đã kết nối',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: mau.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Chưa kết nối',
                      style: TextStyle(color: mau.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (vi.daLienKetVi) ...[
              Text(
                'Địa chỉ ví: ${vi.metamaskAddress}',
                style: t.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _xuLyHuyKetNoi,
                icon: const Icon(Icons.link_off, size: 16),
                label: const Text('Ngắt kết nối ví'),
              ),
            ] else ...[
              Text(
                'Kết nối ví MetaMask để nạp Coin qua mạng Sepolia Testnet.',
                style: t.bodyMedium?.copyWith(color: mau.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _dangKetNoi ? null : _xuLyKetNoi,
                icon: _dangKetNoi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet, size: 18),
                label: Text(_dangKetNoi ? 'Đang kết nối...' : 'Kết nối MetaMask'),
              ),
            ],
          ],
        ),
      ),
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
                        color: tv.isPro ? Colors.amber.shade900 : mau.onSurfaceVariant,
                        fontWeight: tv.isPro ? FontWeight.w600 : FontWeight.normal,
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
                  gd.createdAt,
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
      error: (e, _) => Text('Lỗi: $e'),
    );
  }
}
