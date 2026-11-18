import 'dart:convert';

import 'package:http/http.dart' as http;
import 'kho_du_lieu.dart';

class KhoGiaSuAi {
  static const diaChi = String.fromEnvironment('AI_TUTOR_URL');
  static const gioiHanCauHoi = 1000;

  static Future<String> hoi({
    required String baiHoc,
    required String cauHoi,
    required String mucDo,
    String? token,
  }) async {
    final phanHoi = await http
        .post(
          Uri.parse(diaChi),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'baiHoc': baiHoc,
            'cauHoi': cauHoi,
            'mucDo': mucDo,
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (phanHoi.statusCode != 200) {
      final json = jsonDecode(utf8.decode(phanHoi.bodyBytes));
      throw LoiTaiKhoan(
        json is Map && json['loi'] is String
            ? json['loi'] as String
            : 'Chưa nhận được câu trả lời.',
      );
    }
    final json = jsonDecode(utf8.decode(phanHoi.bodyBytes));
    if (json is! Map || json['cauTraLoi'] is! String) {
      throw const FormatException('Phản hồi AI Tutor không hợp lệ.');
    }
    return json['cauTraLoi'] as String;
  }
}
