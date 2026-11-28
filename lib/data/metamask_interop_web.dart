import 'dart:js_interop';

@JS('FlutterMetaMask')
external _FlutterMetaMask get _metaMask;

@JS()
extension type _FlutterMetaMask(JSObject _) implements JSObject {
  external bool isInstalled();
  external JSPromise<JSString?> requestAccounts();
  external JSPromise<JSString?> getAccount();
  external JSPromise<JSString> getChainId();
  external JSPromise<JSBoolean> isSepolia();
  external JSPromise<JSBoolean> switchToSepolia();
  external JSPromise<JSString?> sendDeposit(
    JSString contractAddress,
    JSString orderId,
    JSNumber packageId,
    JSString ethAmount,
    JSString chainId,
    JSString walletAddress,
  );
  external JSPromise<JSString> getBalance(JSString address);
  external void onAccountsChanged(JSFunction callback);
  external void onChainChanged(JSFunction callback);
  external void watchConnection(JSFunction callback);
  external void unwatchConnection(JSFunction callback);
  external JSNumber getContractPackageId(JSString flutterPkgId);
}

class MetaMaskService {
  static bool get isInstalled {
    try {
      return _metaMask.isInstalled();
    } catch (_) {
      return false;
    }
  }

  static Future<String?> requestAccounts() async {
    try {
      final res = await _metaMask.requestAccounts().toDart;
      return res?.toDart;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccount() async {
    try {
      final res = await _metaMask.getAccount().toDart;
      return res?.toDart;
    } catch (_) {
      return null;
    }
  }

  static Future<String> getChainId() async {
    try {
      final res = await _metaMask.getChainId().toDart;
      return res.toDart;
    } catch (_) {
      return '';
    }
  }

  static Future<bool> isSepolia() async {
    try {
      final res = await _metaMask.isSepolia().toDart;
      return res.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> switchToSepolia() async {
    try {
      final res = await _metaMask.switchToSepolia().toDart;
      return res.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> sendDeposit({
    required String contractAddress,
    required String orderId,
    required int packageId,
    required String ethAmount,
    required int chainId,
    required String walletAddress,
  }) async {
    try {
      final res = await _metaMask
          .sendDeposit(
            contractAddress.toJS,
            orderId.toJS,
            packageId.toJS,
            ethAmount.toJS,
            '0x${chainId.toRadixString(16)}'.toJS,
            walletAddress.toJS,
          )
          .toDart;
      return res?.toDart;
    } catch (_) {
      return null;
    }
  }

  static void Function() quanSatKetNoi(void Function() callback) {
    final handler = ((JSAny? _) => callback()).toJS;
    try {
      _metaMask.watchConnection(handler);
      return () => _metaMask.unwatchConnection(handler);
    } catch (_) {
      return () {};
    }
  }

  static Future<String> getBalance(String address) async {
    try {
      final res = await _metaMask.getBalance(address.toJS).toDart;
      return res.toDart;
    } catch (_) {
      return '0';
    }
  }

  static void onAccountsChanged(void Function(String?) callback) {
    try {
      _metaMask.onAccountsChanged(
        ((JSString? addr) {
          callback(addr?.toDart);
        }).toJS,
      );
    } catch (_) {}
  }

  static void onChainChanged(void Function(String) callback) {
    try {
      _metaMask.onChainChanged(
        ((JSString chainId) {
          callback(chainId.toDart);
        }).toJS,
      );
    } catch (_) {}
  }

  static int getContractPackageId(String flutterPkgId) {
    try {
      return _metaMask.getContractPackageId(flutterPkgId.toJS).toDartInt;
    } catch (_) {
      return 0;
    }
  }
}
