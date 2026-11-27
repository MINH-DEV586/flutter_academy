// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FlutterAcademyRewards {
    address public immutable owner;
    bytes32 public constant PRO_PACKAGE = keccak256("pro_7");
    uint256 public constant PRO_PRICE = 30;

    mapping(address => uint256) public balanceOf;
    mapping(bytes32 => bool) public awarded;
    mapping(bytes32 => bool) public redeemed;

    event RewardIssued(bytes32 indexed rewardId, address indexed wallet, uint256 amount);
    event ProRedeemed(bytes32 indexed requestId, address indexed wallet, bytes32 packageId, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function issue(bytes32 rewardId, address wallet, uint256 amount) external {
        require(msg.sender == owner, "Issuer only");
        require(!awarded[rewardId], "Reward already issued");
        require(wallet != address(0) && amount > 0, "Invalid reward");
        awarded[rewardId] = true;
        balanceOf[wallet] += amount;
        emit RewardIssued(rewardId, wallet, amount);
    }

    function redeem(bytes32 salt) external {
        _redeem(salt, PRO_PACKAGE, PRO_PRICE);
    }

    function priceOf(bytes32 packageId) public pure returns (uint256) {
        if (packageId == PRO_PACKAGE) return PRO_PRICE;
        if (packageId == keccak256("pro_30")) return 100;
        if (packageId == keccak256("pro_90")) return 250;
        if (packageId == keccak256("pro_365")) return 800;
        return 0;
    }

    function redeemPackage(bytes32 salt, bytes32 packageId) external {
        uint256 price = priceOf(packageId);
        require(price != 0, "Unknown Pro package");
        _redeem(salt, packageId, price);
    }

    function _redeem(bytes32 salt, bytes32 packageId, uint256 price) private {
        bytes32 requestId = keccak256(abi.encode(msg.sender, salt));
        require(!redeemed[requestId], "Request already redeemed");
        require(balanceOf[msg.sender] >= price, "Insufficient reward balance");
        redeemed[requestId] = true;
        balanceOf[msg.sender] -= price;
        emit ProRedeemed(requestId, msg.sender, packageId, price);
    }
}
