import 'dart:convert';
import 'dart:math';

import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../cau_hinh/may_chu.dart';

abstract interface class KhoThuongChuoi {
  int soDangCho(String email);
  Future<void> ghiNhan(String email, String bai);
  Future<void> dongBo(String email);
  Future<Map<String, dynamic>> yeuCau(
    String duongDan, {
    Map<String, Object?>? duLieu,
  });
}

class HttpKhoThuongChuoi implements KhoThuongChuoi {
  HttpKhoThuongChuoi(
    this._cho,
    this._phien, {
    http.Client Function()? taoClient,
  }) : _taoClient = taoClient ?? http.Client.new;

  final Box<String> _cho;
  final Box<String> _phien;
  final http.Client Function() _taoClient;
  final _dangDongBo = <String, Future<void>>{};
  final _random = Random.secure();
  int _thuTuCuoi = 0;

  Iterable<String> _cacSuKien(String email) =>
      _cho.keys.whereType<String>().where((khoa) => khoa.startsWith('$email|'));

  @override
  int soDangCho(String email) => _cacSuKien(email).length;

  @override
  Future<void> ghiNhan(String email, String bai) {
    final id = base64UrlEncode(
      List<int>.generate(18, (_) => _random.nextInt(256)),
    );
    _thuTuCuoi = max(DateTime.now().microsecondsSinceEpoch, _thuTuCuoi + 1);
    final thuTu = _thuTuCuoi.toString().padLeft(19, '0');
    // Khóa cũ chỉ có ID base64url. Dấu ~ xếp sự kiện mới sau sự kiện cũ.
    return _cho.put('$email|~$thuTu|$id', bai);
  }

  @override
  Future<void> dongBo(String email) => _dangDongBo.putIfAbsent(
    email,
    () => _guiHangDoi(email).whenComplete(() {
      _dangDongBo.remove(email);
    }),
  );

  Future<void> _guiHangDoi(String email) async {
    while (true) {
      final cho = _cacSuKien(email);
      if (cho.isEmpty) return;
      final khoa = cho.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      try {
        await yeuCau(
          '/complete',
          duLieu: {
            'email': email,
            'eventId': khoa.substring(khoa.lastIndexOf('|') + 1),
            'lesson': _cho.get(khoa),
            'from': false,
            'to': true,
          },
        );
      } on LoiThuongChuoi catch (loi) {
        if (loi.ma != 'INVALID_COMPLETION' && loi.ma != 'COMPLETION_CONFLICT') {
          rethrow;
        }
      }
      await _cho.delete(khoa);
    }
  }

  @override
  Future<Map<String, dynamic>> yeuCau(
    String duongDan, {
    Map<String, Object?>? duLieu,
  }) async {
    final token = _phien.get('token');
    if (token == null) throw const LoiThuongChuoi('Vui lòng đăng nhập.');
    final client = _taoClient();
    try {
      final request = http.Request(
        duLieu == null ? 'GET' : 'POST',
        Uri.parse('${MayChu.api}/rewards$duongDan'),
      )..headers['Authorization'] = 'Bearer $token';
      if (duLieu != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(duLieu);
      }
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      final kq =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw LoiThuongChuoi(
          kq['loi'] as String? ?? 'Chưa cập nhật được Coin.',
          ma: kq['code'] as String?,
        );
      }
      return kq;
    } finally {
      client.close();
    }
  }
}

class LoiThuongChuoi implements Exception {
  const LoiThuongChuoi(this.thongBao, {this.ma});
  final String thongBao;
  final String? ma;
}
