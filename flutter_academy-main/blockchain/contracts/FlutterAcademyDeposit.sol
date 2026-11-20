// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title FlutterAcademyDeposit
/// @notice Smart contract nhận thanh toán Sepolia ETH để nạp Coin cho Flutter Academy.
/// @dev Mỗi giao dịch nạp có orderId duy nhất, chống replay và double-spending.
contract FlutterAcademyDeposit {
    address public owner;
    bool public paused;

    struct Package {
        uint256 coinAmount;
        uint256 ethPrice;    // wei
        bool active;
    }

    /// Danh sách gói nạp. packageId bắt đầu từ 1.
    mapping(uint256 => Package) public packages;
    uint256 public packageCount;

    /// Chống sử dụng lại orderId.
    mapping(bytes32 => bool) public usedOrderIds;

    /// Event phát ra khi người dùng nạp Coin thành công.
    event Deposit(
        bytes32 indexed orderId,
        address indexed buyer,
        uint256 packageId,
        uint256 amountPaid,
        uint256 coinAmount,
        uint256 timestamp
    );

    /// Event quản trị.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(bool isPaused);
    event Withdrawal(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Chi chu so huu moi co quyen");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Hop dong dang tam dung");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Khởi tạo 5 gói nạp mặc định (giá tính bằng wei)
        // 1 Coin = 0.0001 ETH = 100000000000000 wei
        _addPackage(50,   0.005 ether);   // Gói 1: 50 Coin
        _addPackage(100,  0.01 ether);    // Gói 2: 100 Coin
        _addPackage(250,  0.025 ether);   // Gói 3: 250 Coin
        _addPackage(500,  0.05 ether);    // Gói 4: 500 Coin
        _addPackage(1000, 0.1 ether);     // Gói 5: 1000 Coin
    }

    /// @notice Nạp Coin bằng cách gửi ETH kèm orderId và packageId.
    /// @param orderId Mã đơn hàng duy nhất (do backend tạo).
    /// @param packageId Mã gói nạp (1-5).
    function deposit(bytes32 orderId, uint256 packageId) external payable whenNotPaused {
        require(orderId != bytes32(0), "orderId khong hop le");
        require(!usedOrderIds[orderId], "orderId da duoc su dung");

        Package memory pkg = packages[packageId];
        require(pkg.active, "Goi nap khong ton tai hoac da tat");
        require(msg.value >= pkg.ethPrice, "Khong du ETH thanh toan");

        usedOrderIds[orderId] = true;

        emit Deposit(
            orderId,
            msg.sender,
            packageId,
            msg.value,
            pkg.coinAmount,
            block.timestamp
        );

        // Hoàn trả ETH thừa
        uint256 excess = msg.value - pkg.ethPrice;
        if (excess > 0) {
            (bool sent, ) = payable(msg.sender).call{value: excess}("");
            require(sent, "Hoan tra ETH that bai");
        }
    }

    // ── Quản trị ─────────────────────────────────────────────────────────

    /// @notice Rút toàn bộ ETH trong contract về ví chủ sở hữu.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Khong co ETH de rut");
        (bool sent, ) = payable(owner).call{value: balance}("");
        require(sent, "Rut ETH that bai");
        emit Withdrawal(owner, balance);
    }

    /// @notice Rút một lượng ETH cụ thể về địa chỉ chỉ định.
    function withdrawTo(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Dia chi khong hop le");
        require(amount <= address(this).balance, "Khong du so du");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Rut ETH that bai");
        emit Withdrawal(to, amount);
    }

    /// @notice Chuyển quyền sở hữu.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Dia chi khong hop le");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Tạm dừng hoặc mở lại contract.
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// @notice Thêm gói nạp mới.
    function addPackage(uint256 coinAmount, uint256 ethPrice) external onlyOwner {
        _addPackage(coinAmount, ethPrice);
    }

    /// @notice Bật/tắt gói nạp.
    function setPackageActive(uint256 packageId, bool active) external onlyOwner {
        require(packageId >= 1 && packageId <= packageCount, "packageId khong hop le");
        packages[packageId].active = active;
    }

    /// @notice Cập nhật giá gói nạp.
    function updatePackagePrice(uint256 packageId, uint256 newEthPrice) external onlyOwner {
        require(packageId >= 1 && packageId <= packageCount, "packageId khong hop le");
        packages[packageId].ethPrice = newEthPrice;
    }

    // ── Internal ─────────────────────────────────────────────────────────

    function _addPackage(uint256 coinAmount, uint256 ethPrice) internal {
        packageCount++;
        packages[packageCount] = Package(coinAmount, ethPrice, true);
    }

    /// @notice Xem thông tin gói nạp.
    function getPackage(uint256 packageId) external view returns (
        uint256 coinAmount, uint256 ethPrice, bool active
    ) {
        Package memory pkg = packages[packageId];
        return (pkg.coinAmount, pkg.ethPrice, pkg.active);
    }

    /// @notice Kiểm tra orderId đã sử dụng chưa.
    function isOrderUsed(bytes32 orderId) external view returns (bool) {
        return usedOrderIds[orderId];
    }

    /// @notice Nhận ETH trực tiếp (không qua deposit → reject).
    receive() external payable {
        revert("Vui long su dung ham deposit()");
    }
}
