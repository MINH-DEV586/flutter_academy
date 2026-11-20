/// Chuẩn hoá chuỗi tiếng Việt để tìm kiếm.
///
/// Người dùng gõ "dieu huong" phải ra "Điều hướng". Muốn vậy phải bỏ dấu cả
/// hai vế trước khi so sánh.
///
/// Đây là hàm thuần, không phụ thuộc Flutter — nên `test/tim_kiem_test.dart`
/// chạy trong vài mili giây.
library;

/// Bảng quy đổi: mỗi nhóm gồm chữ không dấu và toàn bộ biến thể có dấu.
const Map<String, String> _nhom = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

/// Bảng tra mã ký tự → chữ không dấu, dựng một lần khi nạp thư viện.
///
/// Dựng bằng vòng lặp thay vì gõ tay hai chuỗi song song: hai chuỗi song song
/// rất dễ lệch một ký tự, và lệch thì không ai phát hiện ra cho tới khi có
/// người tìm "hướng" mà không ra kết quả.
final Map<int, String> _bangTra = _dungBang();

Map<int, String> _dungBang() {
  final bang = <int, String>{};
  _nhom.forEach((khongDauCua, coDau) {
    for (final r in coDau.runes) {
      bang[r] = khongDauCua;
    }
  });
  return bang;
}

/// Chuyển về chữ thường, không dấu.
String khongDau(String chuoi) {
  final thap = chuoi.toLowerCase();
  final ra = StringBuffer();
  for (final r in thap.runes) {
    ra.write(_bangTra[r] ?? String.fromCharCode(r));
  }
  return ra.toString();
}

/// `noiDung` có chứa `tuKhoa` không, bỏ qua dấu và hoa thường.
///
/// Từ khoá được tách theo khoảng trắng và phải khớp **tất cả** — gõ
/// "flutter web" thì chỉ ra những khoá học có cả hai chữ, thứ tự tuỳ ý.
bool khopTuKhoa(String noiDung, String tuKhoa) {
  final can = khongDau(tuKhoa).trim();
  if (can.isEmpty) return true;
  final dich = khongDau(noiDung);
  for (final tu in can.split(RegExp(r'\s+'))) {
    if (!dich.contains(tu)) return false;
  }
  return true;
}
