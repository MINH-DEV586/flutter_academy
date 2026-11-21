import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../models/goi_pro.dart';

abstract interface class KhoThanhVien {
  Future<List<GoiPro>> layDanhSachGoiPro();

  Future<TrangThaiThanhVien> layTrangThaiThanhVien();

  Future<Map<String, dynamic>> muaGoiPro(String packageId);
}

class HttpKhoThanhVien implements KhoThanhVien {
  HttpKhoThanhVien(this._phien);

  static const _diaChi = String.fromEnvironment(
    'ACCOUNT_API_URL',
    defaultValue: 'http://127.0.0.1:8787/api',
  );
  static const _khoaToken = 'token';
  final Box<String> _phien;

  String _docToken() {
    final token = _phien.get(_khoaToken);
    if (token == null) {
      throw Exception('Vui lòng đăng nhập.');
    }
    return token;
  }

  Future<http.Response> _gui(
    String method,
    String path, {
    Map<String, dynamic>? duLieu,
  }) async {
    final client = http.Client();
    try {
      final token = _docToken();
      final request =
          http.Request(method, Uri.parse('$_diaChi/subscriptions/$path'));
      request.headers['Authorization'] = 'Bearer $token';
      if (duLieu != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(duLieu);
      }
      return await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _doc(http.Response response) {
    if (response.statusCode >= 500) {
      throw Exception('Máy chủ thành viên đang gặp lỗi.');
    }
    final duLieu =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        duLieu['loi'] as String? ?? 'Yêu cầu thất bại.',
      );
    }
    return duLieu;
  }

  @override
  Future<List<GoiPro>> layDanhSachGoiPro() async {
    final res = await _gui('GET', 'packages');
    final data = _doc(res);
    final list = data['packages'] as List? ?? [];
    return list.map((e) => GoiPro.tuMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TrangThaiThanhVien> layTrangThaiThanhVien() async {
    final res = await _gui('GET', 'me');
    return TrangThaiThanhVien.tuMap(_doc(res));
  }

  @override
  Future<Map<String, dynamic>> muaGoiPro(String packageId) async {
    final res = await _gui('POST', 'purchase', duLieu: {
      'packageId': packageId,
    });
    return _doc(res);
  }
}
