import 'package:hive_ce/hive_ce.dart';

import '../models/bai_hoc.dart';
import '../models/chuoi_hoc.dart';
import '../models/khoa_hoc.dart';
import '../models/nguoi_dung.dart';
import '../models/nhat_ky_ngay.dart';
import '../models/tien_do.dart';

/// Bộ chuyển đổi (TypeAdapter) cho Hive — **viết tay, không dùng codegen**.
///
/// Sách (Chương 7) dùng `@HiveType` + `build_runner` sinh ra các tệp
/// `*.g.dart`. Dự án này cố ý viết tay, vì ba lý do:
///
///   1. Sinh viên nhìn thấy *cái mà máy sinh ra*, hiểu được định dạng nhị
///      phân chứ không coi nó là phép thuật.
///   2. Không cần `build_runner`: `flutter pub get` xong là chạy được ngay,
///      không có bước "chạy lệnh sinh mã" hay bị kẹt vì phiên bản
///      `analyzer` xung đột — lỗi hay gặp nhất khi dạy trong phòng máy.
///   3. Mã viết tay chính là mã mà `hive_ce_generator` sinh ra, chỉ khác là
///      có chú thích. Ai muốn chuyển sang codegen thì xoá tệp này và thêm
///      chú giải `GenerateAdapters` — cấu trúc dữ liệu giữ nguyên.
///
/// ## Định dạng
///
/// Mỗi đối tượng được ghi theo khuôn: **một byte cho số trường**, rồi với
/// mỗi trường là **một byte số hiệu** và **giá trị**. Đọc lại thì dựng một
/// `Map<int, dynamic>` rồi lấy theo số hiệu.
///
/// Vì sao rườm rà như vậy thay vì ghi tuần tự: số hiệu trường cho phép
/// **thêm trường mới mà không hỏng dữ liệu cũ**. Bản cũ không có trường 13
/// thì `fields[13]` là null và ta dùng giá trị mặc định. Quy tắc duy nhất
/// phải giữ: **số hiệu đã dùng thì không bao giờ dùng lại cho trường khác**.

/// Số hiệu kiểu. Cũng vậy: đã cấp thì không đổi.
class MaKieu {
  MaKieu._();
  static const int baiHoc = 1;
  static const int khoaHoc = 2;
  static const int tienDo = 3;
  static const int nguoiDung = 4;
  static const int chuoiHoc = 5;
  static const int nhatKyNgay = 6;
}

/// Đọc phần đầu chung: số trường + bảng trường.
Map<int, dynamic> _docTruong(BinaryReader reader) {
  final soTruong = reader.readByte();
  return <int, dynamic>{
    for (var i = 0; i < soTruong; i++) reader.readByte(): reader.read(),
  };
}

class BaiHocAdapter extends TypeAdapter<BaiHoc> {
  @override
  final int typeId = MaKieu.baiHoc;

  @override
  BaiHoc read(BinaryReader reader) {
    final f = _docTruong(reader);
    return BaiHoc(
      ma: f[0] as String,
      tieuDe: f[1] as String,
      thoiLuongGiay: f[2] as int,
      xemThu: f[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, BaiHoc obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.ma)
      ..writeByte(1)
      ..write(obj.tieuDe)
      ..writeByte(2)
      ..write(obj.thoiLuongGiay)
      ..writeByte(3)
      ..write(obj.xemThu);
  }
}

class KhoaHocAdapter extends TypeAdapter<KhoaHoc> {
  @override
  final int typeId = MaKieu.khoaHoc;

  @override
  KhoaHoc read(BinaryReader reader) {
    final f = _docTruong(reader);
    return KhoaHoc(
      ma: f[0] as String,
      tieuDe: f[1] as String,
      giangVien: f[2] as String,
      moTaNgan: f[3] as String,
      moTaDai: f[4] as String,
      danhMuc: f[5] as String,
      // Enum lưu bằng TÊN chứ không bằng số thứ tự: chèn thêm một mức độ
      // vào giữa `MucDo` là mọi bản ghi cũ lệch hết nếu lưu bằng số.
      mucDo: MucDo.tuTen(f[6] as String?),
      diemDanhGia: (f[7] as num).toDouble(),
      soLuotDanhGia: f[8] as int,
      gia: f[9] as int,
      anhBia: f[10] as String,
      noiBat: f[11] as bool? ?? false,
      // Hive trả về `List<dynamic>`; phải ép kiểu tường minh.
      baiHoc: (f[12] as List).cast<BaiHoc>(),
    );
  }

  @override
  void write(BinaryWriter writer, KhoaHoc obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.ma)
      ..writeByte(1)
      ..write(obj.tieuDe)
      ..writeByte(2)
      ..write(obj.giangVien)
      ..writeByte(3)
      ..write(obj.moTaNgan)
      ..writeByte(4)
      ..write(obj.moTaDai)
      ..writeByte(5)
      ..write(obj.danhMuc)
      ..writeByte(6)
      ..write(obj.mucDo.name)
      ..writeByte(7)
      ..write(obj.diemDanhGia)
      ..writeByte(8)
      ..write(obj.soLuotDanhGia)
      ..writeByte(9)
      ..write(obj.gia)
      ..writeByte(10)
      ..write(obj.anhBia)
      ..writeByte(11)
      ..write(obj.noiBat)
      ..writeByte(12)
      ..write(obj.baiHoc);
  }
}

