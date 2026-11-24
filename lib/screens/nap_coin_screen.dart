import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mo_trang_metamask.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../models/don_nap_coin.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/vi_coin_vm.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

class NapCoinScreen extends ConsumerStatefulWidget {
  const NapCoinScreen({super.key});

  @override
  ConsumerState<NapCoinScreen> createState() => _NapCoinScreenState();
}

class _NapCoinScreenState extends ConsumerState<NapCoinScreen> {
  late final AppLifecycleListener _vongDoi;
  GoiNapCoin? _goiChon;
  Uri? _trangKy;
  bool _dangChuanBi = false;
  String? _thongBao;

  @override
  void initState() {
    super.initState();
    _vongDoi = AppLifecycleListener(onResume: _kiemTra);
  }

  @override
  void dispose() {
    _vongDoi.dispose();
    super.dispose();
  }

  void _kiemTra() => ref.invalidate(donNapGanNhatProvider);

  Future<void> _thanhToan(String packageId, {String? orderId}) async {
    setState(() {
      _dangChuanBi = true;
      _trangKy = null;
      _thongBao = null;
    });
    try {
      final diaChi = await ref
          .read(viCoinProvider.notifier)
          .taoPhienNap(packageId, orderId: orderId);
      if (!mounted || diaChi == null) return;
      setState(() => _trangKy = diaChi);
      await _moVi(diaChi);
    } catch (_) {
      if (mounted) {
        setState(
          () => _thongBao =
              'Chưa chuẩn bị được thanh toán. Kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _dangChuanBi = false);
    }
  }

  Future<void> _moVi(Uri diaChi) async {
    try {
      final thongBao = await moTrangMetaMask(diaChi);
      if (mounted) setState(() => _thongBao = thongBao);
    } catch (_) {
      if (mounted) {
        setState(() => _thongBao = 'Chưa mở được MetaMask. Hãy thử mở lại.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(phienProvider, (cu, moi) {
      if (cu?.asData?.value?.email == moi.asData?.value?.email) return;
      setState(() {
        _goiChon = null;
        _trangKy = null;
        _thongBao = null;
      });
    });
    final daDangNhap = ref.watch(daDangNhapProvider);
    final text = Theme.of(context).textTheme;
    final goi = _goiChon;
    final don = daDangNhap
        ? ref.watch(donNapGanNhatProvider)
        : const AsyncData<DonNapCoin?>(null);

    return Trang(
      con: [
        TieuDeMuc(
          chu: 'Nạp Coin',
          hanhDong: TextButton.icon(
            onPressed: () => context.go(DuongDan.viCoin),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Ví Coin'),
          ),
        ),
        const Text(
          'Coin nạp được cộng vào số dư trong ứng dụng sau khi thanh toán được xác minh.',
        ),
        const SizedBox(height: 16),
        if (!daDangNhap)
          KhoiRong(
            bieuTuong: Icons.account_balance_wallet_outlined,
            tieuDe: 'Đăng nhập để nạp Coin',
            moTa: 'Đơn nạp và số dư được lưu theo tài khoản của bạn.',
            hanhDong: FilledButton(
              onPressed: () =>
                  context.go(DuongDan.dangNhapRoiVe(DuongDan.napCoin)),
              child: const Text('Đăng nhập'),
            ),
          )
        else ...[
          if (don.hasError || don.isLoading || don.value != null)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đơn nạp gần nhất', style: text.titleMedium),
                    if (don.value case final ganNhat?) ...[
                      Text(
                        '${ganNhat.coinAmount} Coin · ${ganNhat.ethAmount} ETH thử nghiệm',
                      ),
                      Text(ganNhat.moTaTrangThai),
                      if (ganNhat.coTheKy)
                        TextButton(
                          onPressed: _dangChuanBi || don.isLoading
                              ? null
                              : () => _thanhToan(
                                  ganNhat.packageId,
                                  orderId: ganNhat.orderId,
                                ),
                          child: const Text('Tiếp tục đơn nạp'),
                        ),
                    ],
                    if (don.isLoading)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Đang kiểm tra đơn nạp',
                      ),
                    if (don.hasError)
                      const Text(
                        'Chưa đọc được trạng thái đơn nạp. Kiểm tra kết nối và thử lại.',
                      ),
                    TextButton.icon(
                      onPressed: don.isLoading ? null : _kiemTra,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Kiểm tra đơn nạp'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Chọn gói nạp Coin', style: text.titleLarge),
          const SizedBox(height: 12),
          KhiAsync(
            gia: ref.watch(danhSachGoiNapProvider),
            thuLai: () => ref.invalidate(danhSachGoiNapProvider),
            khiCo: (cacGoi) => cacGoi.isEmpty
                ? const Text('Chưa có gói nạp khả dụng.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final muc in cacGoi)
                        ChoiceChip(
                          label: Text(
                            '${muc.coinAmount} Coin · ${muc.ethAmount} ETH',
                          ),
                          selected: muc.id == goi?.id,
                          onSelected: _dangChuanBi
                              ? null
                              : (_) => setState(() => _goiChon = muc),
                        ),
                    ],
                  ),
          ),
          if (goi != null) ...[
            const SizedBox(height: 16),
            Text('Thanh toán', style: text.titleMedium),
            Text('Nhận ${goi.coinAmount} Coin trong ứng dụng'),
            Text(
              '${goi.ethAmount} ETH thử nghiệm + phí mạng hiển thị trong MetaMask',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _dangChuanBi || don.value?.dangXacNhan == true
                  ? null
                  : () => _thanhToan(goi.id),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Xác nhận thanh toán'),
            ),
          ],
          if (_dangChuanBi)
            const LinearProgressIndicator(
              semanticsLabel: 'Đang chuẩn bị thanh toán',
            ),
          if (_trangKy case final diaChi?)
            if (don.value?.coTheKy != false)
              OutlinedButton(
                onPressed: _dangChuanBi ? null : () => _moVi(diaChi),
                child: const Text('Mở lại trang thanh toán'),
              ),
          if (_thongBao case final thongBao?)
            Semantics(liveRegion: true, child: Text(thongBao)),
        ],
      ],
    );
  }
}
