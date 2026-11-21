import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/bai_luyen_tap.dart';
import '../dinh_tuyen/duong_dan.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

class LuyenTapScreen extends ConsumerWidget {
  const LuyenTapScreen({super.key, required this.maKhoaHoc});

  final String maKhoaHoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khoaHoc = ref.watch(danhSachKhoaHocProvider);
    return KhiAsync(
      gia: khoaHoc,
      thuLai: () => ref.invalidate(danhSachKhoaHocProvider),
      khiCo: (danhSach) {
        final khoa = timKhoaHoc(danhSach, maKhoaHoc);
        final luyenTap = BaiLuyenTap.cua(maKhoaHoc);
        if (khoa == null || luyenTap == null) {
          return Trang(
            con: [
              KhoiRong(
                bieuTuong: Icons.assignment_outlined,
                tieuDe: 'Chưa có bài luyện tập',
                moTa: 'Chọn một khóa khác để xem phần luyện tập.',
                hanhDong: TextButton(
                  onPressed: () => context.go(DuongDan.danhSach),
                  child: const Text('Tất cả khóa học'),
                ),
              ),
            ],
          );
        }
        return _NoiDungLuyenTap(
          key: ValueKey(maKhoaHoc),
          maKhoaHoc: maKhoaHoc,
          tenKhoaHoc: khoa.tieuDe,
          luyenTap: luyenTap,
        );
      },
    );
  }
}

enum _Muc { quiz, baiTap }

class _NoiDungLuyenTap extends StatefulWidget {
  const _NoiDungLuyenTap({
    super.key,
    required this.maKhoaHoc,
    required this.tenKhoaHoc,
    required this.luyenTap,
  });

  final String maKhoaHoc;
  final String tenKhoaHoc;
  final BaiLuyenTap luyenTap;

  @override
  State<_NoiDungLuyenTap> createState() => _NoiDungLuyenTapState();
}

class _NoiDungLuyenTapState extends State<_NoiDungLuyenTap> {
  _Muc _muc = _Muc.quiz;

  @override
  Widget build(BuildContext context) {
    return Trang(
      con: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () =>
                        context.go(DuongDan.chiTiet(widget.maKhoaHoc)),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(widget.tenKhoaHoc),
                  ),
                ),
                Text(
                  'Luyện tập',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SegmentedButton<_Muc>(
                    segments: const [
                      ButtonSegment(
                        value: _Muc.quiz,
                        label: Text('Trắc nghiệm'),
                      ),
                      ButtonSegment(
                        value: _Muc.baiTap,
                        label: Text('Bài tập code'),
                      ),
                    ],
                    selected: {_muc},
                    onSelectionChanged: (muc) =>
                        setState(() => _muc = muc.single),
                  ),
                ),
                Visibility(
                  visible: _muc == _Muc.quiz,
                  maintainState: true,
                  child: _Quiz(
                    luyenTap: widget.luyenTap,
                    maKhoaHoc: widget.maKhoaHoc,
                  ),
                ),
                Visibility(
                  visible: _muc == _Muc.baiTap,
                  maintainState: true,
                  child: _BaiTap(
                    bai: widget.luyenTap.baiTap,
                    maKhoaHoc: widget.maKhoaHoc,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Quiz extends ConsumerStatefulWidget {
  const _Quiz({required this.luyenTap, required this.maKhoaHoc});

  final BaiLuyenTap luyenTap;
  final String maKhoaHoc;

  @override
  ConsumerState<_Quiz> createState() => _QuizState();
}

class _QuizState extends ConsumerState<_Quiz> {
  final _luaChon = <int, int>{};
  bool _daNop = false;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.luyenTap.quiz;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (_daNop)
          Semantics(
            liveRegion: true,
            child: Text(
              'Kết quả: ${widget.luyenTap.chamDiem(_luaChon)}/${quiz.length} câu đúng',
              style: theme.textTheme.titleMedium,
            ),
          )
        else
          Text('Đã trả lời ${_luaChon.length}/${quiz.length} câu'),
        for (final (i, cau) in quiz.indexed)
          _Khoi(
            con: [
              Text(
                '${i + 1}. ${cau.cauHoi}',
                style: theme.textTheme.titleMedium,
              ),
              RadioGroup<int>(
                groupValue: _luaChon[i],
                onChanged: (giaTri) {
                  if (!_daNop && giaTri != null) {
                    setState(() => _luaChon[i] = giaTri);
                  }
                },
                child: Column(
                  children: [
                    for (final (j, dapAn) in cau.luaChon.indexed)
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        enabled: !_daNop,
                        value: j,
                        title: Text(dapAn),
                      ),
                  ],
                ),
              ),
              if (_daNop)
                Text(
                  '${_luaChon[i] == cau.dapAn ? 'Đúng' : 'Chưa đúng'}. '
                  'Đáp án: ${cau.luaChon[cau.dapAn]}.\n${cau.giaiThich}',
                ),
            ],
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _daNop
              ? OutlinedButton(
                  onPressed: () => setState(() {
                    _luaChon.clear();
                    _daNop = false;
                  }),
                  child: const Text('Làm lại quiz'),
                )
              : FilledButton(
                  onPressed: _luaChon.length == quiz.length
                      ? () {
                          setState(() => _daNop = true);
                          ref.read(chuoiHocProvider.notifier).ghiNhanHocTap(
                                maKhoaHoc: widget.maKhoaHoc,
                                maBaiHoc: 'quiz_${widget.maKhoaHoc}',
                                xpCongThem: 30,
                                moTaHoatDong: 'Hoàn thành bài kiểm tra trắc nghiệm',
                              );
                          ref.read(viCoinProvider.notifier).nhanThuong(
                                loai: 'quiz_complete',
                                referenceId: 'quiz_${widget.maKhoaHoc}',
                                moTa: 'Hoàn thành Quiz khóa học',
                              );
                        }
                      : null,
                  child: const Text('Nộp quiz'),
                ),
        ),
      ],
    );
  }
}

