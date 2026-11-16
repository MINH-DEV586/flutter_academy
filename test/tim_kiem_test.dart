import 'package:flutter_academy/models/tim_kiem.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kiểm thử phần chuẩn hoá chuỗi tiếng Việt.
///
/// Đây là loại mã "nhìn qua thì đúng" nguy hiểm nhất: bảng quy đổi thiếu một
/// ký tự thì 99% trường hợp vẫn chạy, chỉ riêng người gõ chữ đó là không tìm
/// ra gì — và không ai báo lỗi vì tưởng mình gõ sai.
void main() {
  group('khongDau', () {
    test('bỏ dấu và chuyển chữ thường', () {
      expect(khongDau('Điều Hướng'), 'dieu huong');
      expect(khongDau('Lưu trữ cục bộ'), 'luu tru cuc bo');
      expect(khongDau('Kiến trúc MVVM'), 'kien truc mvvm');
    });

    test('phủ hết sáu nguyên âm có dấu và chữ đ', () {
      expect(khongDau('àáạảãâầấậẩẫăằắặẳẵ'), 'a' * 17);
      expect(khongDau('èéẹẻẽêềếệểễ'), 'e' * 11);
      expect(khongDau('ìíịỉĩ'), 'i' * 5);
      expect(khongDau('òóọỏõôồốộổỗơờớợởỡ'), 'o' * 17);
      expect(khongDau('ùúụủũưừứựửữ'), 'u' * 11);
      expect(khongDau('ỳýỵỷỹ'), 'y' * 5);
      expect(khongDau('đĐ'), 'dd');
    });

    test('giữ nguyên chữ không dấu, chữ số và dấu câu', () {
      expect(khongDau('go_router 18.0.1'), 'go_router 18.0.1');
    });

    test('chuỗi rỗng', () {
      expect(khongDau(''), '');
    });
  });

  group('khopTuKhoa', () {
    const noiDung = 'Điều hướng theo URL với go_router';

    test('khớp khi gõ không dấu', () {
      expect(khopTuKhoa(noiDung, 'dieu huong'), isTrue);
    });

    test('khớp khi gõ có dấu', () {
      expect(khopTuKhoa(noiDung, 'Điều hướng'), isTrue);
    });

    test('không phân biệt hoa thường', () {
      expect(khopTuKhoa(noiDung, 'GO_ROUTER'), isTrue);
    });

    test('nhiều từ phải khớp hết, thứ tự tuỳ ý', () {
      expect(khopTuKhoa(noiDung, 'router dieu'), isTrue);
      expect(khopTuKhoa(noiDung, 'router hive'), isFalse);
    });

    test('từ khoá rỗng hoặc toàn khoảng trắng thì khớp tất cả', () {
      expect(khopTuKhoa(noiDung, ''), isTrue);
      expect(khopTuKhoa(noiDung, '   '), isTrue);
    });

    test('khớp cả khi từ khoá nằm giữa một từ khác', () {
      // Cố ý: người dùng gõ "rout" phải ra "router". Tìm kiếm theo tiền tố
      // từ thì chặt chẽ hơn nhưng khó chịu hơn với danh sách chỉ vài chục mục.
      expect(khopTuKhoa(noiDung, 'rout'), isTrue);
    });
  });
}
