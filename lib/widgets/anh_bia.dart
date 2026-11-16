import 'package:flutter/material.dart';

import '../cau_hinh/mau_sac.dart';

/// Ảnh bìa khoá học, có phương án dự phòng khi thiếu tệp.
///
/// Vì sao phải có dự phòng: ảnh trong `assets/images/` do một script Python
/// sinh ra (`cong-cu/sinh_anh_bia.py`). Ai tải mã nguồn về mà chưa chạy
/// script sẽ thiếu ảnh, và nếu không có `errorBuilder` thì cả lưới khoá học
/// hiện một dãy ô đỏ báo lỗi. Có dự phòng thì ứng dụng vẫn dùng được, chỉ là
/// bìa đơn giản hơn.
class AnhBia extends StatelessWidget {
  final String tenTep;
  final String danhMuc;
  final String tieuDe;

  /// Tỉ lệ khung hình. 16/9 cho thẻ, 21/9 cho ảnh đầu trang chi tiết.
  final double tiLe;

  const AnhBia({
    super.key,
    required this.tenTep,
    required this.danhMuc,
    required this.tieuDe,
    this.tiLe = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: tiLe,
      child: Image.asset(
        'assets/images/$tenTep',
        fit: BoxFit.cover,
        errorBuilder: (context, loi, vet) => _BiaDuPhong(
          danhMuc: danhMuc,
          tieuDe: tieuDe,
        ),
      ),
    );
  }
}

class _BiaDuPhong extends StatelessWidget {
  final String danhMuc;
  final String tieuDe;

  const _BiaDuPhong({required this.danhMuc, required this.tieuDe});

  @override
  Widget build(BuildContext context) {
    final nen = ChuDe.mauDanhMuc[danhMuc] ?? ChuDe.mauGoc;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nen, Color.lerp(nen, Colors.black, 0.35)!],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            tieuDe,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}
