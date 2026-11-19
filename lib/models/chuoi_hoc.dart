import 'dart:math' as math;

import 'cap_do.dart';

/// Trạng thái chuỗi học tập (Streak) và hệ thống Gamification của học viên.
///
/// Bao gồm:
/// - Chuỗi ngày liên tiếp hiện tại và kỷ lục dài nhất.
/// - Khiên bảo vệ chuỗi (Streak Freeze).
/// - Điểm kinh nghiệm (XP) và Cấp độ (Level).
/// - Mục tiêu học tập hàng ngày và danh sách huy hiệu thành tích đã đạt.
class ChuoiHoc {
  final int chuoiHienTai;
  final int chuoiDaiNhat;
  final String? ngayHocGanNhat;
  final int soKhiensFreeze;
  final int tongXp;
  final int mucTieuPhutMoiNgay;
  final Set<String> danhSachHuyHieu;
  final Set<String> cacNgayFreezeDaDung;

  const ChuoiHoc({
    this.chuoiHienTai = 0,
    this.chuoiDaiNhat = 0,
    this.ngayHocGanNhat,
    this.soKhiensFreeze = 0,
    this.tongXp = 0,
    this.mucTieuPhutMoiNgay = 10,
    this.danhSachHuyHieu = const {},
    this.cacNgayFreezeDaDung = const {},
  });

  /// Cấp độ hiện tại tính toán tự động từ tổng XP.
  CapDo get capDo => CapDo.tuTongXp(tongXp);

