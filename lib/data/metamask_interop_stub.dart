/// Stub cho nền tảng không phải Web (VM / Unit Test).
class MetaMaskService {
  static bool get isInstalled => false;

  static Future<String?> requestAccounts() async => null;

  static Future<String?> getAccount() async => null;

  static Future<String> getChainId() async => '';

  static Future<bool> isSepolia() async => false;

  static Future<bool> switchToSepolia() async => false;

  static Future<String?> sendDeposit({
    required String contractAddress,
    required String orderId,
    required int packageId,
    required String ethAmount,
    required int chainId,
    required String walletAddress,
  }) async => null;

  static Future<String> getBalance(String address) async => '0';

  static void Function() quanSatKetNoi(void Function() callback) => () {};

  static void onAccountsChanged(void Function(String?) callback) {}

  static void onChainChanged(void Function(String) callback) {}

  static int getContractPackageId(String flutterPkgId) => 0;
}
