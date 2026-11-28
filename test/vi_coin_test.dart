import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_academy/models/don_nap_coin.dart';
import 'package:flutter_academy/models/giao_dich_coin.dart';
import 'package:flutter_academy/models/goi_pro.dart';
import 'package:flutter_academy/models/vi_coin.dart';
import 'package:flutter_academy/data/metamask_interop.dart';

void main() {
  group('ViCoin Model', () {
    test('Khởi tạo mặc định và tính toán địa chỉ rút gọn', () {
      const vi = ViCoin(
        email: 'user@example.com',
        coinBalance: 250,
        metamaskAddress: '0x1234567890abcdef1234567890abcdef12345678',
      );

      expect(vi.coinBalance, 250);
      expect(vi.daLienKetVi, isTrue);
      expect(vi.diaChiRutGon, '0x1234...5678');
    });

    test('Ví chưa liên kết MetaMask', () {
      const viChuaLienKet = ViCoin(email: 'user2@example.com');
      expect(viChuaLienKet.daLienKetVi, isFalse);
      expect(viChuaLienKet.diaChiRutGon, 'Chưa liên kết');
    });

    test('Chuyển đổi sang Map và từ Map', () {
      final m = {
        'email': 'test@test.com',
        'coinBalance': 500,
        'metamaskAddress': '0xABCDEF1234567890ABCDEF1234567890ABCDEF12',
        'createdAt': '2026-11-20T12:00:00Z',
      };
      final vi = ViCoin.tuMap(m);
      expect(vi.email, 'test@test.com');
      expect(vi.coinBalance, 500);
      expect(vi.sangMap()['coinBalance'], 500);
    });
  });

  group('GiaoDichCoin Model', () {
    test('Đúng định dạng hiển thị cộng/trừ Coin và txHash rút gọn', () {
      const gdThuong = GiaoDichCoin(
        id: 'tx_1',
        type: LoaiGiaoDich.reward,
        amount: 20,
        balanceBefore: 10,
        balanceAfter: 30,
        createdAt: '2026-11-20',
      );
      expect(gdThuong.laCongCoin, isTrue);
      expect(gdThuong.soCoinHienThi, '+20');

      const gdMuaPro = GiaoDichCoin(
        id: 'tx_2',
        type: LoaiGiaoDich.purchasePro,
        amount: -100,
        balanceBefore: 100,
        balanceAfter: 0,
        createdAt: '2026-11-20',
      );
      expect(gdMuaPro.laCongCoin, isFalse);
      expect(gdMuaPro.soCoinHienThi, '-100');

      const gdNap = GiaoDichCoin(
        id: 'tx_3',
        type: LoaiGiaoDich.deposit,
        amount: 50,
        balanceBefore: 0,
        balanceAfter: 50,
        transactionHash:
            '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        createdAt: '2026-11-20',
      );
      expect(gdNap.txHashRutGon, '0xabcd...7890');
    });
  });

  group('GoiPro & TrangThaiThanhVien', () {
    test('Kiểm tra quyền và số ngày còn lại của gói Pro', () {
      final tuongLai = DateTime.now().add(const Duration(days: 25));
      final tv = TrangThaiThanhVien(
        isPro: true,
        packageId: 'pro_30',
        expiresAt: tuongLai,
      );

      expect(tv.isPro, isTrue);
      expect(tv.daHetHan, isFalse);
      expect(tv.soNgayConLai, greaterThanOrEqualTo(24));
    });

    test('Xử lý gói Pro đã hết hạn', () {
      final quaKhu = DateTime.now().subtract(const Duration(days: 2));
      final tvHetHan = TrangThaiThanhVien(
        isPro: true,
        packageId: 'pro_30',
        expiresAt: quaKhu,
      );

      expect(tvHetHan.daHetHan, isTrue);
      expect(tvHetHan.soNgayConLai, 0);
    });
  });

  group('DonNapCoin & MetaMask stub', () {
    test('MetaMaskService an toàn trên môi trường VM/Test', () async {
      expect(MetaMaskService.isInstalled, isFalse);
      expect(await MetaMaskService.getAccount(), isNull);
      expect(await MetaMaskService.isSepolia(), isFalse);
    });

    test('Chuyển đổi DonNapCoin và GoiNapCoin', () {
      const goi = GoiNapCoin(
        id: 'pkg_100',
        coinAmount: 100,
        ethAmount: '0.01',
        name: '100 Coin',
      );
      expect(goi.coinAmount, 100);
      expect(goi.ethAmount, '0.01');

      const don = DonNapCoin(
        orderId: '0x1111',
        email: 'test@example.com',
        packageId: 'pkg_100',
        ethAmount: '0.01',
        coinAmount: 100,
        createdAt: '2026-11-20',
      );
      expect(don.status, 'pending');
      expect(don.coinAmount, 100);
    });
  });
}