class _BaiTap extends ConsumerStatefulWidget {
  const _BaiTap({required this.bai, required this.maKhoaHoc});

  final BaiTapCode bai;
  final String maKhoaHoc;

  @override
  ConsumerState<_BaiTap> createState() => _BaiTapState();
}

class _BaiTapState extends ConsumerState<_BaiTap> {
  late final _ma = TextEditingController(text: widget.bai.maKhoiDau);
  bool _hienLoiGiai = false;

  @override
  void dispose() {
    _ma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bai = widget.bai;
    final theme = Theme.of(context);
    final chuCode = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
    );
    return _Khoi(
      con: [
        Text(bai.tieuDe, style: theme.textTheme.titleLarge),
        Text(bai.deBai),
        Text('Kết quả mong đợi', style: theme.textTheme.titleSmall),
        Text(bai.ketQua),
        TextField(
          controller: _ma,
          minLines: 7,
          maxLines: 14,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.multiline,
          style: chuCode,
          decoration: const InputDecoration(
            labelText: 'Code của bạn',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Xem gợi ý'),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: AlignmentDirectional.centerStart,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(bai.goiY),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton(
            onPressed: () {
              final hienMoi = !_hienLoiGiai;
              if (hienMoi && _ma.text.trim().isNotEmpty) {
                ref.read(chuoiHocProvider.notifier).ghiNhanHocTap(
                      maKhoaHoc: widget.maKhoaHoc,
                      maBaiHoc: 'code_${widget.maKhoaHoc}',
                      xpCongThem: 30,
                      moTaHoatDong: 'Hoàn thành bài tập lập trình',
                    );
              }
              setState(() => _hienLoiGiai = hienMoi);
            },
            child: Text(
              _hienLoiGiai ? 'Ẩn lời giải mẫu' : 'Đối chiếu lời giải',
            ),
          ),
        ),
        if (_hienLoiGiai)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(bai.loiGiai, style: chuCode),
            ),
          ),
      ],
    );
  }
}

class _Khoi extends StatelessWidget {
  const _Khoi({required this.con});

  final List<Widget> con;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: con,
      ),
    ),
  );
}
