# 🦊 HƯỚNG DẪN KẾT NỐI VÍ METAMASK & NẠP COIN (CHUẨN HỌC PHẦN INT1449)

Tài liệu này hướng dẫn chi tiết từng bước kết nối ví **MetaMask**, cấu hình mạng **Hardhat Local**, cấp ETH thử nghiệm và thực hiện nạp Coin trên nền tảng **Flutter Academy** đúng theo bài giảng thực hành của giảng viên.

---

## 📑 MỤC LỤC
1. [Mô hình 3 tiến trình hoạt động](#1-mô-hình-3-tiến-trình-hoạt-động)
2. [Bước 1: Khởi động Hardhat Local Node & Deploy Smart Contract](#bước-1-khởi-động-hardhat-local-node--deploy-smart-contract)
3. [Bước 2: Cài đặt & Cấu hình mạng Hardhat Local trên MetaMask](#bước-2-cài-đặt--cấu-hình-mạng-hardhat-local-trên-metamask)
4. [Bước 3: Chọn tài khoản ví & Import vào MetaMask](#bước-3-chọn-tài-khoản-ví--import-vào-metamask)
5. [Bước 4: Cấp 1 ETH thử nghiệm cho Ví cá nhân (Slide 20)](#bước-4-cấp-1-eth-thử-nghiệm-cho-ví-cá-nhân-slide-20)
6. [Bước 5: Kết nối ví & Nạp Coin trên giao diện Website](#bước-5-kết-nối-ví--nạp-coin-trên-giao-diện-website)
7. [Bảng xử lý các lỗi thường gặp (Slide 23 & 24)](#bảng-xử-lý-các-lỗi-thường-gặp-slide-23--24)

---

## 1. MÔ HÌNH 3 TIẾN TRÌNH HOẠT ĐỘNG

Theo hướng dẫn trong slide, hệ thống yêu cầu 3 tiến trình chạy song song trên các cửa sổ PowerShell:

| Cửa sổ | Thành phần | Thư mục | Cổng | Vai trò |
| :--- | :--- | :--- | :--- | :--- |
| **PS 1** | **Hardhat node** | `blockchain` | `:8545` | Mạng Blockchain thử nghiệm local |
| **PS 2** | **Backend API** | `server` | `:8787` | Xác thực tài khoản, tạo đơn nạp, kiểm tra on-chain |
| **PS 3** | **Flutter Web** | `lib` | `:8082` | Giao diện học trực tuyến & nạp Coin |

> ⚠️ **Quy tắc quan trọng**: Giữ cửa sổ **PS 1** và **PS 2** luôn mở khi chạy ứng dụng. Nếu tắt node Hardhat, trạng thái blockchain trên RAM sẽ biến mất.

---

## BƯỚC 1: KHỞI ĐỘNG HARDHAT LOCAL NODE & DEPLOY SMART CONTRACT

### 1.1. Cửa sổ PowerShell 1: Khởi động Blockchain Node
```powershell
cd c:\Users\Admin\flutter_academy-main\flutter_academy-main\blockchain
npx hardhat node
```
* Khi xuất hiện dòng: `Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/` kèm danh sách 20 tài khoản thử nghiệm (`Account #0` đến `#19`) $\rightarrow$ **Node đã chạy thành công, hãy giữ cửa sổ này chạy liên tục**.

### 1.2. Cửa sổ PowerShell bổ sung: Deploy Smart Contract
Mở thêm một tab PowerShell để deploy hợp đồng:
```powershell
cd c:\Users\Admin\flutter_academy-main\flutter_academy-main\blockchain
node scripts/deploy.js
```
* Màn hình sẽ in ra địa chỉ hợp đồng đã deploy, thông thường là:
  `0x5FbDB2315678afecb367f032d93F642f64180aa3`

---

## BƯỚC 2: CÀI ĐẶT & CẤU HÌNH MẠNG HARDHAT LOCAL TRÊN METAMASK

1. Cài đặt tiện ích mở rộng **MetaMask** trên trình duyệt Google Chrome (từ Chrome Web Store).
2. Mở MetaMask, nhấn vào menu chọn mạng ở góc trên bên trái (mặc định là *Ethereum Mainnet*).
3. Chọn **Thêm mạng (Add a network)** $\rightarrow$ chọn tiếp **Thêm mạng thủ công (Add a network manually)**.
4. Điền chính xác các thông tin sau (theo Slide 16):

| Trường | Giá trị cần điền |
| :--- | :--- |
| **Tên mạng (Network name)** | `Hardhat Local` |
| **URL RPC mới (RPC URL)** | `http://127.0.0.1:8545` |
| **Mã chuỗi (Chain ID)** | `31337` |
| **Ký hiệu tiền tệ (Currency symbol)** | `ETH` |
| **URL trình khám phá khối** | *Để trống* |

5. Nhấn **Lưu (Save)** và chuyển sang mạng **Hardhat Local**.

---

## BƯỚC 3: CHỌN TÀI KHOẢN VÍ & IMPORT VÀO METAMASK

Theo Slide 17 của giảng viên, các tài khoản Hardhat có phân công vai trò:
* **Account #0** (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`): Dành cho Deployer (triển khai hợp đồng).
* **Account #1** (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`): Dành cho Backend / Trọng tài ký duyệt.
* **Account #2 trở đi**: Dành cho Học viên / Người chơi nạp Coin (có sẵn 10,000 ETH test).

### Cách nhập Account #2 vào MetaMask:
1. Trong MetaMask, bấm vào menu danh sách tài khoản (Avatar tròn ở giữa trên cùng).
2. Chọn **Thêm tài khoản hoặc phần cứng** $\rightarrow$ chọn **Nhập tài khoản (Import account)**.
3. Dán **Private Key** của `Account #2` (lấy từ log ở cửa sổ PS 1 khi chạy `npx hardhat node`):
   ```text
   0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
   ```
4. Bấm **Nhập (Import)**. Tài khoản này sẽ có sẵn số dư `10,000 ETH` để bạn thoải mái thử nghiệm!

---

## BƯỚC 4: CẤP 1 ETH THỬ NGHIỆM CHO VÍ CÁ NHÂN (SLIDE 20)

Nếu bạn không muốn dùng Account #2 của Hardhat mà muốn dùng **chính tài khoản ví cá nhân của bạn** (địa chỉ ví riêng bạn tạo):

Ví mới tạo trên mạng Local ban đầu sẽ có `0 ETH` (không đủ trả phí Gas). Bạn có thể cấp ngay 1 ETH vào ví bằng lệnh PowerShell sau (Slide 20):

```powershell
$diaChiVi = Read-Host "Dán địa chỉ ví cá nhân MetaMask của bạn"
$body = @{ 
  jsonrpc = "2.0" 
  method  = "hardhat_setBalance" 
  params  = @($diaChiVi, "0xDE0B6B3A7640000") # 1 ETH = 10^18 wei
  id      = 1 
} | ConvertTo-Json -Compress 

Invoke-RestMethod -Uri "http://127.0.0.1:8545" -Method Post -ContentType "application/json" -Body $body
```
* Kết quả trả về `result: True` $\rightarrow$ Mở MetaMask lên bạn sẽ thấy ví của mình đã được cộng ngay **1 ETH**!

---

## BƯỚC 5: KẾT NỐI VÍ & NẠP COIN TRÊN GIAO DIỆN WEBSITE

### 5.1. Khởi động Backend & Frontend
* **Cửa sổ PS 2 (Backend)**:
  ```powershell
  cd c:\Users\Admin\flutter_academy-main\flutter_academy-main
  node --env-file=.env server/ai-tutor.mjs
  ```
* **Cửa sổ PS 3 (Flutter Web)**:
  ```powershell
  $env:Path += ";D:\Dowloads\flutter_windows_3.47.6-stable\flutter\bin"
  cd c:\Users\Admin\flutter_academy-main\flutter_academy-main
  flutter run -d chrome --web-port 8082
  ```

### 5.2. Luồng thao tác trên trình duyệt:
1. Mở Chrome truy cập: `http://localhost:8082`.
2. Đăng nhập vào tài khoản học viên (hoặc đăng ký mới).
3. Bấm vào icon Avatar góc trên $\rightarrow$ chọn **Ví Coin & Blockchain** (hoặc truy cập `/vi-coin`).
4. Tại mục MetaMask, bấm nút **Kết nối MetaMask** (hoặc **Liên kết lại**).
5. Popup MetaMask hiện lên $\rightarrow$ Chọn đúng tài khoản của bạn $\rightarrow$ Bấm **Next** $\rightarrow$ Bấm **Connect**.
6. Sau khi kết nối thành công, bấm **Nạp Coin qua MetaMask** (hoặc truy cập `/nap-coin`).
7. Chọn gói nạp (ví dụ: *50 Coin = 0.005 ETH* hoặc *100 Coin = 0.01 ETH*) $\rightarrow$ Bấm **Nạp ngay**.
8. Cửa sổ MetaMask sẽ hiển thị chi tiết giao dịch $\rightarrow$ Bấm **Xác nhận (Confirm)**.
9. Đợi 1-2 giây để giao dịch được đóng block trên Hardhat $\rightarrow$ Hệ thống tự động cập nhật số dư Coin! 🎉

---

## BẢNG XỬ LÝ CÁC LỖI THƯỜNG GẶP (SLIDE 23 & 24)

| Lỗi gặp phải | Nguyên nhân | Cách khắc phục triệt để |
| :--- | :--- | :--- |
| **`Nonce too high. Expected nonce to be 0 but got X`** | Node Hardhat vừa khởi động lại (đặt về block 0), nhưng MetaMask còn lưu cache số thứ tự giao dịch cũ. | Trong MetaMask: **Cài đặt (Settings)** $\rightarrow$ **Nâng cao (Advanced)** $\rightarrow$ Bấm **Xóa dữ liệu hoạt động và nonce (Clear activity and nonce data)**. |
| **`TransactionExecutionError: StackOverflow`** | Do lỗi Nonce ở trên khiến giao dịch bị từ chối, MetaMask mô phỏng lại dẫn đến tràn ngăn xếp. | Xử lý lỗi Nonce ở trên (Clear nonce data) là lỗi này tự hết. |
| **`MetaMask báo duplicate account`** | Private key của tài khoản này đã được nhập vào MetaMask trước đó. | Không cần import lại, chỉ cần mở danh sách tài khoản của MetaMask và chọn tài khoản đó theo địa chỉ. |
| **`Ví thiếu ETH (Insufficient funds)`** | Ví của bạn chưa có ETH để trả phí gas hoặc tiền mua gói. | Dùng script ở **Bước 4** để cấp 1 ETH, hoặc chuyển sang dùng **Account #2** của Hardhat có sẵn 10,000 ETH. |
| **`Cannot connect to network localhost`** | Cửa sổ PS 1 chưa chạy lệnh `npx hardhat node` hoặc đã bị tắt. | Mở lại cửa sổ PowerShell chạy `npx hardhat node` ở thư mục `blockchain`. |
| **`Không hiện popup kết nối MetaMask`** | Có nhiều extension ví (như Phantom, OKX, Coinbase...) tranh quyền của MetaMask. | Tạm tắt các extension ví khác trong Chrome (`chrome://extensions`), chỉ giữ lại MetaMask rồi F5 tải lại trang. |
| **`Chưa cấu hình địa chỉ Smart Contract`** | Backend chưa load file `.env` chứa địa chỉ hợp đồng. | Chạy backend bằng lệnh `node --env-file=.env server/ai-tutor.mjs` (hệ thống cũng đã có sẵn fallback mặc định). |

---

*Tài liệu thực hành nội bộ - Bộ môn Kỹ thuật Phần mềm & Mạng máy tính.*
