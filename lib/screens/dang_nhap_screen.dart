import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/bo_dinh_tuyen.dart';
import '../viewmodels/phien_vm.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';

/// Màn hình đăng nhập.
///
/// Không có mật khẩu và không có máy chủ — chỉ ghi hồ sơ xuống Hive. Phần
/// đáng học ở đây là **cách một biểu mẫu web hoạt động đúng**:
///
///   * `Form` + `GlobalKey<FormState>` để kiểm tra dữ liệu;
///   * `autovalidateMode` chỉ bật sau khi người dùng đã chạm vào ô, chứ
///     không tô đỏ ngay khi trang vừa mở;
///   * `autofillHints` để trình duyệt gợi ý điền sẵn;
///   * quay về đúng trang người dùng định vào (`?tiep=...`), và chỉ chấp
///     nhận đường dẫn nội bộ.
class DangNhapScreen extends ConsumerStatefulWidget {
  final String? diaChiTiep;

  const DangNhapScreen({super.key, this.diaChiTiep});

  @override
  ConsumerState<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends ConsumerState<DangNhapScreen> {
  final _khoaForm = GlobalKey<FormState>();
  final _oEmail = TextEditingController();
  final _oTen = TextEditingController();

  bool _dangGui = false;
  String? _loiChung;

  @override
  void dispose() {
    _oEmail.dispose();
    _oTen.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    setState(() => _loiChung = null);
    if (!(_khoaForm.currentState?.validate() ?? false)) return;

    setState(() => _dangGui = true);
    final loi = await ref.read(phienProvider.notifier).dangNhap(
          email: _oEmail.text,
          hoTen: _oTen.text,
        );

    // Người dùng có thể đã rời trang trong lúc chờ. Đụng vào `context` hay
    // `setState` sau khi widget bị huỷ là một trong những lỗi async hay gặp
    // nhất trong Flutter.
    if (!mounted) return;
    setState(() => _dangGui = false);

    if (loi != null) {
      setState(() => _loiChung = loi);
      return;
    }
    context.go(diaChiVeSauDangNhap(widget.diaChiTiep));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mau = Theme.of(context).colorScheme;

    return Trang(
      con: [
        const SizedBox(height: 32),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _khoaForm,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Đăng nhập',
                          style: t.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        'Hồ sơ chỉ được lưu trên máy này. Không có mật khẩu, '
                        'không có dữ liệu nào rời khỏi trình duyệt.',
                        style: t.bodySmall
                            ?.copyWith(color: mau.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _oTen,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Họ tên phải có ít nhất 2 ký tự.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        // Dùng lại đúng hàm mà ViewModel dùng, không viết
                        // lại luật ở hai nơi.
                        validator: (v) => hopLeEmail(v ?? '')
                            ? null
                            : 'Email chưa đúng định dạng.',
                        onFieldSubmitted: (_) => _gui(),
                      ),
                      if (_loiChung != null) ...[
                        const SizedBox(height: 16),
                        Text(_loiChung!,
                            style: TextStyle(color: mau.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _dangGui ? null : _gui,
                        child: _dangGui
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
