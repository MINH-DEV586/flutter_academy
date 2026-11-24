import 'dart:convert';
import 'dart:io';

import 'package:flutter_academy/data/kho_gia_su_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  test(
    'khôi phục bản ghi hợp lệ và bỏ qua bản ghi lỗi theo tài khoản và bài',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'flutter-academy-tutor-',
      );
      Hive.init(temp.path);
      try {
        final chat = await Hive.openBox<String>('chat');
        final phien = await Hive.openBox<String>('phien');
        final kho = HttpKhoGiaSuAi(chat, phien);
        const email = 'alice@example.test';
        const bai = 'flutter/b1';
        await chat.put(
          jsonEncode([email, bai]),
          jsonEncode([
            {'cauHoi': 5},
            {
              'cauHoi': 'Giải thích đoạn này',
              'mucDo': 'coBan',
              'traLoi': 'Phần đã nhận',
            },
            {
              'cauHoi': 'Quiz đã hỏng',
              'mucDo': 'coBan',
              'quiz': {
                'luaChon': ['a'],
                'dung': 3,
              },
            },
          ]),
        );
        final lichSu = kho.doc((email: email, bai: bai));
        expect(lichSu.single.traLoi, 'Phần đã nhận');
        expect(kho.doc((email: 'bob@example.test', bai: bai)), isEmpty);
        expect(kho.doc((email: email, bai: 'flutter/b2')), isEmpty);
      } finally {
        await Hive.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
