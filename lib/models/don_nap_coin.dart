/// Gói nạp Coin từ MetaMask.
class GoiNapCoin {
  final String id;
  final int coinAmount;
  final String ethAmount;
  final String name;

  const GoiNapCoin({
    required this.id,
    required this.coinAmount,
    required this.ethAmount,
    required this.name,
  });

  factory GoiNapCoin.tuMap(Map<String, dynamic> m) => GoiNapCoin(
    id: m['id'] as String? ?? '',
    coinAmount: (m['coinAmount'] as num?)?.toInt() ?? 0,
    ethAmount: m['ethAmount'] as String? ?? '0',
    name: m['name'] as String? ?? '',
  );

  Map<String, dynamic> sangMap() => {
    'id': id,
    'coinAmount': coinAmount,
    'ethAmount': ethAmount,
    'name': name,
  };
}

/// Đơn nạp Coin trên hệ thống.
class DonNapCoin {
  final String orderId;
  final String email;
  final String? walletAddress;
  final String packageId;
  final String ethAmount;
  final int coinAmount;
  final String? transactionHash;
  final String status;
  final String createdAt;
  final String? confirmedAt;
  bool get dangXacNhan => status == 'submitted' || status == 'confirming';
  bool get daXong => status == 'completed';
  bool get coTheKy => !daXong && !dangXacNhan;
  String get moTaTrangThai => switch (status) {
    'completed' => 'Đã nạp $coinAmount Coin vào ứng dụng.',
    'submitted' || 'confirming' => 'Đã gửi giao dịch. Đang chờ xác nhận.',
    'rejected' => 'Bạn đã từ chối thanh toán. Có thể thử lại.',
    'failed' => 'Giao dịch chưa thành công. Kiểm tra ví rồi thử lại.',
    _ => 'Đang chờ xác nhận trong MetaMask.',
  };

  const DonNapCoin({
    required this.orderId,
    required this.email,
    this.walletAddress,
    required this.packageId,
    required this.ethAmount,
    required this.coinAmount,
    this.transactionHash,
    this.status = 'pending',
    required this.createdAt,
    this.confirmedAt,
  });

  factory DonNapCoin.tuMap(Map<String, dynamic> m) => DonNapCoin(
    orderId: m['orderId'] as String? ?? '',
    email: m['email'] as String? ?? '',
    walletAddress: m['walletAddress'] as String?,
    packageId: m['packageId'] as String? ?? '',
    ethAmount: m['ethAmount'] as String? ?? '0',
    coinAmount: (m['coinAmount'] as num?)?.toInt() ?? 0,
    transactionHash: m['transactionHash'] as String?,
    status: m['status'] as String? ?? 'pending',
    createdAt: m['createdAt'] as String? ?? '',
    confirmedAt: m['confirmedAt'] as String?,
  );
}
