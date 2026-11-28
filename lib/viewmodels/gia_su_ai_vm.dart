import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kho_gia_su_ai.dart';
import '../models/gia_su_ai.dart';

final khoGiaSuAiProvider = Provider<KhoGiaSuAi>(
  (ref) => throw UnimplementedError('Chưa ghi đè khoGiaSuAiProvider'),
);

final giaSuAiProvider = NotifierProvider.autoDispose
    .family<GiaSuAiVM, TrangThaiTutor, HoiThoaiTutor>(GiaSuAiVM.new);

class TrangThaiTutor {
  const TrangThaiTutor(this.lichSu, {this.dangTraLoi = false, this.loi});

  final List<LuotHoiTutor> lichSu;
  final bool dangTraLoi;
  final LoiTutor? loi;
}

class GiaSuAiVM extends Notifier<TrangThaiTutor> {
  GiaSuAiVM(this.khoa);

  final HoiThoaiTutor khoa;
  StreamSubscription<Map<String, dynamic>>? _stream;
  Completer<void>? _huy;
  Timer? _henLuu;
  List<LuotHoiTutor>? _choLuu;

  @override
  TrangThaiTutor build() {
    final kho = ref.watch(khoGiaSuAiProvider);
    ref.onDispose(() {
      _henLuu?.cancel();
      final lichSu = _choLuu;
      if (lichSu != null) _luu(kho, lichSu);
      _huy?.complete();
      _huy = null;
      unawaited(_stream?.cancel());
    });
    return TrangThaiTutor(kho.doc(khoa));
  }

  void hoi(String cauHoi, String mucDo, {int? thayLuot}) {
    final cau = cauHoi.trim();
    if (state.dangTraLoi ||
        cau.isEmpty ||
        cau.runes.length > KhoGiaSuAi.gioiHanCauHoi) {
      return;
    }

    final kho = ref.read(khoGiaSuAiProvider);
    final lichSu = [...state.lichSu];
    final cu = thayLuot == null ? null : lichSu.removeAt(thayLuot);
    lichSu.add(
      LuotHoiTutor({
        'cauHoi': cau,
        'mucDo': mucDo,
        'traLoi': cu?.traLoi ?? '',
        'demo': cu?.demo ?? false,
      }),
    );
    if (lichSu.length > 50) lichSu.removeAt(0);
    state = TrangThaiTutor(lichSu, dangTraLoi: true);
    _luu(kho, lichSu);
    final huy = _huy = Completer<void>();
    var coPhanMoi = false;

    void ketThuc([Object? loi]) {
      if (!ref.mounted || _huy != huy) return;
      _huy = null;
      huy.complete();
      unawaited(_stream?.cancel());
      _stream = null;
      _henLuu?.cancel();
      state = TrangThaiTutor(
        state.lichSu,
        loi: loi == null
            ? null
            : loi is LoiTutor
            ? loi
            : const LoiTutor('Kết nối Gia sư AI bị gián đoạn. Hãy thử lại.'),
      );
      _luu(kho, state.lichSu);
    }

    void capNhat(Map<String, dynamic> moi) {
      final cacLuot = [...state.lichSu];
      cacLuot[cacLuot.length - 1] = cacLuot.last.capNhat(moi);
      state = TrangThaiTutor(cacLuot, dangTraLoi: true);
      _choLuu = cacLuot;
      if (!(_henLuu?.isActive ?? false)) {
        _henLuu = Timer(
          const Duration(milliseconds: 300),
          () => _luu(kho, state.lichSu),
        );
      }
    }

    _stream = kho
        .hoi(khoa: khoa, cauHoi: cau, mucDo: mucDo, khiHuy: huy.future)
        .listen(
          (muc) {
            if (!ref.mounted || _huy != huy) return;
            try {
              switch (muc['loai']) {
                case 'batDau':
                  capNhat({'demo': muc['demo'] == true});
                case 'phan':
                  final cu = coPhanMoi ? state.lichSu.last.traLoi : '';
                  coPhanMoi = true;
                  capNhat({'traLoi': cu + (muc['text'] as String)});
                case 'xong':
                  capNhat({
                    'hoanTat': true,
                    'nguon': muc['nguon'],
                    'quiz': muc['quiz'],
                  });
                  ketThuc();
                case 'loi':
                  ketThuc(LoiTutor(muc['loi'] as String));
              }
            } on TypeError catch (loi) {
              ketThuc(loi);
            } on FormatException catch (loi) {
              ketThuc(loi);
            }
          },
          onError: ketThuc,
          onDone: () => ketThuc(
            const LoiTutor('Câu trả lời chưa hoàn tất. Hãy thử lại.'),
          ),
        );
  }

  void chonDapAn(int luot, int dapAn) {
    final lichSu = [...state.lichSu];
    lichSu[luot] = lichSu[luot].capNhat({'daChon': dapAn});
    state = TrangThaiTutor(
      lichSu,
      dangTraLoi: state.dangTraLoi,
      loi: state.loi,
    );
    _luu(ref.read(khoGiaSuAiProvider), lichSu);
  }

  void _luu(KhoGiaSuAi kho, List<LuotHoiTutor> lichSu) {
    _choLuu = null;
    unawaited(
      kho.luu(khoa, lichSu).catchError((Object _) {
        if (ref.mounted && !state.dangTraLoi && state.loi == null) {
          state = TrangThaiTutor(
            state.lichSu,
            loi: const LoiTutor('Chưa lưu được lịch sử trên thiết bị.'),
          );
        }
      }),
    );
  }
}
