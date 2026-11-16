import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/duong_dan.dart';
import '../widgets/trang.dart';
import '../widgets/trang_thai.dart';

/// Trang 404.
///
/// Trên ứng dụng di động, "đường dẫn không tồn tại" gần như không xảy ra vì
/// người dùng chỉ đi lại bằng cách bấm nút. Trên web thì đây là chuyện
/// thường ngày: gõ nhầm địa chỉ, link cũ đã đổi, bookmark từ ba năm trước.
///
/// Vì vậy trang này phải làm được hai việc: nói rõ địa chỉ nào hỏng, và đưa
/// người dùng về chỗ dùng được — chứ không chỉ hiện một con số.
class KhongTimThayScreen extends StatelessWidget {
  final String diaChi;

  const KhongTimThayScreen({super.key, required this.diaChi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Trang(
        con: [
          const SizedBox(height: 48),
          KhoiRong(
            bieuTuong: Icons.travel_explore,
            tieuDe: 'Không có trang này',
            moTa: 'Địa chỉ "$diaChi" không dẫn tới đâu cả. '
                'Có thể link đã cũ hoặc bị gõ thiếu một ký tự.',
            hanhDong: Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () => context.go(DuongDan.trangChu),
                  child: const Text('Về trang chủ'),
                ),
                FilledButton.tonal(
                  onPressed: () => context.go(DuongDan.danhSach),
                  child: const Text('Xem tất cả khoá học'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