class TienDoAdapter extends TypeAdapter<TienDo> {
  @override
  final int typeId = MaKieu.tienDo;

  @override
  TienDo read(BinaryReader reader) {
    final f = _docTruong(reader);
    return TienDo(
      maKhoaHoc: f[0] as String,
      // Lưu List rồi đọc ra Set: Hive không có kiểu Set trong định dạng
      // nhị phân cơ bản, nên quy đổi ở biên là chuyện bình thường.
      baiDaXong: (f[1] as List).cast<String>().toSet(),
      baiDangXem: f[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TienDo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.maKhoaHoc)
      ..writeByte(1)
      ..write(obj.baiDaXong.toList())
      ..writeByte(2)
      ..write(obj.baiDangXem);
  }
}

class NguoiDungAdapter extends TypeAdapter<NguoiDung> {
  @override
  final int typeId = MaKieu.nguoiDung;

  @override
  NguoiDung read(BinaryReader reader) {
    final f = _docTruong(reader);
    return NguoiDung(
      email: f[0] as String,
      hoTen: f[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NguoiDung obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.hoTen);
  }
}

class ChuoiHocAdapter extends TypeAdapter<ChuoiHoc> {
  @override
  final int typeId = MaKieu.chuoiHoc;

  @override
  ChuoiHoc read(BinaryReader reader) {
    final f = _docTruong(reader);
    return ChuoiHoc(
      chuoiHienTai: (f[0] as num?)?.toInt() ?? 0,
      chuoiDaiNhat: (f[1] as num?)?.toInt() ?? 0,
      ngayHocGanNhat: f[2] as String?,
      soKhiensFreeze: (f[3] as num?)?.toInt() ?? 0,
      tongXp: (f[4] as num?)?.toInt() ?? 0,
      mucTieuPhutMoiNgay: (f[5] as num?)?.toInt() ?? 10,
      danhSachHuyHieu: ((f[6] as List?) ?? const []).cast<String>().toSet(),
      cacNgayFreezeDaDung: ((f[7] as List?) ?? const []).cast<String>().toSet(),
    );
  }

  @override
  void write(BinaryWriter writer, ChuoiHoc obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.chuoiHienTai)
      ..writeByte(1)
      ..write(obj.chuoiDaiNhat)
      ..writeByte(2)
      ..write(obj.ngayHocGanNhat)
      ..writeByte(3)
      ..write(obj.soKhiensFreeze)
      ..writeByte(4)
      ..write(obj.tongXp)
      ..writeByte(5)
      ..write(obj.mucTieuPhutMoiNgay)
      ..writeByte(6)
      ..write(obj.danhSachHuyHieu.toList())
      ..writeByte(7)
      ..write(obj.cacNgayFreezeDaDung.toList());
  }
}

class NhatKyNgayAdapter extends TypeAdapter<NhatKyNgay> {
  @override
  final int typeId = MaKieu.nhatKyNgay;

  @override
  NhatKyNgay read(BinaryReader reader) {
    final f = _docTruong(reader);
    return NhatKyNgay(
      ngay: f[0] as String,
      thoiGianHocGiay: (f[1] as num?)?.toInt() ?? 0,
      baiDaHoanThanh: ((f[2] as List?) ?? const []).cast<String>().toSet(),
      khoaHocDaThamGia: ((f[3] as List?) ?? const []).cast<String>().toSet(),
      xpNhanDuoc: (f[4] as num?)?.toInt() ?? 0,
      dungFreeze: f[5] as bool? ?? false,
      hoatDongDuyTri: f[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NhatKyNgay obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.ngay)
      ..writeByte(1)
      ..write(obj.thoiGianHocGiay)
      ..writeByte(2)
      ..write(obj.baiDaHoanThanh.toList())
      ..writeByte(3)
      ..write(obj.khoaHocDaThamGia.toList())
      ..writeByte(4)
      ..write(obj.xpNhanDuoc)
      ..writeByte(5)
      ..write(obj.dungFreeze)
      ..writeByte(6)
      ..write(obj.hoatDongDuyTri);
  }
}

/// Đăng ký tất cả bộ chuyển đổi. Gọi đúng một lần, trước khi mở hộp nào.
///
/// `isAdapterRegistered` là chốt an toàn cho `flutter test`: mỗi bài kiểm
/// thử gọi lại hàm này thì không bị ném lỗi "đã đăng ký rồi".
void dangKyBoChuyenDoi() {
  void dangKy<T>(int ma, TypeAdapter<T> bo) {
    if (!Hive.isAdapterRegistered(ma)) Hive.registerAdapter<T>(bo);
  }

  dangKy(MaKieu.baiHoc, BaiHocAdapter());
  dangKy(MaKieu.khoaHoc, KhoaHocAdapter());
  dangKy(MaKieu.tienDo, TienDoAdapter());
  dangKy(MaKieu.nguoiDung, NguoiDungAdapter());
  dangKy(MaKieu.chuoiHoc, ChuoiHocAdapter());
  dangKy(MaKieu.nhatKyNgay, NhatKyNgayAdapter());
}
