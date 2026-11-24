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
        bytes32 requestId = keccak256(abi.encode(msg.sender, salt));
        require(!redeemed[requestId], "Request already redeemed");
        require(balanceOf[msg.sender] >= PRO_PRICE, "Insufficient reward balance");
        redeemed[requestId] = true;
        balanceOf[msg.sender] -= PRO_PRICE;
        emit ProRedeemed(requestId, msg.sender, PRO_PACKAGE, PRO_PRICE);
    }
}
