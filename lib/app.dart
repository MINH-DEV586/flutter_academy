import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cau_hinh/mau_sac.dart';
import 'models/che_do_giao_dien.dart';
import 'dinh_tuyen/bo_dinh_tuyen.dart';
import 'viewmodels/providers.dart';

/// Gốc của ứng dụng.
///
/// `MaterialApp.router` chứ không `MaterialApp`: điều hướng khai báo cần
/// `routerConfig`, và chỉ có dạng `.router` mới đồng bộ được với thanh địa
/// chỉ của trình duyệt.
class UngDung extends ConsumerWidget {
  const UngDung({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `watch` chứ không `read`: nếu sau này router phụ thuộc vào thứ gì đổi
    // được thì giao diện cũng phải dựng lại theo.
    final router = ref.watch(boDinhTuyenProvider);

    return MaterialApp.router(
      title: 'Flutter Academy',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ChuDe.sang(),
      darkTheme: ChuDe.toi(),
      themeMode: _sangThemeMode(ref.watch(chuDeProvider)),
    );
  }
}

/// Quy đổi enum của tầng ViewModel sang kiểu của Flutter.
///
/// Ba dòng này là toàn bộ cái giá phải trả để `viewmodels/` không phải import
/// `material.dart`. Đổi lại, luật phân tầng kiểm tra được chỉ bằng mắt.
ThemeMode _sangThemeMode(CheDoGiaoDien c) => switch (c) {
      CheDoGiaoDien.theoHeThong => ThemeMode.system,
      CheDoGiaoDien.sang => ThemeMode.light,
      CheDoGiaoDien.toi => ThemeMode.dark,
    };
