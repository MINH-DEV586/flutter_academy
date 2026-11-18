import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../data/vi_hardhat.dart';
import '../viewmodels/providers.dart';
import 'trang_thai.dart';

class TheThuongHoc extends ConsumerStatefulWidget {
  const TheThuongHoc({super.key});

  @override
  ConsumerState<TheThuongHoc> createState() => _TheThuongHocState();
}

class _TheThuongHocState extends ConsumerState<TheThuongHoc> {
  final _maGiaoDich = TextEditingController();
  bool _dangXuLy = false;
  String? _thongBao;

  @override
  void dispose() {
    _maGiaoDich.dispose();
    super.dispose();
  }

  Future<void> _doi({required bool moi}) async {
    if (_dangXuLy) return;
    setState(() {
      _dangXuLy = true;
      _thongBao = null;
    });
    final kho = ref.read(khoNguoiDungProvider);
    final nguoiDung = ref.read(phienProvider).asData?.value;
    try {
      var hash = _maGiaoDich.text.trim();
      if (moi) {
        final vi = await ketNoiVi();
        if (!mounted || ref.read(phienProvider).asData?.value != nguoiDung)
          return;
        final payload = await kho.yeuCauDoiPro(vi);
        if (!mounted || ref.read(phienProvider).asData?.value != nguoiDung)
          return;
        hash = await guiGiaoDichDoiPro(vi, payload);
        if (!mounted || ref.read(phienProvider).asData?.value != nguoiDung)
          return;
        _maGiaoDich.text = hash;
      }
      await kho.xacNhanDoiPro(hash);
      if (!mounted) return;
      _maGiaoDich.clear();
      ref.invalidate(thuongHocProvider);
      setState(() => _thongBao = 'Đã xác minh giao dịch và kích hoạt Pro.');
    } catch (loi) {
      if (mounted) {
        setState(
          () => _thongBao = loi is LoiTaiKhoan ? loi.thongBao : 'Chưa hoàn tất giao dịch. Kiểm tra MetaMask và mạng Hardhat rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  String _ngayVietNam(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      ms,
      isUtc: true,
    ).add(const Duration(hours: 7));
    final gio = d.hour.toString().padLeft(2, '0');
    final phut = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} lúc $gio:$phut (giờ Việt Nam)';
  }

  @override
  Widget build(BuildContext context) => KhiAsync(
    gia: ref.watch(thuongHocProvider),
    thuLai: () => ref.invalidate(thuongHocProvider),
    khiCo: (thuong) {
      if (thuong == null) return const SizedBox.shrink();
      final t = Theme.of(context).textTheme;
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text('Chuỗi ngày học và xu', style: t.titleLarge),
              Text('${thuong.chuoi} ngày liên tiếp · ${thuong.xu} xu'),
              Text(
                thuong.daHocHomNay
                    ? 'Đã ghi nhận ngày học hôm nay.'
                    : 'Hoàn thành một bài để ghi nhận ngày học hôm nay.',
              ),
              const Text('Mốc 3 ngày nhận 10 xu. Mốc 7 ngày nhận thêm 20 xu.'),
              const Divider(),
              Text(
                thuong.pro ? 'Đang dùng Pro' : 'Đổi Pro',
                style: t.titleLarge,
              ),
              if (thuong.pro) Text('Pro đến ${_ngayVietNam(thuong.proDen)}'),
              Text('AI hôm nay: ${thuong.daDungAi}/${thuong.gioiHanAi} lượt'),
              const Text(
                'Đổi 30 xu lấy 7 ngày Pro. Xác nhận bằng MetaMask trên Hardhat.',
              ),
              FilledButton.icon(
                onPressed:
                    _dangXuLy || thuong.xu < 30 || _maGiaoDich.text.isNotEmpty
                    ? null
                    : () => _doi(moi: true),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(
                  _dangXuLy ? 'Đang xác minh…' : 'Đổi 7 ngày Pro · 30 xu',
                ),
              ),
              if (_thongBao != null)
                Semantics(liveRegion: true, child: Text(_thongBao!)),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Kiểm tra giao dịch đã gửi'),
                initiallyExpanded: _maGiaoDich.text.isNotEmpty,
                children: [
                  TextField(
                    controller: _maGiaoDich,
                    enabled: !_dangXuLy,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Mã giao dịch Hardhat',
                    ),
                  ),
                  TextButton(
                    onPressed: _dangXuLy || _maGiaoDich.text.trim().isEmpty
                        ? null
                        : () => _doi(moi: false),
                    child: const Text('Xác minh giao dịch'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
