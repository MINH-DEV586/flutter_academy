import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../models/don_nap_coin.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';

/// Màn hình Nạp Coin bằng ví MetaMask qua Ethereum Sepolia Testnet.
class NapCoinScreen extends ConsumerStatefulWidget {
  const NapCoinScreen({super.key});

  @override
  ConsumerState<NapCoinScreen> createState() => _NapCoinScreenState();
}

class _NapCoinScreenState extends ConsumerState<NapCoinScreen> {
  String? _dangXuLyGoiId;
  String? _thongBaoLoi;

  void _napCoin(GoiNapCoin goi) async {
    setState(() {
      _dangXuLyGoiId = goi.id;
      _thongBaoLoi = null;
    });

    final loi = await ref.read(viCoinProvider.notifier).napCoin(
          packageId: goi.id,
          ethAmount: goi.ethAmount,
        );

    if (!mounted) return;
    setState(() {
      _dangXuLyGoiId = null;
      if (loi != null) {
        _thongBaoLoi = loi;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nạp thành công ${goi.coinAmount} Coin! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vi = ref.watch(viCoinProvider).asData?.value;
    final goiNapAsync = ref.watch(danhSachGoiNapProvider);
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Trang(
      con: [
        TieuDeMuc(
          chu: 'Nạp Coin qua MetaMask',
          hanhDong: TextButton.icon(
            onPressed: () => context.go(DuongDan.viCoin),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Ví Coin'),
          ),
        ),
        Card(
          color: mau.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mạng thử nghiệm: Ethereum Sepolia Testnet (Chain ID 11155111). '
                    'Thanh toán bằng Sepolia ETH (miễn phí nhận từ Faucet).',
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_thongBaoLoi != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_thongBaoLoi!, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (vi != null && !vi.daLienKetVi) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🦊', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  Text(
                    'Bạn cần kết nối ví MetaMask trước khi nạp Coin',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(viCoinProvider.notifier).ketNoiMetaMask(),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Kết nối MetaMask ngay'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Chọn gói nạp Coin',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        goiNapAsync.when(
          data: (dsGoi) {
            final danhSach = dsGoi.isNotEmpty
                ? dsGoi
                : const [
                    GoiNapCoin(id: 'pkg_50', coinAmount: 50, ethAmount: '0.005', name: '50 Coin'),
                    GoiNapCoin(id: 'pkg_100', coinAmount: 100, ethAmount: '0.01', name: '100 Coin'),
                    GoiNapCoin(id: 'pkg_250', coinAmount: 250, ethAmount: '0.025', name: '250 Coin'),
                    GoiNapCoin(id: 'pkg_500', coinAmount: 500, ethAmount: '0.05', name: '500 Coin'),
                    GoiNapCoin(id: 'pkg_1000', coinAmount: 1000, ethAmount: '0.1', name: '1000 Coin'),
                  ];

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final goi in danhSach)
                  _TheGoiNap(
                    goi: goi,
                    dangXuLy: _dangXuLyGoiId == goi.id,
                    onChon: vi?.daLienKetVi == true && _dangXuLyGoiId == null
                        ? () => _napCoin(goi)
                        : null,
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Không tải được danh sách gói nạp.'),
        ),
      ],
    );
  }
}

class _TheGoiNap extends StatelessWidget {
  final GoiNapCoin goi;
  final bool dangXuLy;
  final VoidCallback? onChon;

  const _TheGoiNap({
    required this.goi,
    required this.dangXuLy,
    required this.onChon,
  });

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mau.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mau.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
              const Spacer(),
              Text(
                '${goi.coinAmount}',
                style: t.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: mau.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Coin'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${goi.ethAmount} Sepolia ETH',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '+ Phí Gas mạng Sepolia',
            style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onChon,
              child: dangXuLy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Nạp ngay'),
            ),
          ),
        ],
      ),
    );
  }
}
