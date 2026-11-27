# Flutter Academy

Ứng dụng học Flutter trên Android và web có video, tiến độ theo tài khoản, Gia sư AI và chuỗi hoàn thành bài. Coin thưởng và Coin nạp dùng chung số dư Hardhat để đổi Pro qua MetaMask.

## Chạy từ clone sạch

Bộ công cụ đã dùng gồm Flutter 3.47.7, Dart 3.13.5, Node 22.13.0, Hardhat 2.29.2 và Gradle Wrapper 9.5.0. Để build Android, cài Android SDK (API 36, Platform Tools) và JDK tương thích với Gradle/Android Gradle Plugin.

```powershell
flutter pub get --enforce-lockfile
npm --prefix blockchain ci
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

1. Mở terminal trong `blockchain/`, chạy `npx hardhat node`. RPC mặc định là `127.0.0.1:8545`, chain ID `31337`.
2. Lần đầu, từ gốc repo chạy `npm --prefix blockchain run deploy:local`. Chép `CONTRACT_ADDRESS`, `DEPOSIT_EVENT_TOPIC` và `REWARD_CONTRACT_ADDRESS` từ kết quả vào `.env`. Dùng lại các địa chỉ này khi chỉ khởi động lại backend và node vẫn chạy.
3. Chạy `node server/ai-tutor.mjs`, mặc định cổng `8787`. `AI_TUTOR_DEMO=1` dùng phản hồi mô phỏng. Với AI live, đặt `AI_TUTOR_DEMO=0` và cấu hình khóa cùng model của Gemini, OpenRouter hoặc OpenAI. Hạn mức, cổng và RPC có thể chỉnh theo mẫu.
4. Chạy web bằng `flutter run -d chrome --web-port=8082`.

## Android thật

1. Cài Git LFS, rồi chạy `git lfs install` và `git lfs pull` từ gốc repo để lấy APK tại `build/app/outputs/flutter-apk/app-debug.apk`. Bạn cũng có thể lấy `app-debug.apk` từ bản `android-debug-7f1ab49d` trong **Releases** và lưu vào cùng đường dẫn.
2. Khởi động backend theo mục trên. Nếu thử Coin hoặc MetaMask, khởi động cả Hardhat và dùng địa chỉ hợp đồng khớp với cấu hình backend.
3. Bật **Gỡ lỗi USB**, cắm điện thoại và chấp nhận hộp thoại cấp quyền. Chạy các lệnh sau từ gốc repo và thay `SERIAL` bằng mã thiết bị từ ADB.

```powershell
adb devices -l
adb -s SERIAL reverse tcp:8787 tcp:8787
adb -s SERIAL reverse tcp:8545 tcp:8545
adb -s SERIAL install -r build/app/outputs/flutter-apk/app-debug.apk
```

4. Mở **Flutter Academy** trên điện thoại và giữ cáp USB khi dùng backend hoặc Hardhat. Với backend demo ở cổng host `18785` và Hardhat ở `18545`, đổi cổng bên phải hai lệnh reverse tương ứng.

Nếu cần tự build từ source, chạy `flutter build apk --debug --no-pub --dart-define=ACADEMY_API_URL=http://127.0.0.1:8787`. APK được ghi vào cùng đường dẫn trên.

## Kiểm thử nhanh

- A hoàn thành một bài. Khách và B có tiến độ riêng. Đăng nhập lại A để kiểm tra bài đã lưu.
- Mở Tutor trong một bài, hỏi về một ví dụ cụ thể và kiểm tra streaming, nguồn, quiz, lịch sử.
- Dùng demo 6 ngày để thử mốc 3 nhận 10 Coin, ngày 7 nhận thêm 20 Coin và đổi Pro qua MetaMask. [Hướng dẫn MetaMask, demo và xử lý lỗi](README_KET_NOI_METAMASK.md)

```powershell
flutter test --no-pub test/du_lieu_hoc_theo_phien_test.dart test/thuong_chuoi_widget_test.dart
node --test server/account.test.mjs server/streak-rewards.test.mjs server/wallet.test.mjs
npm --prefix blockchain test -- test/FlutterAcademyRewards.test.js
```

## Cấu trúc và dữ liệu

- `lib/` và `assets/` chứa Flutter, ViewModel, kho dữ liệu và nội dung học.
- `server/` chứa API Node, SQLite, Gia sư AI và script demo.
- `blockchain/` chứa hợp đồng, script deploy và test Hardhat.
- `android/` và `web/` chứa cấu hình nền tảng. `test/` và `docs/` chứa kiểm thử Flutter và tài liệu dùng chung.

SQLite mặc định ở `server/.local/accounts.sqlite`. Tiến độ và lịch sử cục bộ theo tài khoản lưu trong Hive, dùng IndexedDB trên web. Hardhat giữ trạng thái trong bộ nhớ của node. Giữ node chạy để tiếp tục sử dụng cùng deployment và dữ liệu.
