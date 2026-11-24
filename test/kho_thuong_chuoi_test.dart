import 'dart:convert';
import 'dart:io';

import 'package:flutter_academy/data/kho_thuong_chuoi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'giữ sự kiện khi lỗi tạm thời rồi bỏ sự kiện lỗi vĩnh viễn để gửi bài sau',
    () async {
      final temp = await Directory.systemTemp.createTemp('thuong-chuoi-');
      Hive.init(temp.path);
      try {
        final cho = await Hive.openBox<String>('cho');
        final phien = await Hive.openBox<String>('phien');
        await phien.put('token', 'token-test');
        var tamLoi = true;
        final gui = <String>[];
        final maDaGui = <String>[];
        final kho = HttpKhoThuongChuoi(
          cho,
          phien,
          taoClient: () => MockClient((req) async {
            final suKien = jsonDecode(req.body) as Map;
            final bai = suKien['lesson'] as String;
            gui.add(bai);
            maDaGui.add(suKien['eventId'] as String);
            if (tamLoi) return http.Response('{}', 503);
            if (bai == 'bai-cu') {
              return http.Response('{"code":"INVALID_COMPLETION"}', 400);
            }
            return http.Response('{}', 200);
          }),
        );
        const email = 'demo@example.test';
        const idCu = 'ma-su-kien-tu-ban-truoc';
        await cho.put('$email|$idCu', 'bai-truoc-cap-nhat');
        await kho.ghiNhan(email, 'bai-cu');
        await kho.ghiNhan(email, 'bai-moi');
        await expectLater(kho.dongBo(email), throwsA(isA<LoiThuongChuoi>()));
        expect(kho.soDangCho(email), 3);
        tamLoi = false;
        await kho.dongBo(email);
        expect(gui, [
          'bai-truoc-cap-nhat',
          'bai-truoc-cap-nhat',
          'bai-cu',
          'bai-moi',
        ]);
        expect(maDaGui.take(2), [idCu, idCu]);
        expect(kho.soDangCho(email), 0);
      } finally {
        await Hive.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
