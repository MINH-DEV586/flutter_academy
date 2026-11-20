import 'package:material_ui/material_ui.dart';

import '../data/kho_gia_su_ai.dart';

enum _MucDo {
  coBan('Cơ bản'),
  trungCap('Trung cấp'),
  chuyenSau('Chuyên sâu');

  const _MucDo(this.nhan);
  final String nhan;
}

class GiaSuAi extends StatefulWidget {
  const GiaSuAi({
    super.key,
    required this.maBai,
    required this.tenBai,
    this.onHoiThanhCong,
  });

  final String maBai;
  final String tenBai;
  final VoidCallback? onHoiThanhCong;

  @override
  State<GiaSuAi> createState() => _GiaSuAiState();
}

class _GiaSuAiState extends State<GiaSuAi> {
  final _cauHoi = TextEditingController();
  var _mucDo = _MucDo.coBan;
  var _dangGui = false;
  var _loi = false;
  String? _cauTraLoi;

  @override
  void dispose() {
    _cauHoi.dispose();
    super.dispose();
  }

  Future<void> _gui(String cauHoi) async {
    final noiDung = cauHoi.trim();
    if (_dangGui || noiDung.isEmpty) return;
    setState(() {
      _dangGui = true;
      _loi = false;
      _cauTraLoi = null;
    });
    try {
      final traLoi = await KhoGiaSuAi.hoi(
        baiHoc: widget.maBai,
        cauHoi: noiDung,
        mucDo: _mucDo.name,
      );
      if (mounted) {
        setState(() => _cauTraLoi = traLoi);
        widget.onHoiThanhCong?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _loi = true);
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chu = Theme.of(context).textTheme;
    final daCauHinh = KhoGiaSuAi.diaChi.isNotEmpty;
    final traLoi = _cauTraLoi;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('AI Tutor', style: chu.titleLarge),
            Text('Đang học: ${widget.tenBai}', style: chu.bodyMedium),
            if (!daCauHinh)
              const Text('AI Tutor chưa được kết nối.')
            else ...[
              DropdownButtonFormField<_MucDo>(
                initialValue: _mucDo,
                decoration: const InputDecoration(labelText: 'Mức giải thích'),
                items: [
                  for (final muc in _MucDo.values)
                    DropdownMenuItem(value: muc, child: Text(muc.nhan)),
                ],
                onChanged: _dangGui
                    ? null
                    : (muc) {
                        if (muc != null) setState(() => _mucDo = muc);
                      },
              ),
              TextField(
                controller: _cauHoi,
                enabled: !_dangGui,
                maxLength: KhoGiaSuAi.gioiHanCauHoi,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Câu hỏi về bài học',
                  hintText: 'Ví dụ: Đoạn code trong bài hoạt động thế nào?',
                  border: OutlineInputBorder(),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _dangGui
                        ? null
                        : () {
                            const cauHoi =
                                'Giải thích đoạn code trong bài từng bước.';
                            _cauHoi.text = cauHoi;
                            _gui(cauHoi);
                          },
                    child: const Text('Giải thích code'),
                  ),
                  FilledButton.icon(
                    onPressed: _dangGui ? null : () => _gui(_cauHoi.text),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Gửi câu hỏi'),
                  ),
                ],
              ),
              if (_dangGui)
                const LinearProgressIndicator(
                  semanticsLabel: 'AI đang trả lời',
                ),
              if (_loi)
                Semantics(
                  liveRegion: true,
                  child: const Text(
                    'Chưa nhận được câu trả lời. Bạn có thể gửi lại.',
                  ),
                ),
              if (traLoi != null) ...[
                Text('Giải thích từ AI', style: chu.titleMedium),
                SelectableText(traLoi),
                Text(
                  'Tài liệu tham chiếu: ${widget.tenBai}',
                  style: chu.labelMedium,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
