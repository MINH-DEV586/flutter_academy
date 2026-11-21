const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH");

  // Deploy contract
  const Factory = await hre.ethers.getContractFactory("FlutterAcademyDeposit");
  const contract = await Factory.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("\n══════════════════════════════════════════════");
  console.log("FlutterAcademyDeposit deployed to:", address);
  console.log("══════════════════════════════════════════════\n");

  // In function selector cho deposit(bytes32,uint256)
  const depositSelector = contract.interface.getFunction("deposit").selector;
  console.log("deposit(bytes32,uint256) selector:", depositSelector);

  // In event topic cho Deposit
  const depositEvent = contract.interface.getEvent("Deposit");
  const eventTopic = depositEvent.topicHash;
  console.log("Deposit event topic:", eventTopic);

  // In cấu hình cho .env
  console.log("\n── Thêm vào file .env ─────────────────────────");
  console.log(`CONTRACT_ADDRESS=${address}`);
  console.log(`DEPOSIT_EVENT_TOPIC=${eventTopic}`);
  console.log(`# Cập nhật DEPOSIT_SELECTOR trong web/metamask.js:`);
  console.log(`# const DEPOSIT_SELECTOR = '${depositSelector}';`);

  // Kiểm tra gói nạp
  console.log("\n── Danh sách gói nạp ──────────────────────────");
  for (let i = 1; i <= 5; i++) {
    const pkg = await contract.getPackage(i);
    console.log(`Gói ${i}: ${pkg.coinAmount} Coin = ${hre.ethers.formatEther(pkg.ethPrice)} ETH (active: ${pkg.active})`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
