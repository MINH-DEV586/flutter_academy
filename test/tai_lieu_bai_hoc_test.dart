import 'package:flutter_academy/data/du_lieu_mau.dart';
import 'package:flutter_academy/data/tai_lieu_bai_hoc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tài liệu AI gắn với bài thật và có code riêng cho từng bài', () async {
    final container = ProviderContainer.test();
    final taiLieu = await container.read(taiLieuBaiHocProvider.future);

    expect(taiLieu.keys, [
      'dieu-huong-url/b1',
      'dieu-huong-url/b2',
      'dieu-huong-url/b3',
    ]);
    final cacBai = {
      for (final khoa in DuLieuMau.khoaHoc())
        for (final bai in khoa.baiHoc) '${khoa.ma}/${bai.ma}',
    };
    expect(cacBai, containsAll(taiLieu.keys));
    expect(taiLieu['dieu-huong-url/b1']?.youtubeId, 'b6Z885Z46cU');
    expect(taiLieu['dieu-huong-url/b2']?.code, contains('queryParameters'));
    expect(taiLieu['dieu-huong-url/b3']?.code, contains('ShellRoute'));
  });
}
