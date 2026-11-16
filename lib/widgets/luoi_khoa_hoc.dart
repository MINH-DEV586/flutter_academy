import 'package:flutter/material.dart';

import '../cau_hinh/diem_ngat.dart';
import '../models/khoa_hoc.dart';
import 'the_khoa_hoc.dart';

/// Lưới thẻ khoá học, tự đổi số cột theo bề rộng **khả dụng**.
///
/// Dùng `LayoutBuilder` chứ không `MediaQuery`: ở khổ màn hình rộng, lưới
/// nằm bên phải thanh điều hướng nên bề rộng của nó nhỏ hơn bề rộng cửa sổ
/// khoảng 260 pixel. Lấy theo `MediaQuery` thì lưới tưởng mình rộng hơn thực
/// tế và thẻ bị bóp méo.
///
/// Đây đúng là chỗ sách nhắc trong Chương 3, và cũng là lỗi hay gặp nhất khi
/// đưa một giao diện điện thoại lên web.
class LuoiKhoaHoc extends StatelessWidget {
  final List<KhoaHoc> danhSach;

  /// Phần trăm tiến độ theo mã khoá học. Khoá nào không có thì chưa học.
  final Map<String, int> tienDo;

  const LuoiKhoaHoc({
    super.key,
    required this.danhSach,
    this.tienDo = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, rangBuoc) {
        final soCot = DiemNgat.soCotLuoi(rangBuoc.maxWidth);
        return GridView.builder(
          // Lưới nằm trong một `SingleChildScrollView` của trang, nên tự nó
          // không được cuộn, và phải tự co lại vừa nội dung.
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: soCot,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Chiều cao cố định thay vì tỉ lệ: nội dung thẻ (2 dòng tiêu đề,
            // sao, ba mẩu tin, giá) luôn cao xấp xỉ nhau, mà tỉ lệ thì ở cột
            // hẹp sẽ ra thẻ lùn và chữ bị cắt.
            mainAxisExtent: 320,
          ),
          itemCount: danhSach.length,
          itemBuilder: (context, i) {
            final k = danhSach[i];
            return TheKhoaHoc(khoaHoc: k, phanTramTienDo: tienDo[k.ma]);
          },
        );
      },
    );
  }
}
