class MayChu {
  MayChu._();

  static const goc = String.fromEnvironment(
    'ACADEMY_API_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );
  static const _taiKhoanCu = String.fromEnvironment('ACCOUNT_API_URL');
  static const _tutorCu = String.fromEnvironment('AI_TUTOR_URL');

  static String get api {
    if (_taiKhoanCu.endsWith('/api/account')) {
      return _taiKhoanCu.substring(0, _taiKhoanCu.length - '/account'.length);
    }
    return _taiKhoanCu.isEmpty ? '$goc/api' : _taiKhoanCu;
  }

  static String get taiKhoan => '$api/account';
  static Uri get tutor =>
      Uri.parse(_tutorCu.isEmpty ? '$api/ai-tutor' : _tutorCu);
}
