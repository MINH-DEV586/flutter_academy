const { expect } = require("chai");
const { ethers } = require("hardhat");

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

    await expect(
      contract.connect(user1).deposit(orderId1, 1, { value: pkg1Price })
    )
      .to.emit(contract, "Deposit")
      .withArgs(orderId1, user1.address, 1n, pkg1Price, 50n, await ethers.provider.getBlock("latest").then(b => b.timestamp + 1));

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
});
