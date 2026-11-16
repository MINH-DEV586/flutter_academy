import 'khoa_hoc.dart';
import 'tim_kiem.dart';

/// Thứ tự sắp xếp danh sách khoá học.
///
/// `ma` là giá trị đi vào URL (`?sap=danh-gia`). Không dùng `name` của enum
/// vì tên biến camelCase nằm trong URL trông xấu và khó gõ.
enum ThuTuSapXep {
  phoBien('pho-bien', 'Phổ biến'),
  danhGiaCao('danh-gia', 'Đánh giá cao'),
  giaTang('gia-tang', 'Giá tăng dần'),
  giaGiam('gia-giam', 'Giá giảm dần'),
  tenAZ('ten', 'Tên A → Z');

  final String ma;
  final String nhan;
  const ThuTuSapXep(this.ma, this.nhan);

  static ThuTuSapXep tuMa(String? ma) => ThuTuSapXep.values
      .firstWhere((e) => e.ma == ma, orElse: () => ThuTuSapXep.phoBien);
}

/// Toàn bộ điều kiện lọc của trang danh sách khoá học.
///
/// Vì sao gom vào một lớp bất biến thay vì năm biến rời trong màn hình:
///
///   1. **URL.** Trên web, trạng thái lọc phải nằm trong thanh địa chỉ thì
///      người dùng mới chia sẻ hay F5 được. Một lớp thì có đúng một cặp hàm
///      `sangThamSo` / `tuThamSo` để đồng bộ với URL.
///   2. **Kiểm thử.** `apDung` là hàm thuần: vào một danh sách, ra một danh
///      sách. Không cần `WidgetTester`, không cần Hive.
///
/// Đây là điểm khác biệt lớn nhất giữa làm ứng dụng di động và làm web, và
/// cũng là bài học trung tâm của Chương 5 trong sách.
class BoLoc {
  final String tuKhoa;

  /// null nghĩa là "tất cả danh mục".
  final String? danhMuc;

  /// null nghĩa là "mọi mức độ".
  final MucDo? mucDo;

  final bool chiMienPhi;
  final ThuTuSapXep thuTu;

  const BoLoc({
    this.tuKhoa = '',
    this.danhMuc,
    this.mucDo,
    this.chiMienPhi = false,
    this.thuTu = ThuTuSapXep.phoBien,
  });

  static const BoLoc macDinh = BoLoc();

  /// Có đang lọc gì không. Dùng để quyết định hiện nút "Xoá bộ lọc".
  bool get coLoc =>
      tuKhoa.trim().isNotEmpty ||
      danhMuc != null ||
      mucDo != null ||
      chiMienPhi;

  /// `copyVoi` thường không xoá được giá trị về null. Ở đây cần xoá được
  /// (bỏ lọc danh mục), nên dùng cờ `xoaDanhMuc` / `xoaMucDo` rõ ràng thay vì
  /// mẹo `Object? sentinel` khó đọc.
  BoLoc copyVoi({
    String? tuKhoa,
    String? danhMuc,
    MucDo? mucDo,
    bool? chiMienPhi,
    ThuTuSapXep? thuTu,
    bool xoaDanhMuc = false,
    bool xoaMucDo = false,
  }) {
    return BoLoc(
      tuKhoa: tuKhoa ?? this.tuKhoa,
      danhMuc: xoaDanhMuc ? null : (danhMuc ?? this.danhMuc),
      mucDo: xoaMucDo ? null : (mucDo ?? this.mucDo),
      chiMienPhi: chiMienPhi ?? this.chiMienPhi,
      thuTu: thuTu ?? this.thuTu,
    );
  }

  // ------------------------------------------------------------------
  // Đồng bộ với URL
  // ------------------------------------------------------------------

