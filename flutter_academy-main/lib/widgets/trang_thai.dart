import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ba trạng thái mà MỌI màn hình đọc dữ liệu đều phải có: đang tải, lỗi,
// và rỗng.
//
// Gom vào một tệp vì hai lý do. Thứ nhất, ba trạng thái này chiếm phần lớn
// mã của một màn hình thật mà lại giống hệt nhau ở mọi màn hình. Thứ hai —
// quan trọng hơn — khi chúng đã sẵn có thì không ai còn cái cớ để bỏ qua
// nhánh lỗi nữa.

/// Hiển thị một `AsyncValue` với đủ ba nhánh.
///
/// Dùng `switch` trên `AsyncValue` (Riverpod 3 khuyến nghị) thay vì hàm
/// `when` của bản cũ: so khớp mẫu thì trình biên dịch kiểm tra đủ nhánh.
class KhiAsync<T> extends StatelessWidget {
  final AsyncValue<T> gia;
  final Widget Function(T duLieu) khiCo;
  final VoidCallback? thuLai;

  const KhiAsync({
    super.key,
    required this.gia,
    required this.khiCo,
    this.thuLai,
  });

  @override
  Widget build(BuildContext context) {
    return switch (gia) {
      AsyncData(:final value) => khiCo(value),
      AsyncError(:final error) => KhoiLoi(loi: error, thuLai: thuLai),
      _ => const KhoiDangTai(),
    };
  }
}

class KhoiDangTai extends StatelessWidget {
  final String? nhan;
  const KhoiDangTai({super.key, this.nhan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (nhan != null) ...[
            const SizedBox(height: 16),
            Text(nhan!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class KhoiLoi extends StatelessWidget {
  final Object loi;
  final VoidCallback? thuLai;

  const KhoiLoi({super.key, required this.loi, this.thuLai});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: mau.error),
            const SizedBox(height: 16),
            Text(
              'Không tải được dữ liệu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Hiện nguyên văn lỗi. Trong ứng dụng thật thì che đi và ghi log,
            // nhưng đây là tài liệu dạy học: nhìn thấy lỗi mới sửa được.
            Text(
              '$loi',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: mau.onSurfaceVariant),
            ),
            if (thuLai != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: thuLai, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Màn hình rỗng có ích: nói rõ vì sao rỗng và làm gì tiếp theo.
///
/// "Không có kết quả" là một câu cụt. "Không có khoá học nào khớp — thử bỏ
/// bớt bộ lọc" thì người dùng biết phải làm gì.
class KhoiRong extends StatelessWidget {
  final IconData bieuTuong;
  final String tieuDe;
  final String moTa;
  final Widget? hanhDong;

  const KhoiRong({
    super.key,
    required this.bieuTuong,
    required this.tieuDe,
    required this.moTa,
    this.hanhDong,
  });

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bieuTuong, size: 56, color: mau.outline),
            const SizedBox(height: 16),
            Text(tieuDe, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                moTa,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: mau.onSurfaceVariant),
              ),
            ),
            if (hanhDong != null) ...[
              const SizedBox(height: 20),
              hanhDong!,
            ],
          ],
        ),
      ),
    );
  }
}
