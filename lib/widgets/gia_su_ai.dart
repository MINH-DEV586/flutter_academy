import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/kho_gia_su_ai.dart';
import '../models/gia_su_ai.dart';
import '../viewmodels/gia_su_ai_vm.dart';

class GiaSuAi extends ConsumerStatefulWidget {
  const GiaSuAi({
    super.key,
    required this.khoa,
    required this.tenBai,
    required this.onDong,
    this.onHoiThanhCong,
    this.onDangNhap,
    this.thongBao,
    this.dangTai = false,
    this.thuLai,
  });

  final HoiThoaiTutor? khoa;
  final String tenBai;
  final VoidCallback onDong;
  final VoidCallback? onHoiThanhCong;
  final VoidCallback? onDangNhap;
  final String? thongBao;
  final bool dangTai;
  final VoidCallback? thuLai;

  @override
  ConsumerState<GiaSuAi> createState() => _GiaSuAiState();
}

class _GiaSuAiState extends ConsumerState<GiaSuAi> {
  final _nhap = TextEditingController();
  final _cuon = ScrollController();
  String _mucDo = 'coBan';

  @override
  void initState() {
    super.initState();
    _cuonCuoi();
  }

  @override
  void dispose() {
    _nhap.dispose();
    _cuon.dispose();
    super.dispose();
  }

  void _cuonCuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cuon.hasClients) {
        _cuon.jumpTo(_cuon.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final khoa = widget.khoa;
    final vm = khoa == null ? null : giaSuAiProvider(khoa);
    final chat = vm == null ? null : ref.watch(vm);
    if (vm != null) {
      ref.listen(vm, (truoc, sau) {
        if (!_cuon.hasClients || _cuon.position.extentAfter < 140) _cuonCuoi();
        if (truoc?.dangTraLoi == true &&
            !sau.dangTraLoi &&
            sau.lichSu.last.hoanTat) {
          widget.onHoiThanhCong?.call();
        }
      });
    }
    final busy = chat?.dangTraLoi ?? false;
    final lichSu = chat?.lichSu ?? const <LuotHoiTutor>[];
    final loi = chat?.loi;
    void gui() {
      final cau = _nhap.text.trim();
      if (cau.isEmpty || cau.runes.length > KhoGiaSuAi.gioiHanCauHoi || busy) {
        return;
      }
      ref.read(vm!.notifier).hoi(cau, _mucDo);
      _nhap.clear();
      _cuonCuoi();
    }

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gia sư AI', style: theme.textTheme.titleMedium),
                      Text(
                        widget.tenBai,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng Gia sư AI',
                  onPressed: widget.onDong,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: _cuon,
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (lichSu.isEmpty)
                  Text(
                    widget.thongBao ??
                        (khoa == null
                            ? 'Đăng nhập để lưu và tiếp tục hội thoại.'
                            : 'Bạn muốn hiểu thêm điều gì trong bài này?'),
                  ),
                if (widget.dangTai) const LinearProgressIndicator(),
                if (widget.thuLai case final thuLai?)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: thuLai,
                      child: const Text('Thử lại'),
                    ),
                  ),
                if (khoa == null &&
                    widget.thongBao == null &&
                    widget.onDangNhap != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: widget.onDangNhap,
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                for (final (i, muc) in lichSu.indexed)
                  _LuotHoi(
                    muc: muc,
                    thuLai: !busy && !muc.hoanTat
                        ? () {
                            ref
                                .read(vm!.notifier)
                                .hoi(muc.cauHoi, muc.mucDo, thayLuot: i);
                            _cuonCuoi();
                          }
                        : null,
                    moNguon: _moNguon,
                    chon: (dapAn) => ref.read(vm!.notifier).chonDapAn(i, dapAn),
                  ),
                if (busy) ...[
                  const LinearProgressIndicator(semanticsLabel: 'Đang trả lời'),
                  const SizedBox(height: 4),
                  const Text('Đang trả lời…'),
                ],
                if (loi != null)
                  Text(
                    _thongBao(loi),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
          if (khoa != null)
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButton<String>(
                      value: _mucDo,
                      onChanged: busy
                          ? null
                          : (muc) => setState(() => _mucDo = muc!),
                      items: const [
                        DropdownMenuItem(value: 'coBan', child: Text('Cơ bản')),
                        DropdownMenuItem(
                          value: 'trungCap',
                          child: Text('Trung cấp'),
                        ),
                        DropdownMenuItem(
                          value: 'chuyenSau',
                          child: Text('Chuyên sâu'),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nhap,
                          maxLines: 2,
                          minLines: 1,
                          maxLength: KhoGiaSuAi.gioiHanCauHoi,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => gui(),
                          decoration: const InputDecoration(
                            labelText: 'Hỏi về bài học',
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Gửi câu hỏi',
                        onPressed: busy ? null : gui,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _moNguon(String duongDan) async {
    final uri = ref.read(khoGiaSuAiProvider).diaChiNguon(duongDan);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Hiện thông báo chung nếu nền tảng không mở được liên kết.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa mở được trang tài liệu.')),
      );
    }
  }

  String _thongBao(LoiTutor loi) {
    final resetAt = loi.resetAt;
    if (resetAt == null) return loi.thongBao;
    final gioVn = resetAt.toUtc().add(const Duration(hours: 7));
    return '${loi.thongBao} Lượt mới lúc 00:00 ngày ${gioVn.day}/${gioVn.month} (giờ Việt Nam).';
  }
}

class _LuotHoi extends StatelessWidget {
  const _LuotHoi({
    required this.muc,
    required this.thuLai,
    required this.moNguon,
    required this.chon,
  });

  final LuotHoiTutor muc;
  final VoidCallback? thuLai;
  final ValueChanged<String> moNguon;
  final ValueChanged<int> chon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nguon = muc.nguon;
    final quiz = muc.quiz;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  muc.cauHoi,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ),
          if (muc.demo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Bản trả lời Demo',
                style: theme.textTheme.labelMedium,
              ),
            ),
          if (muc.traLoi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(
                muc.traLoi,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (thuLai != null)
            TextButton(onPressed: thuLai, child: const Text('Thử trả lời lại')),
          if (nguon != null)
            TextButton(
              onPressed: () => moNguon(nguon['duongDan'] as String),
              child: Text('Trang ${nguon['trang']} · ${nguon['ten']}'),
            ),
          if (quiz != null)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Trắc nghiệm nhanh',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(quiz['cauHoi'] as String),
                    for (final (i, dapAn) in (quiz['luaChon'] as List).indexed)
                      OutlinedButton(
                        onPressed: muc.daChon == null ? () => chon(i) : null,
                        child: Text(dapAn as String),
                      ),
                    if (muc.daChon != null)
                      Text(
                        muc.daChon == quiz['dung']
                            ? 'Đúng. ${quiz['giaiThich']}'
                            : 'Chưa đúng. ${quiz['giaiThich']}',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
