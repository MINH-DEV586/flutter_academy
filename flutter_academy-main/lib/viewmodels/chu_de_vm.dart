import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/che_do_giao_dien.dart';

/// Chế độ sáng/tối của giao diện.
///
/// Đây là ví dụ cho `Notifier` đồng bộ — loại provider đơn giản nhất của
/// Riverpod 3. Trạng thái nằm gọn trong bộ nhớ, không đọc ổ đĩa, nên `build`
/// trả về thẳng giá trị chứ không trả về `Future`.
///
/// Sách (Chương 8) dùng `StateNotifier` cho loại việc này. Từ Riverpod 3,
/// `StateNotifier` đã chuyển sang `package:riverpod/legacy.dart`; mã tương
/// đương bằng `Notifier` ngắn hơn và không cần khai báo lớp trạng thái riêng.
///
/// Chú ý danh sách `import` của tệp này: **không có** `material.dart`. Đó là
/// lý do trạng thái ở đây là `CheDoGiaoDien` chứ không phải `ThemeMode`.
class ChuDeVM extends Notifier<CheDoGiaoDien> {
  @override
  CheDoGiaoDien build() => CheDoGiaoDien.theoHeThong;

  void dat(CheDoGiaoDien che) {
    if (state != che) state = che;
  }

  void xoayVong() => state = state.tiepTheo;
}