  /// Chuyển đổi DateTime sang định dạng chuẩn YYYY-MM-DD.
  static String dinhDangNgay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _chiLayNgayUtc(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  /// Kiểm tra hôm nay học viên đã có hoạt động học hợp lệ hay chưa.
  bool daHocHomNay([DateTime? thoiDiemHienTai]) {
    if (ngayHocGanNhat == null) return false;
    final homNay = dinhDangNgay(thoiDiemHienTai ?? DateTime.now());
    return ngayHocGanNhat == homNay;
  }

  /// Ghi nhận một ngày học hợp lệ (đủ 10 phút hoặc hoàn thành bài quiz/code).
  ///
  /// Xử lý logic tăng chuỗi, sử dụng Khiên Freeze tự động nếu có ngày bị lỡ,
  /// cộng XP và thưởng Khiên Freeze khi đạt mốc chuỗi 7 ngày hoặc thăng cấp chẵn.
  ChuoiHoc ghiNhanHocHopLe(DateTime thoiDiem, {int xpCongThem = 0}) {
    final ngayStr = dinhDangNgay(thoiDiem);
    final thoiDiemUtc = _chiLayNgayUtc(thoiDiem);

    var freezeConLai = soKhiensFreeze;
    final freezeDaDungMoi = Set<String>.from(cacNgayFreezeDaDung);
    int chuoiMoi;

    if (ngayHocGanNhat == null) {
      // Lần đầu tiên học trong đời
      chuoiMoi = 1;
    } else {
      final ganNhatUtc = _chiLayNgayUtc(DateTime.parse(ngayHocGanNhat!));
      final khoangCachNgay = thoiDiemUtc.difference(ganNhatUtc).inDays;

      if (khoangCachNgay == 0) {
        // Cùng ngày hôm nay: không tăng chuỗi thêm
        chuoiMoi = chuoiHienTai == 0 ? 1 : chuoiHienTai;
      } else if (khoangCachNgay == 1) {
        // Học liên tiếp ngày hôm sau: tăng 1 ngày
        chuoiMoi = (chuoiHienTai == 0 ? 0 : chuoiHienTai) + 1;
      } else if (khoangCachNgay > 1) {
        // Bỏ lỡ một số ngày
        final soNgayBiLo = khoangCachNgay - 1;

        if (freezeConLai >= soNgayBiLo && chuoiHienTai > 0) {
          // Có đủ Khiên Freeze để bảo vệ toàn bộ các ngày bị lỡ!
          // Đánh dấu các ngày dùng Freeze
          for (var i = 1; i <= soNgayBiLo; i++) {
            final ngayLoUtc = ganNhatUtc.add(Duration(days: i));
            freezeDaDungMoi.add(dinhDangNgay(ngayLoUtc));
          }
          freezeConLai -= soNgayBiLo;
          // Chuỗi nối tiếp bảo toàn cả ngày Freeze và ngày hôm nay
          chuoiMoi = chuoiHienTai + soNgayBiLo + 1;
        } else {
          // Không đủ Freeze -> đứt chuỗi, bắt đầu lại từ 1
          chuoiMoi = 1;
        }
      } else {
        // Học bù ngày cũ trong quá khứ
        chuoiMoi = chuoiHienTai;
      }
    }

    // Tặng miễn phí 1 Freeze khi chuỗi đạt mốc 7 ngày (hoặc bội số 7)
    if (chuoiMoi > chuoiHienTai && chuoiMoi % 7 == 0) {
      freezeConLai++;
    }

    // Tính toán XP và kiểm tra thưởng lên cấp
    final tongXpCu = tongXp;
    final tongXpMoi = math.max(0, tongXpCu + xpCongThem);

    final capCu = CapDo.tuTongXp(tongXpCu).capHienTai;
    final capMoi = CapDo.tuTongXp(tongXpMoi).capHienTai;
    if (capMoi > capCu && capMoi % 5 == 0) {
      // Thưởng thêm 1 Freeze khi đạt cấp mốc 5, 10, 15...
      freezeConLai++;
    }

    final kyLucMoi = math.max(chuoiDaiNhat, chuoiMoi);

    return ChuoiHoc(
      chuoiHienTai: chuoiMoi,
      chuoiDaiNhat: kyLucMoi,
      ngayHocGanNhat: ngayStr,
      soKhiensFreeze: freezeConLai,
      tongXp: tongXpMoi,
      mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
      danhSachHuyHieu: danhSachHuyHieu,
      cacNgayFreezeDaDung: freezeDaDungMoi,
    );
  }

  /// Kiểm tra trạng thái chuỗi khi mở app vào thời điểm `thoiDiem`.
  ///
  /// Tự động sử dụng Khiên Freeze nếu ngày hôm qua bị lỡ, hoặc đứt chuỗi về 0
  /// nếu không còn Khiên Freeze để bảo vệ.
  ChuoiHoc kiemTraVaDungFreezeTuDong(DateTime thoiDiem) {
    if (ngayHocGanNhat == null || chuoiHienTai == 0) return this;

    final ganNhatUtc = _chiLayNgayUtc(DateTime.parse(ngayHocGanNhat!));
    final thoiDiemUtc = _chiLayNgayUtc(thoiDiem);
    final khoangCachNgay = thoiDiemUtc.difference(ganNhatUtc).inDays;

    if (khoangCachNgay <= 1) {
      // Hôm nay hoặc hôm qua là ngày học gần nhất -> Chuỗi vẫn an toàn
      return this;
    }

    final soNgayBiLo = khoangCachNgay - 1;
    if (soKhiensFreeze >= soNgayBiLo) {
      // Tự động dùng Freeze để duy trì chuỗi
      final freezeDaDungMoi = Set<String>.from(cacNgayFreezeDaDung);
      for (var i = 1; i <= soNgayBiLo; i++) {
        final ngayLoUtc = ganNhatUtc.add(Duration(days: i));
        freezeDaDungMoi.add(dinhDangNgay(ngayLoUtc));
      }
      return ChuoiHoc(
        chuoiHienTai: chuoiHienTai + soNgayBiLo,
        chuoiDaiNhat: math.max(chuoiDaiNhat, chuoiHienTai + soNgayBiLo),
        ngayHocGanNhat: dinhDangNgay(ganNhatUtc.add(Duration(days: soNgayBiLo))),
        soKhiensFreeze: soKhiensFreeze - soNgayBiLo,
        tongXp: tongXp,
        mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
        danhSachHuyHieu: danhSachHuyHieu,
        cacNgayFreezeDaDung: freezeDaDungMoi,
      );
    } else {
      // Hết Freeze để bảo vệ -> Chuỗi bị đứt về 0
      return ChuoiHoc(
        chuoiHienTai: 0,
        chuoiDaiNhat: chuoiDaiNhat,
        ngayHocGanNhat: ngayHocGanNhat,
        soKhiensFreeze: soKhiensFreeze,
        tongXp: tongXp,
        mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
        danhSachHuyHieu: danhSachHuyHieu,
        cacNgayFreezeDaDung: cacNgayFreezeDaDung,
      );
    }
  }

  /// Cộng trực tiếp XP (ví dụ: thưởng thử thách, hỏi AI, hoàn thành mục tiêu).
  ChuoiHoc congXp(int xpCongThem) {
    if (xpCongThem <= 0) return this;
    final tongXpMoi = tongXp + xpCongThem;
    var freezeConLai = soKhiensFreeze;

    final capCu = CapDo.tuTongXp(tongXp).capHienTai;
    final capMoi = CapDo.tuTongXp(tongXpMoi).capHienTai;
    if (capMoi > capCu && capMoi % 5 == 0) {
      freezeConLai++;
    }

    return ChuoiHoc(
      chuoiHienTai: chuoiHienTai,
      chuoiDaiNhat: chuoiDaiNhat,
      ngayHocGanNhat: ngayHocGanNhat,
      soKhiensFreeze: freezeConLai,
      tongXp: tongXpMoi,
      mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
      danhSachHuyHieu: danhSachHuyHieu,
      cacNgayFreezeDaDung: cacNgayFreezeDaDung,
    );
  }

  /// Đổi điểm XP lấy Khiên bảo vệ chuỗi (Freeze).
  ChuoiHoc? muaFreeze({int giaXp = 100, int toiDa = 3}) {
    if (soKhiensFreeze >= toiDa || tongXp < giaXp) {
      return null; // Không đủ điều kiện mua
    }
    return ChuoiHoc(
      chuoiHienTai: chuoiHienTai,
      chuoiDaiNhat: chuoiDaiNhat,
      ngayHocGanNhat: ngayHocGanNhat,
      soKhiensFreeze: soKhiensFreeze + 1,
      tongXp: tongXp - giaXp,
      mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
      danhSachHuyHieu: danhSachHuyHieu,
      cacNgayFreezeDaDung: cacNgayFreezeDaDung,
    );
  }

  /// Cập nhật mục tiêu học tập hàng ngày (phút).
  ChuoiHoc datMucTieu(int soPhut) => ChuoiHoc(
        chuoiHienTai: chuoiHienTai,
        chuoiDaiNhat: chuoiDaiNhat,
        ngayHocGanNhat: ngayHocGanNhat,
        soKhiensFreeze: soKhiensFreeze,
        tongXp: tongXp,
        mucTieuPhutMoiNgay: soPhut > 0 ? soPhut : 10,
        danhSachHuyHieu: danhSachHuyHieu,
        cacNgayFreezeDaDung: cacNgayFreezeDaDung,
      );

  /// Mở khóa một huy hiệu thành tích mới.
  ChuoiHoc moKhoaHuyHieu(String maHuyHieu) {
    if (danhSachHuyHieu.contains(maHuyHieu)) return this;
    final moi = Set<String>.from(danhSachHuyHieu)..add(maHuyHieu);
    return ChuoiHoc(
      chuoiHienTai: chuoiHienTai,
      chuoiDaiNhat: chuoiDaiNhat,
      ngayHocGanNhat: ngayHocGanNhat,
      soKhiensFreeze: soKhiensFreeze,
      tongXp: tongXp,
      mucTieuPhutMoiNgay: mucTieuPhutMoiNgay,
      danhSachHuyHieu: moi,
      cacNgayFreezeDaDung: cacNgayFreezeDaDung,
    );
  }

  Map<String, dynamic> sangMap() => {
        'chuoiHienTai': chuoiHienTai,
        'chuoiDaiNhat': chuoiDaiNhat,
        'ngayHocGanNhat': ngayHocGanNhat,
        'soKhiensFreeze': soKhiensFreeze,
        'tongXp': tongXp,
        'mucTieuPhutMoiNgay': mucTieuPhutMoiNgay,
        'danhSachHuyHieu': danhSachHuyHieu.toList(),
        'cacNgayFreezeDaDung': cacNgayFreezeDaDung.toList(),
      };

  factory ChuoiHoc.tuMap(Map<dynamic, dynamic> m) => ChuoiHoc(
        chuoiHienTai: (m['chuoiHienTai'] as num?)?.toInt() ?? 0,
        chuoiDaiNhat: (m['chuoiDaiNhat'] as num?)?.toInt() ?? 0,
        ngayHocGanNhat: m['ngayHocGanNhat'] as String?,
        soKhiensFreeze: (m['soKhiensFreeze'] as num?)?.toInt() ?? 0,
        tongXp: (m['tongXp'] as num?)?.toInt() ?? 0,
        mucTieuPhutMoiNgay: (m['mucTieuPhutMoiNgay'] as num?)?.toInt() ?? 10,
        danhSachHuyHieu: ((m['danhSachHuyHieu'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        cacNgayFreezeDaDung: ((m['cacNgayFreezeDaDung'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChuoiHoc &&
          runtimeType == other.runtimeType &&
          chuoiHienTai == other.chuoiHienTai &&
          chuoiDaiNhat == other.chuoiDaiNhat &&
          ngayHocGanNhat == other.ngayHocGanNhat &&
          soKhiensFreeze == other.soKhiensFreeze &&
          tongXp == other.tongXp &&
          mucTieuPhutMoiNgay == other.mucTieuPhutMoiNgay &&
          danhSachHuyHieu.length == other.danhSachHuyHieu.length &&
          danhSachHuyHieu.containsAll(other.danhSachHuyHieu) &&
          cacNgayFreezeDaDung.length == other.cacNgayFreezeDaDung.length &&
          cacNgayFreezeDaDung.containsAll(other.cacNgayFreezeDaDung);

  @override
  int get hashCode => Object.hash(
        chuoiHienTai,
        chuoiDaiNhat,
        ngayHocGanNhat,
        soKhiensFreeze,
        tongXp,
        mucTieuPhutMoiNgay,
        Object.hashAll(danhSachHuyHieu),
        Object.hashAll(cacNgayFreezeDaDung),
      );

  @override
  String toString() =>
      'ChuoiHoc(chuoi: $chuoiHienTai/$chuoiDaiNhat, freeze: $soKhiensFreeze, XP: $tongXp (${capDo.danhHieu} Lv.${capDo.capHienTai}))';
}
