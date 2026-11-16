import 'package:flutter_academy/models/bai_hoc.dart';
import 'package:flutter_academy/models/khoa_hoc.dart';

/// Dữ liệu dùng chung cho các bài kiểm thử.
///
/// Cố ý **không** dùng `DuLieuMau` của ứng dụng: bài kiểm thử phải cố định,
/// còn dữ liệu mẫu thì sẽ đổi khi thêm khoá học mới. Dùng chung là một hôm
/// nào đó thêm một khoá học rồi cả chục bài kiểm thử đỏ lên mà không ai hiểu
/// vì sao.
KhoaHoc kh({
  required String ma,
  String? tieuDe,
  String giangVien = 'Người dạy',
  String danhMuc = 'Web',
  MucDo mucDo = MucDo.coBan,
  double diem = 4.0,
  int luot = 100,
  int gia = 0,
  bool noiBat = false,
  int soBai = 3,
}) {
  return KhoaHoc(
    ma: ma,
    tieuDe: tieuDe ?? ma,
    giangVien: giangVien,
    moTaNgan: 'mô tả ngắn',
    moTaDai: 'mô tả dài',
    danhMuc: danhMuc,
    mucDo: mucDo,
    diemDanhGia: diem,
    soLuotDanhGia: luot,
    gia: gia,
    anhBia: 'khong_co.png',
    noiBat: noiBat,
    baiHoc: [
      for (var i = 1; i <= soBai; i++)
        BaiHoc(ma: 'b$i', tieuDe: 'Bài $i', thoiLuongGiay: 600, xemThu: i == 1),
    ],
  );
}

/// Sáu khoá học phủ đủ các nhánh lọc: có/không miễn phí, ba mức độ, hai danh
/// mục, điểm và lượt đánh giá khác nhau.
List<KhoaHoc> boMau() => [
      kh(
        ma: 'a-dieu-huong',
        tieuDe: 'Điều hướng theo URL',
        danhMuc: 'Web',
        mucDo: MucDo.trungCap,
        diem: 4.9,
        luot: 300,
        gia: 490000,
        noiBat: true,
      ),
      kh(
        ma: 'b-hive',
        tieuDe: 'Lưu trữ với Hive',
        danhMuc: 'Dữ liệu',
        mucDo: MucDo.trungCap,
        diem: 4.6,
        luot: 500,
        gia: 390000,
      ),
      kh(
        ma: 'c-dart',
        tieuDe: 'Dart cơ bản',
        danhMuc: 'Nhập môn',
        mucDo: MucDo.coBan,
        diem: 4.8,
        luot: 900,
        gia: 0,
        noiBat: true,
      ),
      kh(
        ma: 'd-mvvm',
        tieuDe: 'Kiến trúc MVVM',
        danhMuc: 'Kiến trúc',
        mucDo: MucDo.nangCao,
        diem: 4.9,
        luot: 200,
        gia: 690000,
      ),
      kh(
        ma: 'e-kiem-thu',
        tieuDe: 'Kiểm thử Flutter',
        danhMuc: 'Nhập môn',
        mucDo: MucDo.trungCap,
        diem: 4.5,
        luot: 500,
        gia: 0,
      ),
      kh(
        ma: 'f-wasm',
        tieuDe: 'Flutter Web và WebAssembly',
        danhMuc: 'Web',
        mucDo: MucDo.nangCao,
        diem: 4.8,
        luot: 120,
        gia: 590000,
      ),
    ];

/// Rút danh sách mã theo đúng thứ tự, cho `expect` đọc dễ hiểu.
List<String> ma(List<KhoaHoc> ds) => ds.map((k) => k.ma).toList();
