/// Thông tin Ví Coin nội bộ của người học.
class ViCoin {
  final String email;
  final int coinBalance;
  final String? metamaskAddress;
  final String? createdAt;

  const ViCoin({
    required this.email,
    this.coinBalance = 0,
    this.metamaskAddress,
    this.createdAt,
  });

  bool get daLienKetVi =>
      metamaskAddress != null && metamaskAddress!.isNotEmpty;

  String get diaChiRutGon {
    if (!daLienKetVi) return 'Chưa liên kết';
    final addr = metamaskAddress!;
    if (addr.length <= 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  factory ViCoin.tuMap(Map<String, dynamic> m) => ViCoin(
        email: m['email'] as String? ?? '',
        coinBalance: (m['coinBalance'] as num?)?.toInt() ?? 0,
        metamaskAddress: m['metamaskAddress'] as String?,
        createdAt: m['createdAt'] as String?,
      );

  Map<String, dynamic> sangMap() => {
        'email': email,
        'coinBalance': coinBalance,
        'metamaskAddress': metamaskAddress,
        'createdAt': createdAt,
      };

  ViCoin copyWith({
    String? email,
    int? coinBalance,
    String? metamaskAddress,
    String? createdAt,
  }) =>
      ViCoin(
        email: email ?? this.email,
        coinBalance: coinBalance ?? this.coinBalance,
        metamaskAddress: metamaskAddress ?? this.metamaskAddress,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViCoin &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          coinBalance == other.coinBalance &&
          metamaskAddress == other.metamaskAddress;

  @override
  int get hashCode => Object.hash(email, coinBalance, metamaskAddress);
}
