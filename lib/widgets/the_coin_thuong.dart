import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/kho_thuong_chuoi.dart';
import '../data/mo_trang_metamask.dart';
import '../dinh_tuyen/duong_dan.dart';
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
  String? _dangNhanId;
  String? _vuaYeuCauNhan;
  String? _loiNhan;
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
          () => _ketQuaKiemTra = switch ((
            ref.read(dongBoThuongProvider),
            trang?.loiMang,
          )) {
            (> 0, _) => 'Bài học đang chờ đồng bộ. Hãy thử lại.',
            (_, String()) => 'Chưa đối soát được với ví. Hãy thử lại.',
            _ => 'Đã cập nhật Coin.',
          },
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

  void _hienLichSu(TrangThaiThuongChuoi tt) {
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
              'Lịch sử thưởng chuỗi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (tt.lichSu.isEmpty)
              const ListTile(title: Text('Chưa có mốc thưởng đã ghi nhận.')),
            for (final item in tt.lichSu)
              ListTile(
                title: Text('+${item.coin} Coin · Mốc ${item.mocNgay} ngày'),
                subtitle: Text(
                  [
                    if (item.thoiDiem case final moc?) _hienThoiDiem(moc, ngay),
                    _trangThaiCap(tt, item.trangThai),
                  ].join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _trangThaiCap(TrangThaiThuongChuoi tt, String? trangThai) =>
      switch (trangThai) {
        'issued' => 'Đã nhận',
        'submitted' => 'Chờ xác nhận trên Hardhat',
        'claiming' => 'Đang cấp vào ví',
        _ when !tt.daKetNoiVi => 'Chờ xác minh ví',
        _ => 'Có thể nhận',
      };

  Future<void> _nhanCoin(String id) async {
    if (_dangNhanId != null) return;
    final email = ref.read(emailHocVienProvider);
    bool cungPhien() => mounted && ref.read(emailHocVienProvider) == email;
    setState(() {
      _dangNhanId = id;
      _vuaYeuCauNhan = id;
      _loiNhan = null;
    });
    try {
      await ref.read(trangThaiThuongProvider.notifier).nhanCoin(id);
    } on LoiThuongChuoi catch (loi) {
      if (cungPhien()) setState(() => _loiNhan = loi.thongBao);
    } catch (_) {
      if (cungPhien()) {
        setState(
          () => _loiNhan = 'Chưa gửi được yêu cầu nhận thưởng. Hãy thử lại.',
        );
      }
    } finally {
      if (cungPhien()) setState(() => _dangNhanId = null);
    }
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
        _dangNhanId = null;
        _vuaYeuCauNhan = null;
        _loiNhan = null;
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
            Text('Số dư Coin', style: Theme.of(context).textTheme.titleSmall),
            if (trang.asData?.value case final tinhTrang?)
              _noiDung(tinhTrang)
            else if (trang.isLoading && !_dangKiemTra)
              const KhoiDangTai(nhan: 'Đang tải Coin'),
            if (trang.hasError && _ketQuaKiemTra == null)
              const Text('Chưa tải được Coin. Kiểm tra kết nối rồi thử lại.'),
            if (_dangKiemTra || (trang.hasValue && trang.isLoading))
              const LinearProgressIndicator(
                semanticsLabel: 'Đang kiểm tra Coin',
              ),
            if (_ketQuaKiemTra case final thongBao?)
              Semantics(liveRegion: true, child: Text(thongBao)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (trang.asData?.value case final tinhTrang?)
                  TextButton.icon(
                    icon: const Icon(Icons.history),
                    onPressed: () => _hienLichSu(tinhTrang),
                    label: const Text('Lịch sử nhận thưởng'),
                  ),
                if (!widget.hienVi)
                  TextButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    onPressed: () => context.go(DuongDan.viCoin),
                    label: const Text('Xem ví'),
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
    final mucDat = tt.moc.where((muc) => muc.trangThai != null).lastOrNull;
    final moiNhan =
        _vuaYeuCauNhan != null &&
        tt.lichSu.any(
          (muc) => muc.id == _vuaYeuCauNhan && muc.trangThai == 'issued',
        );
    final baiChoDongBo = ref.watch(dongBoThuongProvider);
    final giaoDien = Theme.of(context);
    final mau = giaoDien.colorScheme;
    final chu = giaoDien.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            tt.soDu == null ? 'Số dư Coin chưa khả dụng' : '${tt.soDu} Coin',
            style: chu.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mau.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_events_outlined, color: mau.onPrimaryContainer),
              const SizedBox(height: 6),
              Text(
                tt.soNgay > 0
                    ? 'Bạn đã đạt chuỗi ${tt.soNgay} ngày!'
                    : 'Thưởng chuỗi học',
                style: chu.titleMedium?.copyWith(
                  color: mau.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (mucDat != null) ...[
                const SizedBox(height: 8),
                Text(
                  '+${mucDat.coin} Coin',
                  style: chu.headlineMedium?.copyWith(
                    color: mau.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Mốc ${mucDat.ngay} ngày · ${_trangThaiCap(tt, mucDat.trangThai)}',
                  style: TextStyle(color: mau.onPrimaryContainer),
                ),
              ],
              if (mucTiep != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Mốc tiếp theo ${tt.soNgay}/${mucTiep.ngay} ngày · +${mucTiep.coin} Coin',
                  style: TextStyle(color: mau.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: tt.soNgay / mucTiep.ngay,
                  semanticsLabel: 'Tiến độ mốc tiếp theo',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Chuỗi thưởng tính theo ngày có bài học hoàn thành.'),
        if (baiChoDongBo > 0) Text('$baiChoDongBo bài đang chờ đồng bộ.'),
        if (moiNhan)
          Semantics(
            liveRegion: true,
            child: const Text('Nhận thưởng thành công.'),
          ),
        if (tt.coinDangCho > 0 && !tt.daKetNoiVi)
          Text('${tt.coinDangCho} Coin chờ xác minh ví MetaMask.'),
        if (tt.coinChoGiaoDich > 0)
          Text(
            tt.diaChiVi == null
                ? '${tt.coinChoGiaoDich} Coin chờ xác minh ví MetaMask.'
                : '${tt.coinChoGiaoDich} Coin đang chờ cấp vào ví.',
          ),
        if (tt.daKetNoiVi)
          for (final muc in tt.lichSu)
            if (muc.id case final id? when muc.trangThai == 'pending')
              FilledButton(
                onPressed: _dangNhanId != null ? null : () => _nhanCoin(id),
                child: Text(
                  _dangNhanId == id
                      ? 'Đang gửi yêu cầu…'
                      : 'Nhận ${muc.coin} Coin · Mốc ${muc.mocNgay} ngày',
                ),
              ),
        if (_loiNhan case final thongBao?)
          Semantics(liveRegion: true, child: Text(thongBao)),
        if (_loi case final thongBao?) Text(thongBao),
        if (tt.loiMang != null)
          const Text('Chưa đối soát được với ví. Hãy kiểm tra trạng thái.'),
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
          const Text('Kết nối ví Coin tạm thời chưa khả dụng.'),
        if (_trangThaiKy(tt) case final nhan?) Text(nhan),
        if (tt.hanPro case final hanPro?)
          Text(
            'Hạn Pro ${MaterialLocalizations.of(context).formatShortDate(hanPro.toLocal())}',
          ),
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
                child: Text('Đổi $gia Coin lấy $soNgay ngày Pro'),
              ),
            if (tt.daKetNoiVi &&
                gia != null &&
                soNgay != null &&
                tt.soDu != null &&
                tt.soDu! < gia)
              Text('Gói Pro $soNgay ngày cần $gia Coin.'),
            if (tt.daKetNoiVi)
              TextButton(
                onPressed: _dangMo ? null : _ngatKetNoi,
                child: const Text('Ngắt kết nối ví Coin'),
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
            title: const Text('Chi tiết ví Coin'),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (diaChi != null) SelectableText(diaChi),
              if (tt.chainId != null) Text('Hardhat Local · ID ${tt.chainId}'),
              if (tt.txHash case final hash?) SelectableText('Giao dịch $hash'),
            ],
          ),
      ],
    );
  }
}
