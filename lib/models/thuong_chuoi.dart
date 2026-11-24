class MocCoinThuong {
  const MocCoinThuong(this.ngay, this.coin, {this.trangThai});
  final int ngay;
  final int coin;
  final String? trangThai;
}

class NhanCoinThuong {
  NhanCoinThuong.tuJson(Map<String, dynamic> json)
    : mocNgay = json['milestone'] as int,
      coin = json['amount'] as int,
      trangThai = json['status'] as String,
      thoiDiem = json['earnedAt'] as String?;

  final int mocNgay;
  final int coin;
  final String trangThai;
  final String? thoiDiem;
}

class TrangThaiThuongChuoi {
  TrangThaiThuongChuoi.tuJson(Map<String, dynamic> json)
    : soNgay = json['days'] as int,
      moc = [
        for (final muc in json['milestones'] as List)
          MocCoinThuong(
            muc['day'] as int,
            muc['amount'] as int,
            trangThai: muc['status'] as String?,
          ),
      ],
      lichSu = [
        for (final muc in json['awards'] as List)
          NhanCoinThuong.tuJson(muc as Map<String, dynamic>),
      ],
      coinDangCho =
          (json['pendingCoin'] as int?) ??
          (json['awards'] as List)
              .where((muc) => muc['status'] != 'issued')
              .fold(0, (tong, muc) => tong + (muc['amount'] as int)),
      blockchain = json['onChain'] != null,
      diaChiVi = json['onChain']?['wallet'] as String?,
      daKetNoiVi =
          (json['onChain']?['connected'] as bool?) ??
          (json['onChain']?['wallet'] != null),
      chainId = json['onChain']?['chainId'] as int?,
      soDu = json['onChain']?['balance'] as int?,
      giaDoiPro = json['onChain']?['proOffer']?['amount'] as int?,
      soNgayPro = json['onChain']?['proOffer']?['days'] as int?,
      loiMang = json['onChain']?['chainError'] as String?,
      dangLienKet = json['onChain']?['linkStatus'] as String?,
      doiPro = json['onChain']?['redemption']?['status'] as String?,
      txHash = json['onChain']?['redemption']?['txHash'] as String?,
      hanPro = DateTime.tryParse(
        json['onChain']?['redemption']?['expiresAt'] as String? ?? '',
      );

  final int soNgay;
  final List<MocCoinThuong> moc;
  final List<NhanCoinThuong> lichSu;
  final int coinDangCho;
  final bool blockchain;
  final String? diaChiVi;
  final bool daKetNoiVi;
  final int? chainId;
  final int? soDu;
  final int? giaDoiPro;
  final int? soNgayPro;
  final String? loiMang;
  final String? dangLienKet;
  final String? doiPro;
  final String? txHash;
  final DateTime? hanPro;

  MocCoinThuong? get mocTiepTheo =>
      moc.where((muc) => muc.ngay > soNgay).firstOrNull;
}
