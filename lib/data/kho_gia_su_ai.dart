import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../cau_hinh/may_chu.dart';
import '../models/gia_su_ai.dart';

abstract interface class KhoGiaSuAi {
  static const gioiHanCauHoi = 1000;

  List<LuotHoiTutor> doc(HoiThoaiTutor khoa);
  Future<void> luu(HoiThoaiTutor khoa, List<LuotHoiTutor> lichSu);
  Uri diaChiNguon(String duongDan);
  Stream<Map<String, dynamic>> hoi({
    required HoiThoaiTutor khoa,
    required String cauHoi,
    required String mucDo,
    required Future<void> khiHuy,
  });
}

class HttpKhoGiaSuAi implements KhoGiaSuAi {
  HttpKhoGiaSuAi(this._chat, this._phien);

  static final _diaChi = MayChu.tutor;
  final Box<String> _chat;
  final Box<String> _phien;

  String _khoa(HoiThoaiTutor khoa) => jsonEncode([khoa.email, khoa.bai]);

  @override
  List<LuotHoiTutor> doc(HoiThoaiTutor khoa) {
    final raw = _chat.get(_khoa(khoa));
    if (raw == null) return [];
    final lichSu = <LuotHoiTutor>[];
    try {
      for (final muc in jsonDecode(raw) as List) {
        try {
          lichSu.add(LuotHoiTutor.tuJson(muc));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
    return lichSu;
  }

  @override
  Future<void> luu(HoiThoaiTutor khoa, List<LuotHoiTutor> lichSu) => _chat.put(
    _khoa(khoa),
    jsonEncode(lichSu.map((muc) => muc.duLieu).toList()),
  );

  @override
  Uri diaChiNguon(String duongDan) => _diaChi.replace(path: duongDan);

  @override
  Stream<Map<String, dynamic>> hoi({
    required HoiThoaiTutor khoa,
    required String cauHoi,
    required String mucDo,
    required Future<void> khiHuy,
  }) async* {
    final token = _phien.get('token');
    if (token == null) throw const LoiTutor('Đăng nhập để hỏi Gia sư AI.');
    final client = http.Client();
    try {
      final request =
          http.AbortableRequest('POST', _diaChi, abortTrigger: khiHuy)
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Accept': 'application/x-ndjson',
              'Authorization': 'Bearer $token',
            })
            ..body = jsonEncode({
              'email': khoa.email,
              'baiHoc': khoa.bai,
              'cauHoi': cauHoi,
              'mucDo': mucDo,
            });
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 18));
      final dong = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        final json = jsonDecode(await dong.join()) as Map<String, dynamic>;
        throw LoiTutor(
          json['loi'] as String? ?? 'Gia sư AI tạm thời không khả dụng.',
          resetAt: DateTime.tryParse(json['resetAt'] as String? ?? ''),
        );
      }
      await for (final muc in dong) {
        if (muc.isNotEmpty) yield jsonDecode(muc) as Map<String, dynamic>;
      }
    } finally {
      client.close();
    }
  }
}
