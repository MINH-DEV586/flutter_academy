import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_du_lieu.dart';
import '../data/kho_gia_su_ai.dart';
import '../viewmodels/providers.dart';

enum _MucDo {
  coBan('Cơ bản'),
  trungCap('Trung cấp'),
  chuyenSau('Chuyên sâu');

  const _MucDo(this.nhan);
  final String nhan;
}

class GiaSuAi extends ConsumerStatefulWidget {
  const GiaSuAi({super.key, required this.maBai, required this.tenBai});

  final String maBai;
  final String tenBai;

  @override
  ConsumerState<GiaSuAi> createState() => _GiaSuAiState();
}

class _GiaSuAiState extends ConsumerState<GiaSuAi> {
  final _cauHoi = TextEditingController();
  var _mucDo = _MucDo.coBan;
  var _dangGui = false;
  String? _loi;
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
      _loi = null;
      _cauTraLoi = null;
    });
    try {
      final traLoi = await ref
          .read(khoNguoiDungProvider)
          .hoiAi(baiHoc: widget.maBai, cauHoi: noiDung, mucDo: _mucDo.name);
      if (mounted) {
        ref.invalidate(thuongHocProvider);
        setState(() => _cauTraLoi = traLoi);
      }
    } catch (loi) {
      if (mounted)
        setState(
          () => _loi = loi is LoiTaiKhoan
              ? loi.thongBao
              : 'Chưa nhận được câu trả lời. Bạn có thể gửi lại.',
        );
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
              if (_loi != null) Semantics(liveRegion: true, child: Text(_loi!)),
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
