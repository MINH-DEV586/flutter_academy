import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';

/// Màn hình lịch sử giao dịch Coin chi tiết.
class LichSuGiaoDichScreen extends ConsumerWidget {
  const LichSuGiaoDichScreen({super.key});

  void _moEtherscan(String txHash) {
    final uri = Uri.parse('https://sepolia.etherscan.io/tx/$txHash');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lichSu = ref.watch(lichSuGiaoDichProvider);
    final mau = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Trang(
      con: [
        TieuDeMuc(
          chu: 'Lịch sử giao dịch Coin',
          hanhDong: TextButton.icon(
            onPressed: () => context.go(DuongDan.viCoin),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Ví Coin'),
          ),
        ),
        lichSu.when(
          data: (ds) {
            if (ds.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: mau.outline),
                        const SizedBox(height: 12),
                        const Text('Bạn chưa có giao dịch Coin nào.'),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final gd in ds)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: gd.laCongCoin
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            child: Text(gd.type.bieuTuong, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gd.description ?? gd.type.ten,
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thời gian: ${gd.createdAt}',
                                  style: t.bodySmall?.copyWith(color: mau.outline),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Số dư: ${gd.balanceBefore} → ${gd.balanceAfter} Coin',
                                  style: t.bodySmall?.copyWith(color: mau.onSurfaceVariant),
                                ),
                                if (gd.transactionHash != null && gd.transactionHash!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _moEtherscan(gd.transactionHash!),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tx: ${gd.txHashRutGon} (Sepolia Etherscan)',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${gd.soCoinHienThi} Coin',
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: gd.laCongCoin ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('Lỗi tải lịch sử: $e')),
        ),
      ],
    );
  }
}
