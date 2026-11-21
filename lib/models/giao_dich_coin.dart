/// Các loại giao dịch Coin.
enum LoaiGiaoDich {
  reward('REWARD', 'Nhận thưởng', '🎁'),
  deposit('DEPOSIT', 'Nạp Coin', '💎'),
  purchasePro('PURCHASE_PRO', 'Đổi gói Pro', '⭐'),
  refund('REFUND', 'Hoàn Coin', '↩️'),
  adjustment('ADMIN_ADJUSTMENT', 'Điều chỉnh', '⚙️');

  final String ma;
  final String ten;
  final String bieuTuong;

  const LoaiGiaoDich(this.ma, this.ten, this.bieuTuong);

  static LoaiGiaoDich tuMa(String ma) {
    for (final v in values) {
      if (v.ma == ma) return v;
    }
    return LoaiGiaoDich.reward;
  }
}

/// Bản ghi lịch sử giao dịch Coin.
class GiaoDichCoin {
  final String id;
  final LoaiGiaoDich type;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String status;
  final String? description;
  final String? referenceId;
  final String? transactionHash;
  final String createdAt;

  const GiaoDichCoin({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.status = 'completed',
    this.description,
    this.referenceId,
    this.transactionHash,
    required this.createdAt,
  });

  bool get laCongCoin => amount > 0;

  String get soCoinHienThi =>
      laCongCoin ? '+$amount' : '$amount';

  String get txHashRutGon {
    if (transactionHash == null || transactionHash!.isEmpty) return '';
    final h = transactionHash!;
    if (h.length <= 12) return h;
    return '${h.substring(0, 6)}...${h.substring(h.length - 4)}';
  }

  factory GiaoDichCoin.tuMap(Map<String, dynamic> m) => GiaoDichCoin(
        id: m['id'] as String? ?? '',
        type: LoaiGiaoDich.tuMa(m['type'] as String? ?? ''),
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        balanceBefore: (m['balanceBefore'] as num?)?.toInt() ?? 0,
        balanceAfter: (m['balanceAfter'] as num?)?.toInt() ?? 0,
        status: m['status'] as String? ?? 'completed',
        description: m['description'] as String?,
        referenceId: m['referenceId'] as String?,
        transactionHash: m['transactionHash'] as String?,
        createdAt: m['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> sangMap() => {
        'id': id,
        'type': type.ma,
        'amount': amount,
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
        'status': status,
        'description': description,
        'referenceId': referenceId,
        'transactionHash': transactionHash,
        'createdAt': createdAt,
      };
}
