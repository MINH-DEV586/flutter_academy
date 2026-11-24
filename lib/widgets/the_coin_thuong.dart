import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/kho_thuong_chuoi.dart';
import '../data/mo_trang_metamask.dart';
import '../models/thuong_chuoi.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/thuong_chuoi_vm.dart';
import 'trang_thai.dart';

class TheCoinThuong extends ConsumerStatefulWidget {
  const TheCoinThuong({super.key, this.hienVi = true});
  final bool hienVi;

  @override
  ConsumerState<TheCoinThuong> createState() => _TheCoinThuongState();
}

class _TheCoinThuongState extends ConsumerState<TheCoinThuong> {
  late final AppLifecycleListener _vongDoi;
  Uri? _trangKy;
  bool _kyDoiPro = false;
  bool _dangMo = false;
  String? _loi;
  bool _dangKiemTra = false;
  String? _ketQuaKiemTra;

  @override
  void initState() {
    super.initState();
    _vongDoi = AppLifecycleListener(onResume: _lamMoi);
  }

  @override
  void dispose() {
    _vongDoi.dispose();
    super.dispose();
  }

  void _lamMoi() => ref.invalidate(trangThaiThuongProvider);

  Future<void> _kiemTra() async {
    if (_dangKiemTra) return;
    final email = ref.read(phienProvider).asData?.value?.email;
    setState(() {
      _dangKiemTra = true;
      _ketQuaKiemTra = null;
    });
    try {
      await ref.read(dongBoThuongProvider.notifier).thuLai();
      if (!mounted || ref.read(phienProvider).asData?.value?.email != email) {
        return;
      }
      final trang = await ref.refresh(trangThaiThuongProvider.future);
      if (mounted && ref.read(phienProvider).asData?.value?.email == email) {
        setState(
          () => _ketQuaKiemTra = trang?.loiMang == null
              ? 'Đã cập nhật Coin thưởng.'
              : 'Chưa đối soát được với ví. Hãy thử lại.',
        );
      }
    } catch (_) {
      if (mounted && ref.read(phienProvider).asData?.value?.email == email) {
        setState(
          () => _ketQuaKiemTra = 'Chưa kết nối được máy chủ. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _dangKiemTra = false);
    }
  }

  Future<void> _ngatKetNoi() async {
    setState(() {
      _dangMo = true;
      _loi = null;
    });
    try {
      await ref.read(trangThaiThuongProvider.notifier).ngatKetNoiVi();
      if (mounted) setState(() => _trangKy = null);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Chưa ngắt được kết nối. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangMo = false);
    }
  }

  void _hienLichSu(List<NhanCoinThuong> lichSu) {
    final ngay = MaterialLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .7,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Lịch sử Coin thưởng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (lichSu.isEmpty)
              const ListTile(title: Text('Chưa có mốc thưởng đã ghi nhận.')),
            for (final item in lichSu)
              ListTile(
                title: Text('+${item.coin} Coin · Mốc ${item.mocNgay} ngày'),
                subtitle: Text(
                  [
                    if (item.thoiDiem case final moc?) _hienThoiDiem(moc, ngay),
                    switch (item.trangThai) {
                      'issued' => 'Đã nhận',
                      'submitted' => 'Đang xác nhận',
                      _ => 'Chờ cấp vào ví',
                    },
                  ].join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _hienThoiDiem(String moTa, MaterialLocalizations ngonNgu) {
    final date = DateTime.tryParse(moTa);
    if (date == null) return moTa;
    if (moTa.length == 10) return ngonNgu.formatShortDate(date);
    final gioVietNam = date.toUtc().add(const Duration(hours: 7));
    return '${ngonNgu.formatShortDate(gioVietNam)} ${ngonNgu.formatTimeOfDay(TimeOfDay.fromDateTime(gioVietNam), alwaysUse24HourFormat: true)} (giờ VN)';
  }

  Future<void> _chuanBi({required bool doiPro}) async {
    final email = ref.read(phienProvider).asData?.value?.email;
    setState(() {
      _dangMo = true;
      _loi = null;
      _trangKy = null;
    });
    try {
      final trang = await ref
          .read(trangThaiThuongProvider.notifier)
          .moVi(doiPro: doiPro);
      if (!mounted || ref.read(phienProvider).asData?.value?.email != email) {
        return;
      }
      setState(() {
        _trangKy = trang;
        _kyDoiPro = doiPro;
      });
      _lamMoi();
      if (dungMetaMaskMobile) {
        await _moTrangKy(trang);
      }
    } on LoiThuongChuoi catch (loi) {
      if (mounted) setState(() => _loi = loi.thongBao);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Chưa mở được yêu cầu MetaMask. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangMo = false);
    }
  }

  Future<void> _moTrangKy(Uri trang) async {
    try {
      final thongBao = await moTrangMetaMask(trang);
      if (mounted) setState(() => _loi = thongBao);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Chưa mở được MetaMask. Hãy thử mở lại.');
      }
    }
  }

  String? _trangThaiKy(TrangThaiThuongChuoi tt) =>
      switch (tt.daKetNoiVi ? tt.doiPro : tt.dangLienKet ?? tt.doiPro) {
        'signing' => 'Đang chờ ký trong MetaMask.',
        'rejected' => 'Bạn đã từ chối yêu cầu. Có thể thử lại.',
        'confirming' => 'Đã gửi giao dịch. Đang chờ xác nhận.',
        'failed' => 'Yêu cầu chưa thành công. Kiểm tra mạng và thử lại.',
        'completed' => 'Đã kích hoạt Pro.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(phienProvider, (cu, moi) {
      if (cu?.asData?.value?.email == moi.asData?.value?.email) return;
      setState(() {
        _trangKy = null;
        _loi = null;
        _ketQuaKiemTra = null;
        _dangMo = false;
      });
    });
    if (!ref.watch(daDangNhapProvider) ||
        ref.watch(khoThuongChuoiProvider) == null) {
      return const SizedBox.shrink();
    }
    final trang = ref.watch(trangThaiThuongProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coin thưởng học tập',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (trang.value case final tinhTrang?)
              _noiDung(tinhTrang)
            else if (trang.isLoading && !_dangKiemTra)
              const KhoiDangTai(nhan: 'Đang tải Coin thưởng'),
            if (trang.hasError && _ketQuaKiemTra == null)
              const Text(
                'Chưa tải được Coin thưởng. Kiểm tra kết nối rồi thử lại.',
              ),
            if (_dangKiemTra)
              const LinearProgressIndicator(
                semanticsLabel: 'Đang kiểm tra Coin thưởng',
              ),
            if (_ketQuaKiemTra case final thongBao?)
              Semantics(liveRegion: true, child: Text(thongBao)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (trang.value case final tinhTrang?)
                  TextButton.icon(
                    icon: const Icon(Icons.history),
                    onPressed: () => _hienLichSu(tinhTrang.lichSu),
                    label: const Text('Lịch sử nhận thưởng'),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: _dangKiemTra ? null : _kiemTra,
                  label: Text(
                    _dangKiemTra ? 'Đang kiểm tra…' : 'Kiểm tra trạng thái',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noiDung(TrangThaiThuongChuoi tt) {
    final mucTiep = tt.mocTiepTheo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          tt.soDu == null ? 'Số dư chưa khả dụng' : '${tt.soDu} Coin thưởng',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('${tt.soNgay} ngày hoàn thành bài liên tiếp'),
        if (widget.hienVi)
          const Text('Dùng Coin thưởng học tập để đổi gói Pro từ phần thưởng.'),
        if (tt.coinDangCho > 0)
          Text('${tt.coinDangCho} Coin đang chờ cấp vào ví'),
        const SizedBox(height: 12),
        for (final muc in tt.moc)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(switch (muc.trangThai) {
              'issued' => Icons.check_circle,
              'submitted' || 'pending' => Icons.schedule,
              _ when muc == mucTiep => Icons.flag_outlined,
              _ => Icons.lock_outline,
            }),
            title: Text('${muc.ngay} ngày · +${muc.coin} Coin'),
            subtitle: Text(switch (muc.trangThai) {
              'issued' => 'Đã nhận',
              'submitted' || 'pending' => 'Đã đạt · Chờ nhận',
              _ when muc == mucTiep => 'Đang thực hiện',
              _ => 'Chưa đạt',
            }),
          ),
        if (mucTiep != null) ...[
          Text('Tiến độ mốc tiếp theo · ${tt.soNgay}/${mucTiep.ngay} ngày'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: tt.soNgay / mucTiep.ngay),
        ],
        if (widget.hienVi) _thaoTacVi(tt),
      ],
    );
  }

  Widget _thaoTacVi(TrangThaiThuongChuoi tt) {
    final diaChi = tt.diaChiVi;
    final trangKy = _trangKy;
    final gia = tt.giaDoiPro;
    final soNgay = tt.soNgayPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(),
        Text('Ví MetaMask', style: Theme.of(context).textTheme.titleMedium),
        Text(tt.daKetNoiVi ? 'Đã kết nối' : 'Chưa kết nối'),
        if (diaChi != null)
          Text(
            diaChi.length > 12
                ? '${diaChi.substring(0, 6)}…${diaChi.substring(diaChi.length - 4)}'
                : diaChi,
          ),
        if (!tt.blockchain)
          const Text('Kết nối ví thưởng tạm thời chưa khả dụng.'),
        if (_trangThaiKy(tt) case final nhan?) Text(nhan),
        if (tt.hanPro case final hanPro?)
          Text(
            'Hạn Pro ${MaterialLocalizations.of(context).formatShortDate(hanPro.toLocal())}',
          ),
        if (tt.loiMang != null)
          const Text('Chưa đọc được dữ liệu ví. Hãy kiểm tra trạng thái.'),
        if (_loi case final thongBao?) Text(thongBao),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (tt.blockchain && !tt.daKetNoiVi)
              FilledButton.tonal(
                onPressed: _dangMo ? null : () => _chuanBi(doiPro: false),
                child: Text(
                  diaChi == null ? 'Kết nối MetaMask' : 'Kết nối lại MetaMask',
                ),
              ),
            if (tt.daKetNoiVi &&
                gia != null &&
                soNgay != null &&
                (tt.soDu ?? 0) >= gia)
              FilledButton(
                onPressed: _dangMo || tt.doiPro == 'confirming'
                    ? null
                    : () => _chuanBi(doiPro: true),
                child: Text('Đổi $gia Coin thưởng lấy $soNgay ngày Pro'),
              ),
            if (tt.daKetNoiVi &&
                gia != null &&
                soNgay != null &&
                tt.soDu != null &&
                tt.soDu! < gia)
              Text('Gói Pro $soNgay ngày cần $gia Coin thưởng.'),
            if (tt.daKetNoiVi)
              TextButton(
                onPressed: _dangMo ? null : _ngatKetNoi,
                child: const Text('Ngắt kết nối ví thưởng'),
              ),
            if (trangKy != null &&
                (_kyDoiPro ? tt.doiPro != 'completed' : !tt.daKetNoiVi))
              OutlinedButton(
                onPressed: () => _moTrangKy(trangKy),
                child: const Text('Mở trang ký trong MetaMask'),
              ),
          ],
        ),
        if (_dangMo)
          const LinearProgressIndicator(semanticsLabel: 'Đang mở MetaMask'),
        if (diaChi != null || tt.txHash != null)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Chi tiết ví thưởng'),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (diaChi != null) SelectableText(diaChi),
              if (tt.chainId != null)
                Text('Mạng thử nghiệm · ID ${tt.chainId}'),
              if (tt.txHash case final hash?) SelectableText('Giao dịch $hash'),
            ],
          ),
      ],
    );
  }
}
