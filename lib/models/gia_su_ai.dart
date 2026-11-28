typedef HoiThoaiTutor = ({String email, String bai});

class LuotHoiTutor {
  const LuotHoiTutor(this.duLieu);
  final Map<String, dynamic> duLieu;

  String get cauHoi => duLieu['cauHoi'] as String;
  String get mucDo => duLieu['mucDo'] as String;
  String get traLoi => duLieu['traLoi'] as String? ?? '';
  bool get demo => duLieu['demo'] == true;
  bool get hoanTat => duLieu['hoanTat'] == true;
  Map<String, dynamic>? get nguon => duLieu['nguon'] as Map<String, dynamic>?;
  Map<String, dynamic>? get quiz => duLieu['quiz'] as Map<String, dynamic>?;
  int? get daChon => duLieu['daChon'] as int?;

  LuotHoiTutor capNhat(Map<String, dynamic> moi) =>
      LuotHoiTutor.tuJson({...duLieu, ...moi});

  static LuotHoiTutor tuJson(Object? json) {
    final muc = LuotHoiTutor(json as Map<String, dynamic>);
    if (muc.cauHoi.isEmpty || muc.mucDo.isEmpty || muc.traLoi.length > 30000) {
      throw const FormatException('Lượt hỏi không hợp lệ');
    }
    final nguon = muc.nguon;
    if (nguon != null &&
        (nguon['ten'] is! String ||
            nguon['trang'] is! int ||
            nguon['duongDan'] is! String)) {
      throw const FormatException('Nguồn không hợp lệ');
    }
    final quiz = muc.quiz;
    if (quiz != null) {
      final luaChon = quiz['luaChon'];
      final dung = quiz['dung'];
      final daChon = muc.daChon;
      if (quiz['cauHoi'] is! String ||
          quiz['giaiThich'] is! String ||
          luaChon is! List ||
          luaChon.any((muc) => muc is! String) ||
          dung is! int ||
          dung < 0 ||
          dung >= luaChon.length ||
          (daChon != null && (daChon < 0 || daChon >= luaChon.length))) {
        throw const FormatException('Quiz không hợp lệ');
      }
    }
    return muc;
  }
}

class LoiTutor implements Exception {
  const LoiTutor(this.thongBao, {this.resetAt});
  final String thongBao;
  final DateTime? resetAt;
}
