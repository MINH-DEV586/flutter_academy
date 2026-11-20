import 'dart:convert';

import 'package:http/http.dart' as http;

class KhoGiaSuAi {
  static const diaChi = String.fromEnvironment('AI_TUTOR_URL');
  static const gioiHanCauHoi = 1000;

  static Future<String> hoi({
    required String baiHoc,
    required String cauHoi,
    required String mucDo,
  }) async {
    final phanHoi = await http
        .post(
          Uri.parse(diaChi),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'baiHoc': baiHoc,
            'cauHoi': cauHoi,
            'mucDo': mucDo,
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (phanHoi.statusCode != 200) {
      throw http.ClientException('HTTP ${phanHoi.statusCode}');
    }
    final json = jsonDecode(utf8.decode(phanHoi.bodyBytes));
    if (json is! Map || json['cauTraLoi'] is! String) {
      throw const FormatException('Phản hồi AI Tutor không hợp lệ.');
    }
    return json['cauTraLoi'] as String;
  }
}
