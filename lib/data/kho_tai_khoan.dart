import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../models/nguoi_dung.dart';
import '../models/thuong_hoc.dart';
import 'kho_du_lieu.dart';
import 'kho_gia_su_ai.dart';

class KhoTaiKhoan implements KhoNguoiDung {
  KhoTaiKhoan(this._phien);

  static const _diaChi = String.fromEnvironment(
    'ACCOUNT_API_URL',
    defaultValue: 'http://127.0.0.1:8787/api/account',
  );
  static const _khoaToken = 'token';
  final Box<String> _phien;

  Future<http.Response> _gui(
    String method,
    String path, {
    Map<String, Object>? duLieu,
    String? token,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request(method, Uri.parse('$_diaChi/$path'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
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
      throw const LoiTaiKhoan(
        'Máy chủ tài khoản đang gặp lỗi. Vui lòng thử lại.',
      );
    }
    final duLieu =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw LoiTaiKhoan(
        duLieu['loi'] as String? ?? 'Yêu cầu tài khoản thất bại.',
      );
    }
    return duLieu;
  }

  @override
  Future<NguoiDung?> hienTai() async {
    final token = _phien.get(_khoaToken);
    if (token == null) return null;
    final response = await _gui('GET', 'session', token: token);
    if (response.statusCode == 401) {
      await _phien.delete(_khoaToken);
      return null;
    }
    return NguoiDung.tuMap(_doc(response)['nguoiDung'] as Map);
  }

  Future<NguoiDung> _xacThuc(String path, Map<String, String> duLieu) async {
    final ketQua = _doc(await _gui('POST', path, duLieu: duLieu));
    final nguoiDung = NguoiDung.tuMap(ketQua['nguoiDung'] as Map);
    await _phien.put(_khoaToken, ketQua['token'] as String);
    return nguoiDung;
  }

  @override
  Future<NguoiDung> dangNhap({
    required String email,
    required String matKhau,
  }) => _xacThuc('login', {'email': email, 'matKhau': matKhau});

  @override
  Future<NguoiDung> dangKy({
    required String email,
    required String hoTen,
    required String matKhau,
  }) => _xacThuc('register', {
    'email': email,
    'hoTen': hoTen,
    'matKhau': matKhau,
  });

  @override
  Future<void> dangXuat() async {
    final token = _phien.get(_khoaToken);
    if (token == null) return;
    final response = await _gui('DELETE', 'session', token: token);
    if (response.statusCode != 401) _doc(response);
    await _phien.delete(_khoaToken);
  }

  String _docToken() {
    final token = _phien.get(_khoaToken);
    if (token == null) {
      throw const LoiTaiKhoan('Vui lòng đăng nhập để đăng ký khóa học.');
    }
    return token;
  }

  @override
  Future<Set<String>> khoaDaDangKy() async {
    final response = await _gui('GET', 'enrollments', token: _docToken());
    return (_doc(response)['maKhoaHoc'] as List).cast<String>().toSet();
  }

  @override
  Future<void> dangKyKhoaHoc(String maKhoaHoc, {int? soTien}) async {
    final response = await _gui(
      'POST',
      soTien == null ? 'enrollments' : 'purchases/demo',
      token: _docToken(),
      duLieu: {'maKhoaHoc': maKhoaHoc, if (soTien != null) 'soTien': soTien},
    );
    _doc(response);
  }

  Future<Map<String, dynamic>> _thuong(
    String method,
    String path, [
    Map<String, String>? duLieu,
  ]) async =>
      _doc(await _gui(method, path, token: _docToken(), duLieu: duLieu));

  @override
  Future<ThuongHoc> thuongHoc() async =>
      ThuongHoc.tuMap(await _thuong('GET', 'rewards'));

  @override
  Future<ThuongHoc> ghiNhanNgayHoc(String baiHoc) async => ThuongHoc.tuMap(
    await _thuong('POST', 'rewards/complete', {'baiHoc': baiHoc}),
  );

  @override
  Future<String> yeuCauDoiPro(String vi) async =>
      (await _thuong('POST', 'rewards/redeem', {'vi': vi}))['payload']
          as String;

  @override
  Future<ThuongHoc> xacNhanDoiPro(String hash) async =>
      ThuongHoc.tuMap(await _thuong('POST', 'rewards/confirm', {'hash': hash}));

  @override
  Future<String> hoiAi({
    required String baiHoc,
    required String cauHoi,
    required String mucDo,
  }) => KhoGiaSuAi.hoi(
    baiHoc: baiHoc,
    cauHoi: cauHoi,
    mucDo: mucDo,
    token: _phien.get(_khoaToken),
  );
}
