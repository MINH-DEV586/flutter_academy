import 'package:flutter_academy/data/du_lieu_mau.dart';
import 'package:flutter_academy/data/tai_lieu_bai_hoc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mỗi bài trong danh mục có video YouTube riêng và đúng nguồn', () async {
    final container = ProviderContainer.test();
    final taiLieu = await container.read(taiLieuBaiHocProvider.future);

    final khoaHoc = DuLieuMau.khoaHoc();
    expect(khoaHoc, hasLength(3));
    expect(khoaHoc.every((khoa) => khoa.mienPhi), isTrue);
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
}
