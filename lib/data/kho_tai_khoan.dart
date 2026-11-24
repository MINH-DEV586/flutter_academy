import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../cau_hinh/may_chu.dart';
import '../models/chuoi_hoc.dart';
import '../models/nguoi_dung.dart';
import 'kho_du_lieu.dart';

class KhoTaiKhoan implements KhoNguoiDung, KhoDongBoChuoiHoc {
  KhoTaiKhoan(this._phien);

  static final _diaChi = MayChu.taiKhoan;
  static const _khoaToken = 'token';
  static const _khoaTaiKhoanStreak = 'tai_khoan_streak';
  final Box<String> _phien;

  Future<http.Response> _gui(
    String method,
    String path, {
    Map<String, dynamic>? duLieu,
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
  Future<void> dangKyKhoaHoc(String maKhoaHoc) async {
    final response = await _gui(
      'POST',
      'enrollments',
      token: _docToken(),
      duLieu: {'maKhoaHoc': maKhoaHoc},
    );
    _doc(response);
  }

  @override
  Future<ChuoiHoc> layChuoiHoc(
    String email, {
    required ChuoiHoc duLieuCucBo,
  }) async {
    final response = await _gui('GET', 'streak', token: _docToken());
    final duLieu = _doc(response);
    if (duLieu['tonTai'] == true) {
      await _phien.put(_khoaTaiKhoanStreak, email);
      return ChuoiHoc.tuMap(duLieu);
    }

    final taiKhoanTruoc = _phien.get(_khoaTaiKhoanStreak);
    final duLieuNhap = taiKhoanTruoc == null || taiKhoanTruoc == email
        ? duLieuCucBo
        : const ChuoiHoc();
    await luuChuoiHoc(email, duLieuNhap);
    return duLieuNhap;
  }

  @override
  Future<void> luuChuoiHoc(String email, ChuoiHoc chuoiHoc) async {
    final duLieu = chuoiHoc.sangMap()
      ..['capHienTai'] = chuoiHoc.capDo.capHienTai;
    final response = await _gui(
      'POST',
      'streak',
      token: _docToken(),
      duLieu: duLieu,
    );
    _doc(response);
    await _phien.put(_khoaTaiKhoanStreak, email);
  }
}
