import 'package:flutter/material.dart';

import '../models/bo_loc.dart';
import '../models/khoa_hoc.dart';

/// Thanh lọc của trang danh sách khoá học.
///
/// Widget này **không tự sửa trạng thái**: nó nhận `boLoc` hiện tại và gọi
/// `khiDoi` với bộ lọc mới. Người gọi quyết định làm gì — ở đây là đẩy bộ lọc
/// mới vào URL. Nhờ vậy widget không biết gì về go_router lẫn Riverpod, và
/// dùng lại được ở chỗ khác.
class ThanhLoc extends StatefulWidget {
  final BoLoc boLoc;
  final List<String> danhMuc;
  final ValueChanged<BoLoc> khiDoi;

  const ThanhLoc({
    super.key,
    required this.boLoc,
    required this.danhMuc,
    required this.khiDoi,
  });

  @override
  State<ThanhLoc> createState() => _ThanhLocState();
}

class _ThanhLocState extends State<ThanhLoc> {
  late final TextEditingController _oTim =
      TextEditingController(text: widget.boLoc.tuKhoa);

  @override
  void didUpdateWidget(covariant ThanhLoc cu) {
    super.didUpdateWidget(cu);
    // URL đổi từ bên ngoài (bấm Back, dán link) thì ô nhập phải theo. So sánh
    // trước khi gán: gán thẳng sẽ nhảy con trỏ về đầu dòng mỗi lần gõ.
    if (widget.boLoc.tuKhoa != _oTim.text) {
      _oTim.text = widget.boLoc.tuKhoa;
    }
  }

  @override
  void dispose() {
    _oTim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.boLoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _oTim,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm khoá học, giảng viên…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: loc.tuKhoa.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Xoá từ khoá',
                          onPressed: () =>
                              widget.khiDoi(loc.copyVoi(tuKhoa: '')),
                        ),
                ),
                // `onSubmitted` chứ không `onChanged`: mỗi lần đổi bộ lọc là
                // một mục mới trong lịch sử trình duyệt. Cập nhật theo từng
                // ký tự thì bấm Back một lần chỉ xoá được một chữ cái.
                onSubmitted: (v) => widget.khiDoi(loc.copyVoi(tuKhoa: v)),
              ),
            ),
            const SizedBox(width: 12),
            DropdownMenu<ThuTuSapXep>(
              initialSelection: loc.thuTu,
              label: const Text('Sắp xếp'),
              onSelected: (v) {
                if (v != null) widget.khiDoi(loc.copyVoi(thuTu: v));
              },
              dropdownMenuEntries: [
                for (final t in ThuTuSapXep.values)
                  DropdownMenuEntry(value: t, label: t.nhan),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Miễn phí'),
              selected: loc.chiMienPhi,
              onSelected: (v) => widget.khiDoi(loc.copyVoi(chiMienPhi: v)),
            ),
            for (final m in MucDo.values)
              FilterChip(
                label: Text(m.nhan),
                selected: loc.mucDo == m,
                onSelected: (v) => widget.khiDoi(
                  v ? loc.copyVoi(mucDo: m) : loc.copyVoi(xoaMucDo: true),
                ),
              ),
            const _Vach(),
            for (final d in widget.danhMuc)
              FilterChip(
                label: Text(d),
                selected: loc.danhMuc == d,
                onSelected: (v) => widget.khiDoi(
                  v ? loc.copyVoi(danhMuc: d) : loc.copyVoi(xoaDanhMuc: true),
                ),
              ),
            if (loc.coLoc)
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 18),
                label: const Text('Xoá bộ lọc'),
                onPressed: () => widget.khiDoi(BoLoc.macDinh),
              ),
          ],
        ),
      ],
    );
  }
}

class _Vach extends StatelessWidget {
  const _Vach();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: VerticalDivider(
        width: 12,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
