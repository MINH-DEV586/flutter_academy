import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dinh_tuyen/bo_dinh_tuyen.dart';
import '../viewmodels/phien_vm.dart';
import '../viewmodels/providers.dart';
import '../widgets/trang.dart';

/// Màn hình đăng nhập.
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
  final _oMatKhau = TextEditingController();

  bool _dangKy = false;
  bool _hienMatKhau = false;
  bool _dangGui = false;
  String? _loiChung;

  @override
  void dispose() {
    _oEmail.dispose();
    _oTen.dispose();
    _oMatKhau.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (_dangGui) return;
    setState(() => _loiChung = null);
    if (!(_khoaForm.currentState?.validate() ?? false)) return;

    setState(() => _dangGui = true);
    final loi = await ref
        .read(phienProvider.notifier)
        .dangNhap(
          email: _oEmail.text,
          hoTen: _dangKy ? _oTen.text : null,
          matKhau: _oMatKhau.text,
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
                      Text(
                        _dangKy ? 'Tạo tài khoản' : 'Đăng nhập',
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const SizedBox(height: 24),
                      if (_dangKy) ...[
                        TextFormField(
                          controller: _oTen,
                          readOnly: _dangGui,
                          maxLength: 80,
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
                      ],
                      TextFormField(
                        controller: _oEmail,
                        readOnly: _dangGui,
                        maxLength: 254,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oMatKhau,
                        readOnly: _dangGui,
                        obscureText: !_hienMatKhau,
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLength: 128,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _dangKy
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hienMatKhau
                                ? 'Ẩn mật khẩu'
                                : 'Hiện mật khẩu',
                            onPressed: () =>
                                setState(() => _hienMatKhau = !_hienMatKhau),
                            icon: Icon(
                              _hienMatKhau
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (giaTri) {
                          final matKhau = giaTri ?? '';
                          if (matKhau.isEmpty) return 'Nhập mật khẩu.';
                          if (_dangKy && matKhau.length < 12) {
                            return 'Mật khẩu phải có ít nhất 12 ký tự.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _gui(),
                      ),
                      if (_loiChung != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _loiChung!,
                          style: TextStyle(color: mau.error, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _dangGui ? null : _gui,
                        child: _dangGui
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_dangKy ? 'Tạo tài khoản' : 'Đăng nhập'),
                      ),
                      TextButton(
                        onPressed: _dangGui
                            ? null
                            : () => setState(() {
                                _dangKy = !_dangKy;
                                _loiChung = null;
                                _hienMatKhau = false;
                                _khoaForm.currentState?.reset();
                                _oMatKhau.clear();
                              }),
                        child: Text(
                          _dangKy
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
                        ),
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