  /// Sinh tham số truy vấn cho URL. Bỏ qua các giá trị mặc định để URL ngắn:
  /// `/khoa-hoc` sạch hơn `/khoa-hoc?q=&danh-muc=&sap=pho-bien`.
  Map<String, String> sangThamSo() {
    final ra = <String, String>{};
    final q = tuKhoa.trim();
    if (q.isNotEmpty) ra['q'] = q;
    if (danhMuc != null) ra['danh-muc'] = danhMuc!;
    if (mucDo != null) ra['muc-do'] = mucDo!.name;
    if (chiMienPhi) ra['mien-phi'] = '1';
    if (thuTu != ThuTuSapXep.phoBien) ra['sap'] = thuTu.ma;
    return ra;
  }

  /// Đọc ngược từ tham số truy vấn. Mọi giá trị lạ đều lùi về mặc định —
  /// người dùng sửa tay URL không được làm sập ứng dụng.
  factory BoLoc.tuThamSo(Map<String, String> thamSo) {
    final tenMucDo = thamSo['muc-do'];
    return BoLoc(
      tuKhoa: thamSo['q'] ?? '',
      danhMuc: _rongThanhNull(thamSo['danh-muc']),
      mucDo: _mucDoTuTen(tenMucDo),
      chiMienPhi: thamSo['mien-phi'] == '1',
      thuTu: ThuTuSapXep.tuMa(thamSo['sap']),
    );
  }

  static String? _rongThanhNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;

  /// Khác `MucDo.tuTen`: ở đây giá trị lạ phải thành null ("mọi mức độ"),
  /// chứ không lùi về `coBan` — lùi về `coBan` là âm thầm lọc mất dữ liệu.
  static MucDo? _mucDoTuTen(String? ten) {
    if (ten == null) return null;
    for (final m in MucDo.values) {
      if (m.name == ten) return m;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Áp dụng
  // ------------------------------------------------------------------

  /// Lọc rồi sắp xếp. Không sửa danh sách đầu vào.
  List<KhoaHoc> apDung(List<KhoaHoc> nguon) {
    final ra = nguon.where(_giuLai).toList();
    ra.sort(_soSanh);
    return ra;
  }

  bool _giuLai(KhoaHoc k) {
    if (danhMuc != null && k.danhMuc != danhMuc) return false;
    if (mucDo != null && k.mucDo != mucDo) return false;
    if (chiMienPhi && !k.mienPhi) return false;
    if (!khopTuKhoa('${k.tieuDe} ${k.giangVien} ${k.moTaNgan} ${k.danhMuc}',
        tuKhoa)) {
      return false;
    }
    return true;
  }

  int _soSanh(KhoaHoc a, KhoaHoc b) {
    final chinh = switch (thuTu) {
      ThuTuSapXep.phoBien => b.soLuotDanhGia.compareTo(a.soLuotDanhGia),
      ThuTuSapXep.danhGiaCao => b.diemDanhGia.compareTo(a.diemDanhGia),
      ThuTuSapXep.giaTang => a.gia.compareTo(b.gia),
      ThuTuSapXep.giaGiam => b.gia.compareTo(a.gia),
      ThuTuSapXep.tenAZ => 0,
    };
    // Bằng điểm thì xếp theo tên, để thứ tự luôn ổn định. Không có bước này,
    // hai lần lọc giống nhau có thể cho hai thứ tự khác nhau và bài kiểm thử
    // sẽ "lúc xanh lúc đỏ".
    if (chinh != 0) return chinh;
    return khongDau(a.tieuDe).compareTo(khongDau(b.tieuDe));
  }

  @override
  bool operator ==(Object other) =>
      other is BoLoc &&
      other.tuKhoa == tuKhoa &&
      other.danhMuc == danhMuc &&
      other.mucDo == mucDo &&
      other.chiMienPhi == chiMienPhi &&
      other.thuTu == thuTu;

  @override
  int get hashCode => Object.hash(tuKhoa, danhMuc, mucDo, chiMienPhi, thuTu);

  @override
  String toString() => 'BoLoc(${sangThamSo()})';
}
