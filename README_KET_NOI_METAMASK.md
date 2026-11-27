# MetaMask và Coin trên Hardhat Local

Khởi động và triển khai hợp đồng theo [README](README.md). Backend xác minh giao dịch nạp ETH thử nghiệm rồi cấp Coin vào cùng hợp đồng dùng cho thưởng chuỗi và đổi Pro.

## Ví và demo sáu ngày

1. Trong MetaMask, thêm **Hardhat Local**, RPC `http://127.0.0.1:8545`, chain ID `31337`, ký hiệu ETH. Với Android, cấu hình ADB reverse theo README.
2. Nhập một tài khoản thử có ETH từ danh sách Hardhat in trong terminal. Dùng khóa này riêng cho môi trường thử nghiệm và chọn tài khoản khác ví deploy.
3. Tạo tài khoản thử có email kết thúc bằng `@example.test`, mở **Ví Coin → Kết nối MetaMask** và ký xác minh. Trên Android với HTTP cục bộ, dán đường dẫn được sao chép vào trình duyệt MetaMask nếu trang ký chưa mở.
4. Từ gốc repo chạy `node server/seed-demo.mjs hocvien@example.test` với email đã tạo. Script dùng `ACADEMY_DB_PATH` hoặc SQLite mặc định. Demo có sáu ngày đến hôm qua theo giờ Việt Nam, 120 XP và huy hiệu Getting Started.
5. Trong **Ví Coin**, nhận 10 Coin ở mốc 3 rồi kiểm tra số dư. Hoàn thành một bài trong ngày mới, nhận thêm 20 Coin và kiểm tra số dư 30 nếu chưa chi tiêu hoặc nạp thêm.

Để dựng demo biệt lập, chạy `npm --prefix blockchain run compile`, mở Hardhat thử riêng trên cổng host `18545`, đặt `ACADEMY_DEMO_PASSWORD` và `ACADEMY_DEMO_WALLET` rồi chạy `node server/seed-video-demo.mjs`. Backend dùng cổng `18785`. Cờ `--chua-nhan` để mốc 3 chờ người dùng nhận. Cờ `--serve-existing` mở lại backend với database và node của phiên demo đã gieo.

## Nạp và đổi Pro

- Trong **Nạp Coin**, chọn gói, ký qua MetaMask, rồi quay lại app kiểm tra đơn.
- Các gói **7/30/90/365 ngày** cần **30/100/250/800 Coin**. Chọn gói, ký qua MetaMask rồi kiểm tra số dư và hạn Pro.
- Khi đã ký nhưng app còn chờ, dùng **Kiểm tra trạng thái** để đối soát trước khi ký lại.

## Khắc phục lỗi

| Hiện tượng | Kiểm tra |
| --- | --- |
| ADB báo `unauthorized` | Mở khóa máy, xác nhận USB debugging và chạy `adb devices -l`. |
| Android hoặc MetaMask chưa tới máy chủ | Kiểm tra `adb reverse --list`, cổng host và URL trong APK. |
| Sai tài khoản hoặc mạng | Chọn Hardhat Local 31337 và ví đã ký xác minh. |
| MetaMask báo `-32603` | Mở lại yêu cầu để lấy nonce hiện tại. Nếu lỗi lặp, xem log Hardhat và giao dịch đang chờ của ví thử. |
| Chờ Coin hoặc Pro | Kiểm tra lại trạng thái, RPC và địa chỉ từ cùng lần deploy. |
| Gia sư trả lời mẫu hoặc báo bận | Kiểm tra chế độ Demo, khóa và model. Gemini có thể trả HTTP 503 khi model đang bận. |
