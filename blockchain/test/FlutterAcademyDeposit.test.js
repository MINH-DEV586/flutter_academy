const { expect } = require("chai");
const { once } = require('node:events');
const { mkdtemp, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { ethers, network } = require("hardhat");

describe("FlutterAcademyDeposit", function () {
  let contract;
  let owner, user1, user2;
  const orderId1 = ethers.encodeBytes32String("ORDER-001");
  const orderId2 = ethers.encodeBytes32String("ORDER-002");

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("FlutterAcademyDeposit");
    contract = await Factory.deploy();
    await contract.waitForDeployment();
  });

  it("Khởi tạo đúng owner và 5 gói nạp", async function () {
    expect(await contract.owner()).to.equal(owner.address);
    expect(await contract.packageCount()).to.equal(5n);

    const pkg1 = await contract.getPackage(1);
    expect(pkg1.coinAmount).to.equal(50n);
    expect(pkg1.ethPrice).to.equal(ethers.parseEther("0.005"));
    expect(pkg1.active).to.be.true;
  });

  it("Nạp Coin thành công và phát event Deposit", async function () {
    const pkg1Price = ethers.parseEther("0.005");

    const tx = await contract.connect(user1).deposit(orderId1, 1, { value: pkg1Price });
    const receipt = await tx.wait();
    const block = await receipt.getBlock();
    await expect(tx)
      .to.emit(contract, "Deposit")
      .withArgs(orderId1, user1.address, 1n, pkg1Price, 50n, block.timestamp);

    expect(await contract.isOrderUsed(orderId1)).to.be.true;
  });

  it("Hoàn trả ETH thừa khi gửi nhiều hơn giá gói", async function () {
    const pkg1Price = ethers.parseEther("0.005");
    const sendAmount = ethers.parseEther("0.01");

    const user1BalBefore = await ethers.provider.getBalance(user1.address);
    const tx = await contract.connect(user1).deposit(orderId1, 1, { value: sendAmount });
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed * receipt.gasPrice;

    const user1BalAfter = await ethers.provider.getBalance(user1.address);
    // Số tiền trừ đúng bằng giá gói + gas (phần thừa đã hoàn trả)
    expect(user1BalBefore - user1BalAfter).to.be.closeTo(pkg1Price + gasUsed, ethers.parseEther("0.0001"));
  });

  it("Chống sử dụng lại orderId (Replay attack)", async function () {
    const pkg1Price = ethers.parseEther("0.005");
    await contract.connect(user1).deposit(orderId1, 1, { value: pkg1Price });

    await expect(
      contract.connect(user2).deposit(orderId1, 1, { value: pkg1Price })
    ).to.be.revertedWith("orderId da duoc su dung");
  });

  it("Bị từ chối khi không gửi đủ ETH", async function () {
    const thieuTien = ethers.parseEther("0.001");
    await expect(
      contract.connect(user1).deposit(orderId1, 1, { value: thieuTien })
    ).to.be.revertedWith("Khong du ETH thanh toan");
  });

  it("Chủ sở hữu có thể rút ETH về ví", async function () {
    const pkg1Price = ethers.parseEther("0.005");
    await contract.connect(user1).deposit(orderId1, 1, { value: pkg1Price });

    const ownerBalBefore = await ethers.provider.getBalance(owner.address);
    const tx = await contract.connect(owner).withdraw();
    const receipt = await tx.wait();
    const gas = receipt.gasUsed * receipt.gasPrice;
    const ownerBalAfter = await ethers.provider.getBalance(owner.address);

    expect(ownerBalAfter + gas - ownerBalBefore).to.equal(pkg1Price);
  });

  it("Người không phải chủ sở hữu không thể rút ETH", async function () {
    await expect(
      contract.connect(user1).withdraw()
    ).to.be.revertedWith("Chi chu so huu moi co quyen");
  });

  it('giữ đơn nạp sau khi từ chối và đối soát một lần trên hợp đồng khi mất hash', async function () {
    this.timeout(30_000);
    const { taoMayChu } = await import('../../server/ai-tutor.mjs');
    const temp = await mkdtemp(join(tmpdir(), 'academy-deposit-'));
    let backend;
    let token;
    let chainSai = false;
    const goiRpcFetch = async (_, request) => {
      const { method, params } = JSON.parse(request.body);
      if (method === 'eth_chainId' && chainSai) return Response.json({ result: '0x1' });
      return Response.json({ result: await network.provider.send(method, params) });
    };
    const start = async () => {
      backend = taoMayChu({
        accountDb: join(temp, 'academy.sqlite'),
        cauHinhBlockchain: {
          chainId: 31337, contractAddress: await contract.getAddress(), requiredConfirmations: 1, goiRpcFetch,
        },
      }).listen(0, '127.0.0.1');
      await once(backend, 'listening');
    };
    const stop = () => new Promise((resolve) => backend.close(resolve));
    const goi = async (path, body, expected = 200) => {
      const response = await fetch(`http://127.0.0.1:${backend.address().port}${path}`, {
        method: body ? 'POST' : 'GET',
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body ? JSON.stringify(body) : undefined,
      });
      const data = await response.json();
      expect(response.status, JSON.stringify(data)).to.equal(expected);
      return data;
    };
    const batDau = (packageId, orderId) => goi('/api/wallet/deposits', { packageId, orderId, checkout: true }, 201);
    const phien = (path, action, data = {}, code = 200) =>
      goi('/meta/vi/session', { token: path.split('#')[1], action, ...data }, code);
    try {
      await start();
      token = (await goi('/api/account/register', {
        email: 'nap@example.test', hoTen: 'Thử nạp', matKhau: 'mat-khau-kiem-thu',
      }, 201)).token;
      const don = await batDau('pkg_50');
      const cauHinh = await phien(don.path, 'open');
      expect(cauHinh.value).to.equal(ethers.toQuantity(ethers.parseEther('0.005')));
      await phien(don.path, 'prepare', { address: user1.address });
      await phien(don.path, 'result', { status: 'rejected' });
      expect((await goi('/api/wallet/deposits/latest')).order.status).to.equal('rejected');
      const thuLai = await batDau('pkg_50', don.orderId);
      expect(thuLai.orderId).to.equal(don.orderId);
      await phien(don.path, 'open', {}, 410);
      await phien(thuLai.path, 'prepare', { address: user2.address }, 409);
      await phien(thuLai.path, 'prepare', { address: user1.address });
      await (await user1.sendTransaction({ to: cauHinh.to, data: cauHinh.data, value: cauHinh.value })).wait();
      await stop();
      await start();
      const latest = await goi('/api/wallet/deposits/latest');
      expect(latest.order.status).to.equal('confirming');
      expect((await goi('/api/wallet')).coinBalance).to.equal(0);
      await network.provider.send('evm_mine');
      const ketQua = await Promise.all([
        goi('/api/wallet/deposits/latest'),
        goi(`/api/wallet/deposits/${don.orderId}/verify`, {}),
        goi(`/api/wallet/deposits/${don.orderId}/verify`, {}),
      ]);
      expect(ketQua[0].order.status).to.equal('completed');
      expect(ketQua[1].newBalance).to.equal(50);
      expect(ketQua[2].newBalance).to.equal(50);
      expect((await goi('/api/wallet/transactions')).transactions).to.have.length(1);

      const saiGoi = await batDau('pkg_50');
      await phien(saiGoi.path, 'prepare', { address: user1.address });
      const tx = await contract.connect(user1).deposit(saiGoi.orderId, 2, { value: ethers.parseEther('0.01') });
      await tx.wait();
      await phien(saiGoi.path, 'signed', { txHash: tx.hash });
      await goi(`/api/wallet/deposits/${saiGoi.orderId}/verify`, {}, 400);
      expect((await goi('/api/wallet')).coinBalance).to.equal(50);
      chainSai = true;
      await goi('/api/wallet/deposits', { packageId: 'pkg_100', checkout: true }, 503);
    } finally {
      if (backend?.listening) await stop();
      await rm(temp, { recursive: true, force: true });
    }
  });
});
