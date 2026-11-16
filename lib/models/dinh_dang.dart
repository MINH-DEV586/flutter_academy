/// Các hàm biến số thành chữ hiển thị.
///
/// Gom vào một tệp không phụ thuộc Flutter để kiểm thử trực tiếp. Dự án cố ý
/// **không dùng gói `intl`**: chỉ cần vài hàm, mà thêm một gói là thêm một
/// thứ phải nâng cấp mỗi năm.
library;

/// 5400 → "1 giờ 30 phút"; 300 → "5 phút"; 45 → "1 phút".
String thoiLuong(int giay) {
  if (giay <= 0) return '0 phút';
  final gio = giay ~/ 3600;
  // Làm tròn LÊN: bài 90 giây hiện "2 phút" chứ không hiện "1 phút", vì
  // người học thấy con số nhỏ hơn thực tế sẽ khó chịu hơn là thấy số lớn hơn.
  final phut = ((giay % 3600) / 60).ceil();
  if (gio == 0) return '$phut phút';
  if (phut == 0) return '$gio giờ';
  if (phut == 60) return '${gio + 1} giờ';
  return '$gio giờ $phut phút';
}

/// 1490000 → "1.490.000 ₫"; 0 → "Miễn phí".
String tienVND(int dong) {
  if (dong <= 0) return 'Miễn phí';
  return '${nhomBaChuSo(dong)} ₫';
}

/// Chèn dấu chấm mỗi ba chữ số: 1490000 → "1.490.000".
String nhomBaChuSo(int so) {
  final am = so < 0;
  final s = so.abs().toString();
  final ra = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    // Chèn dấu chấm trước chữ số thứ i khi số chữ số còn lại chia hết cho 3.
    if (i > 0 && (s.length - i) % 3 == 0) ra.write('.');
    ra.write(s[i]);
  }
  return am ? '-$ra' : ra.toString();
}

/// 4.0 → "4.0"; 4.25 → "4.3". Luôn một chữ số thập phân cho cột thẳng hàng.
String diem(double d) => d.toStringAsFixed(1);

/// 12345 → "12.3k" để nhãn "lượt đánh giá" không kéo dài thẻ khoá học.
String soGon(int n) {
  if (n < 1000) return '$n';
  final k = n / 1000;
  if (k < 10) return '${k.toStringAsFixed(1)}k';
  return '${k.round()}k';
}
