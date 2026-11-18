import 'package:flutter_academy/data/du_lieu_mau.dart';
import 'package:flutter_academy/data/gioi_thieu_khoa_hoc.dart';
import 'package:flutter_academy/data/tai_lieu_bai_hoc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mỗi bài trong danh mục có video YouTube riêng và đúng nguồn', () async {
    final container = ProviderContainer.test();
    final taiLieu = await container.read(taiLieuBaiHocProvider.future);

    final khoaHoc = DuLieuMau.khoaHoc();
    expect(
      khoaHoc.map((khoa) => khoa.ma),
      unorderedEquals([
        'flutter-nhap-mon',
        'trang-thai-flutter',
        'dieu-huong-url',
        'python-co-ban',
        'java-co-ban',
      ]),
    );
    expect(khoaHoc.where((khoa) => khoa.mienPhi), hasLength(4));
    final java = khoaHoc.singleWhere((khoa) => khoa.ma == 'java-co-ban');
    expect(java.gia, 99000);
    expect(java.baiHoc.where((bai) => bai.xemThu).map((bai) => bai.ma), ['b1']);
    final cacBai = {
      for (final khoa in khoaHoc)
        for (final bai in khoa.baiHoc) '${khoa.ma}/${bai.ma}',
    };
    expect(taiLieu.keys, unorderedEquals(cacBai));
    final idVideo = <String>{};
    for (final bai in taiLieu.values) {
      expect(bai.youtubeId, matches(RegExp(r'^[\w-]{11}$')));
      expect(bai.kenhYouTube, isNotEmpty);
      expect(idVideo.add(bai.youtubeId!), isTrue);
    }
    expect(taiLieu['dieu-huong-url/b1']?.youtubeId, 'b6Z885Z46cU');
    expect(taiLieu['dieu-huong-url/b2']?.code, contains('queryParameters'));
    expect(taiLieu['dieu-huong-url/b3']?.code, contains('ShellRoute'));
  });

  test('trang giới thiệu có mục tiêu, yêu cầu và đủ các bài theo chương', () {
    for (final khoa in DuLieuMau.khoaHoc()) {
      final gioiThieu = GioiThieuKhoaHoc.cua(khoa.ma)!;
      expect(gioiThieu.mucTieu, isNotEmpty, reason: khoa.ma);
      expect(gioiThieu.yeuCau, isNotEmpty, reason: khoa.ma);
      expect(
        gioiThieu.chuong.values.expand((ma) => ma),
        orderedEquals(khoa.baiHoc.map((bai) => bai.ma)),
        reason: khoa.ma,
      );
      expect(gioiThieu.chiaChuong(khoa), hasLength(2), reason: khoa.ma);
    }
  });
}
