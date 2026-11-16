import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaiLieuBaiHoc {
  const TaiLieuBaiHoc({
    required this.noiDung,
    required this.code,
    this.youtubeId,
    this.kenhYouTube,
  });

  final String noiDung;
  final String code;
  final String? youtubeId;
  final String? kenhYouTube;

  factory TaiLieuBaiHoc.tuJson(Map<String, dynamic> json) => TaiLieuBaiHoc(
    noiDung: json['noiDung'] as String,
    code: json['code'] as String,
    youtubeId: json['youtubeId'] as String?,
    kenhYouTube: json['kenhYouTube'] as String?,
  );
}

final taiLieuBaiHocProvider = FutureProvider<Map<String, TaiLieuBaiHoc>>((
  ref,
) async {
  final nguon = await rootBundle.loadString('assets/bai_hoc_ai.json');
  final json = jsonDecode(nguon) as Map<String, dynamic>;
  return json.map(
    (ma, taiLieu) =>
        MapEntry(ma, TaiLieuBaiHoc.tuJson(taiLieu as Map<String, dynamic>)),
  );
});
