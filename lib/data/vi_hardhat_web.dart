import 'dart:js_interop';

import 'kho_du_lieu.dart';

@JS('ethereum')
external _Vi? get _ethereum;

extension type _Vi(JSObject _) implements JSObject {
  external JSPromise<JSAny?> request(JSObject request);
}

const _chainId = '0x7a69';

Future<Object?> _gui(String method, [List<Object?> params = const []]) async {
  final vi = _ethereum;
  if (vi == null) {
    throw const LoiTaiKhoan('Mở ứng dụng trong trình duyệt đã cài MetaMask.');
  }
  final yeuCau = {'method': method, 'params': params}.jsify() as JSObject;
  return (await vi.request(yeuCau).toDart).dartify();
}

Future<String> ketNoiVi() async {
  if (await _gui('eth_chainId') != _chainId) {
    await _gui('wallet_addEthereumChain', [
      {
        'chainId': _chainId,
        'chainName': 'Hardhat Local',
        'rpcUrls': ['http://127.0.0.1:8545'],
        'nativeCurrency': {
          'name': 'Test Ether',
          'symbol': 'ETH',
          'decimals': 18,
        },
      },
    ]);
    if (await _gui('eth_chainId') != _chainId) {
      await _gui('wallet_switchEthereumChain', [
        {'chainId': _chainId},
      ]);
    }
  }
  if (await _gui('eth_chainId') != _chainId) {
    throw const LoiTaiKhoan('Chọn đúng mạng Hardhat 31337 trong MetaMask.');
  }
  final vi = await _gui('eth_requestAccounts');
  if (vi is! List || vi.isEmpty || vi.first is! String) {
    throw const LoiTaiKhoan('Bạn chưa chọn tài khoản MetaMask.');
  }
  return vi.first as String;
}

Future<String> guiGiaoDichDoiPro(String vi, String payload) async {
  if (await _gui('eth_chainId') != _chainId) {
    throw const LoiTaiKhoan('Chọn đúng mạng Hardhat 31337 trong MetaMask.');
  }
  return await _gui('eth_sendTransaction', [
    {
      'from': vi,
      'to': vi,
      'data': payload,
      'value': '0x0',
      'chainId': _chainId,
    },
  ]) as String;
}
