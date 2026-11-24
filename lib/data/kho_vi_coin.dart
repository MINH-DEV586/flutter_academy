import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../cau_hinh/may_chu.dart';
import '../models/don_nap_coin.dart';
import '../models/giao_dich_coin.dart';
import '../models/vi_coin.dart';

abstract interface class KhoViCoin {
  Future<ViCoin> layThongTinVi();

  Future<List<GiaoDichCoin>> layLichSuGiaoDich({int page = 1, int limit = 20});

  Future<List<GoiNapCoin>> layGoiNap();

  Future<void> lienKetMetaMask(String? address);

  Future<Map<String, dynamic>> taoDonNap({
    required String packageId,
    String? orderId,
  });

  Future<DonNapCoin?> layDonNapGanNhat();

  Future<Map<String, dynamic>> nhanThuong({
    required String type,
    required String referenceId,
    String? description,
  });
}

class HttpKhoViCoin implements KhoViCoin {
  HttpKhoViCoin(this._phien);

  static final _diaChi = MayChu.api;
  static const _khoaToken = 'token';
  final Box<String> _phien;

  String _docToken() {
    final token = _phien.get(_khoaToken);
    if (token == null) {
      throw Exception('Vui lòng đăng nhập để thao tác ví.');
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
      final request = http.Request(method, Uri.parse('$_diaChi/wallet/$path'));
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
      throw Exception('Máy chủ ví đang gặp lỗi. Vui lòng thử lại.');
    }
    final duLieu =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(duLieu['loi'] as String? ?? 'Yêu cầu ví thất bại.');
    }
    return duLieu;
  }

  @override
  Future<ViCoin> layThongTinVi() async {
    final client = http.Client();
    try {
      final token = _docToken();
      final request = http.Request('GET', Uri.parse('$_diaChi/wallet'));
      request.headers['Authorization'] = 'Bearer $token';
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      return ViCoin.tuMap(_doc(response));
    } finally {
      client.close();
    }
  }

  @override
  Future<List<GiaoDichCoin>> layLichSuGiaoDich({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _gui('GET', 'transactions?page=$page&limit=$limit');
    final data = _doc(res);
    final list = data['transactions'] as List? ?? [];
    return list
        .map((e) => GiaoDichCoin.tuMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GoiNapCoin>> layGoiNap() async {
    final res = await _gui('GET', 'deposit-packages');
    final data = _doc(res);
    final list = data['packages'] as List? ?? [];
    return list
        .map((e) => GoiNapCoin.tuMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> lienKetMetaMask(String? address) async {
    final res = await _gui('POST', 'metamask', duLieu: {'address': address});
    _doc(res);
  }

  @override
  Future<Map<String, dynamic>> taoDonNap({
    required String packageId,
    String? orderId,
  }) async {
    return _doc(
      await _gui(
        'POST',
        'deposits',
        duLieu: {'packageId': packageId, 'checkout': true, 'orderId': ?orderId},
      ),
    );
  }

  @override
  Future<DonNapCoin?> layDonNapGanNhat() async {
    final don = _doc(await _gui('GET', 'deposits/latest'))['order'];
    return don is Map<String, dynamic> ? DonNapCoin.tuMap(don) : null;
  }

  @override
  Future<Map<String, dynamic>> nhanThuong({
    required String type,
    required String referenceId,
    String? description,
  }) async {
    final payload = <String, dynamic>{'type': type, 'referenceId': referenceId};
    if (description != null) payload['description'] = description;
    final res = await _gui('POST', 'claim-reward', duLieu: payload);
    return _doc(res);
  }
}
