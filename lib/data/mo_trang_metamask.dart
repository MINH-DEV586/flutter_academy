import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

bool get dungMetaMaskMobile =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<String?> moTrangMetaMask(Uri trang) async {
  if (dungMetaMaskMobile) {
    await Clipboard.setData(ClipboardData(text: trang.toString()));
    if (trang.scheme == 'https') {
      final lienKet = Uri.parse(
        'https://link.metamask.io/dapp/${trang.authority}${trang.path}#${trang.fragment}',
      );
      if (await launchUrl(lienKet, mode: LaunchMode.externalApplication)) {
        return null;
      }
    }
    const kenh = MethodChannel('vn.flutteracademy/metamask');
    if (await kenh.invokeMethod<bool>('open') != true) {
      return 'Chưa tìm thấy MetaMask trên điện thoại.';
    }
    return 'Đã sao chép đường dẫn. Dán vào trình duyệt trong MetaMask nếu trang ký chưa mở.';
  }
  if (!await launchUrl(trang, mode: LaunchMode.externalApplication)) {
    return 'Chưa mở được trang ký MetaMask. Hãy thử mở lại.';
  }
  return null;
}
