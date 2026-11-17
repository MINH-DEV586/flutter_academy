import 'package:flutter_academy/data/kho_du_lieu.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';
import 'package:flutter_academy/models/nguoi_dung.dart';
import 'package:flutter_academy/models/tien_do.dart';

/// Ba kho dữ liệu giả lập, giữ mọi thứ trong bộ nhớ.
///
/// **Viết tay, không dùng thư viện giả lập nào.** Ba lớp này cộng lại chưa
/// tới 80 dòng, trong khi `mockito` hay `mocktail` kéo theo một gói phụ
/// thuộc, một bước sinh mã, và một cú pháp riêng phải học. Với một tầng kho
/// dữ liệu chỉ có tám phương thức thì viết tay vừa ngắn hơn vừa dễ đọc hơn.
///
/// Đây cũng là lý do `kho_du_lieu.dart` khai báo giao diện trừu tượng chứ
/// không để màn hình gọi thẳng Hive: có giao diện thì thay bằng bản giả lập
/// là chuyện một dòng.
class KhoKhoaHocGiaLap implements KhoKhoaHoc {
  final List<KhoaHoc> duLieu;

  /// Đặt true để mọi lời gọi ném lỗi — dùng kiểm thử nhánh hiển thị lỗi.
  bool gayLoi;

  KhoKhoaHocGiaLap(this.duLieu, {this.gayLoi = false});

  @override
  Future<List<KhoaHoc>> tatCa() async {
    if (gayLoi) throw Exception('Hỏng kho khoá học');
    return List.of(duLieu);
  }

  @override
  Future<KhoaHoc?> theoMa(String ma) async {
    if (gayLoi) throw Exception('Hỏng kho khoá học');
    for (final k in duLieu) {
      if (k.ma == ma) return k;
    }
    return null;
  }
}

class KhoTienDoGiaLap implements KhoTienDo {
  final Map<String, TienDo> duLieu;
  bool gayLoi;

  /// Đếm số lần ghi, để kiểm tra "cập nhật lạc quan" có thật sự ghi xuống kho.
  int soLanLuu = 0;

  KhoTienDoGiaLap([Map<String, TienDo>? ban])
      : duLieu = {...?ban},
        gayLoi = false;

  @override
  Future<TienDo> cua(String maKhoaHoc) async =>
      duLieu[maKhoaHoc] ?? TienDo(maKhoaHoc: maKhoaHoc);

  @override
  Future<List<TienDo>> tatCa() async => duLieu.values.toList();

  @override
  Future<void> luu(TienDo tienDo) async {
    if (gayLoi) throw Exception('Hỏng kho tiến độ');
    soLanLuu++;
    duLieu[tienDo.maKhoaHoc] = tienDo;
  }

  @override
  Future<void> xoa(String maKhoaHoc) async {
    if (gayLoi) throw Exception('Hỏng kho tiến độ');
    duLieu.remove(maKhoaHoc);
  }
}

class KhoNguoiDungGiaLap implements KhoNguoiDung {
  NguoiDung? duLieu;
  bool gayLoi;
  final _dangKy = <String, Set<String>>{};

  KhoNguoiDungGiaLap({this.duLieu, this.gayLoi = false});

  @override
  Future<NguoiDung?> hienTai() async => duLieu;

  @override
  Future<NguoiDung> dangNhap({
    required String email,
    required String matKhau,
  }) => dangKy(email: email, matKhau: matKhau, hoTen: 'Người học');

  @override
  Future<NguoiDung> dangKy({
    required String email,
    required String hoTen,
    required String matKhau,
  }) async {
    if (gayLoi) throw Exception('Không ghi được hồ sơ');
    final nguoiDung = NguoiDung(email: email, hoTen: hoTen);
    return duLieu = nguoiDung;
  }

  @override
  Future<void> dangXuat() async {
    duLieu = null;
  }

  @override
  Future<Set<String>> khoaDaDangKy() async => {...?_dangKy[duLieu?.email]};

  @override
  Future<void> dangKyKhoaHoc(String maKhoaHoc) async {
    final email = duLieu?.email;
    if (email == null) throw StateError('Chưa đăng nhập');
    _dangKy.putIfAbsent(email, () => {}).add(maKhoaHoc);
  }
}
