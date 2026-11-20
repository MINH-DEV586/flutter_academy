/// Chế độ giao diện do người dùng chọn.
///
/// Vì sao khai báo enum riêng thay vì dùng thẳng `ThemeMode` của Flutter:
/// `ThemeMode` nằm trong `package:material_ui/material_ui.dart`. Dùng nó ở tầng
/// ViewModel là phá vỡ luật "viewmodels không import material.dart" — luật
/// mà cả dự án dựa vào để phân tầng.
///
/// Cái giá phải trả là một hàm quy đổi ba dòng trong `app.dart`. Đổi lại,
/// ranh giới giữa các tầng vẫn kiểm tra được chỉ bằng cách nhìn danh sách
/// `import`.
enum CheDoGiaoDien {
  theoHeThong('Theo hệ thống'),
  sang('Sáng'),
  toi('Tối');

  final String nhan;
  const CheDoGiaoDien(this.nhan);

  /// Xoay vòng: theo hệ thống → sáng → tối → theo hệ thống.
  CheDoGiaoDien get tiepTheo => switch (this) {
        CheDoGiaoDien.theoHeThong => CheDoGiaoDien.sang,
        CheDoGiaoDien.sang => CheDoGiaoDien.toi,
        CheDoGiaoDien.toi => CheDoGiaoDien.theoHeThong,
      };
}
