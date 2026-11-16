# Flutter Academy — nền tảng học trực tuyến chạy trên web

Dựng lại ứng dụng của sách *Taking Flutter to the Web* (Damodar Lohani,
Packt 2022) bằng thư viện phiên bản **2026**: Flutter 3.47, go_router 18,
Riverpod 3, Hive CE. Chạy được trên web, Android, iOS, Windows, macOS và
Linux từ cùng một mã nguồn — nhưng mọi quyết định thiết kế đều nhắm vào web.

Biên soạn: **Võ Thái Anh** · Trường Đại học Phenikaa · Tháng 9/2026

> Sách viết trên Flutter 3.0. Chép nguyên mã trong sách vào dự án mới thì
> phần lớn không biên dịch được. Toàn bộ khác biệt được liệt kê theo từng
> chương trong **[DOI-CHIEU-2022-2026.md](DOI-CHIEU-2022-2026.md)** — đọc
> tệp đó trước nếu thầy cô đang dạy theo sách.

---

## 1. Chạy

```bash
cd flutter_academy
flutter create .          # sinh web/ android/ ios/ … cho máy của bạn
flutter pub get
flutter run -d chrome
```

Lệnh `flutter create .` **không ghi đè** `lib/`, `test/`, `assets/` và
`pubspec.yaml`.

Sinh lại bộ ảnh bìa (tuỳ chọn — ảnh đã có sẵn trong `assets/images/`):

```bash
pip install pillow
python3 cong-cu/sinh_anh_bia.py
```

Chạy bộ kiểm thử:

```bash
flutter test
```

Kiểm tra cảnh báo:

```bash
flutter analyze
```

---

## 2. Ứng dụng làm được gì

| | |
|---|---|
| **Trang chủ** | mảng giới thiệu, dải "Tiếp tục học", dải khoá học nổi bật, danh sách chủ đề |
| **Danh sách khoá học** | tìm theo từ khoá (bỏ dấu tiếng Việt), lọc theo chủ đề / mức độ / học phí, năm kiểu sắp xếp — **tất cả nằm trong URL** |
| **Chi tiết khoá học** | mô tả, danh sách bài, thanh tiến độ, nút "Học tiếp" |
| **Trang học** | video YouTube, mục lục, đánh dấu đã xong, bài trước / bài sau và AI Tutor |
| **Khoá học của tôi** | cần đăng nhập; khoá đang học dở xếp trước khoá đã hoàn thành |
| **Hồ sơ** | thống kê, chọn giao diện sáng/tối, đăng xuất |

Tiến độ học được lưu bằng **Hive**, ngay trong trình duyệt (IndexedDB).
Trình phát bài mẫu kết nối YouTube. Khi bật AI Tutor, backend gửi câu hỏi và
tài liệu bài học hiện tại tới Gemini hoặc OpenAI tùy cấu hình. Email và tiến
độ học vẫn lưu cục bộ.

### Dùng thử AI Tutor

Danh mục có năm khóa miễn phí với 16 video YouTube tiếng Anh. Mỗi bài có tên
kênh, liên kết YouTube và nội dung hướng dẫn tiếng Việt trong
`assets/bai_hoc_ai.json`. Tutor dựa vào nội dung và code của bài đang mở.

- **Bắt đầu với Flutter** theo [lộ trình chính thức của Flutter](https://docs.flutter.dev/learn/pathway).
- **Quản lý trạng thái trong Flutter** tuyển chọn từ [kênh Flutter](https://www.youtube.com/@flutterdev).
- **Điều hướng theo URL với go_router** gồm [video giới thiệu của Flutter](https://www.youtube.com/watch?v=b6Z885Z46cU),
  [ví dụ điều hướng với tham số](https://www.youtube.com/watch?v=9c5A-iaiLqI) và
  [bài thực hành ShellRoute](https://www.youtube.com/watch?v=L-DhEd5hF3M).
- **Python cơ bản** và **Java cơ bản** tuyển chọn từ [kênh Bro Code](https://www.youtube.com/@BroCodez).

1. Cài Node.js 22 trở lên. Tạo tệp `.env` ở thư mục gốc dự án và thêm dòng
   `GEMINI_API_KEY=khóa_của_bạn` hoặc `OPENAI_API_KEY=khóa_của_bạn`. Git bỏ
   qua tệp này. Backend dùng Gemini nếu có cả hai khóa. Có thể chọn model
   bằng `GEMINI_MODEL` hoặc `OPENAI_MODEL` tương ứng. Các biến đã đặt trong
   terminal được ưu tiên hơn tệp `.env`.
2. Từ thư mục gốc dự án, chạy `node server/ai-tutor.mjs`.
3. Mở terminal khác và chạy Flutter Web với địa chỉ backend.

   ```powershell
   flutter run -d chrome --dart-define=AI_TUTOR_URL=http://127.0.0.1:8787/api/ai-tutor
   ```

4. Mở một bài học, chọn mức giải thích và đặt câu hỏi.

Backend demo chỉ lắng nghe trên loopback. Để chạy Android debug với cùng
backend, chạy `adb reverse tcp:8787 tcp:8787` rồi dùng cùng giá trị
`AI_TUTOR_URL` khi chạy Flutter trên thiết bị. Nếu Android chặn HTTP cục bộ,
cho phép cleartext trong manifest **debug**. Để phát video trực tuyến trong
bản Android release, thêm quyền `android.permission.INTERNET` vào manifest
chính sau khi sinh thư mục Android.

Khóa API chỉ được cấu hình ở backend. Bản demo local có thể kiểm tra bằng
`node --test server/ai-tutor.test.mjs`.

---

## 3. Cấu trúc mã nguồn

```
lib/
├── main.dart                  Mở hộp Hive rồi lắp ghép các provider
├── app.dart                   MaterialApp.router
├── cau_hinh/
│   ├── diem_ngat.dart         Ba khổ màn hình — HÀM THUẦN, kiểm thử được
│   └── mau_sac.dart           Một seed color sinh ra cả chủ đề sáng lẫn tối
├── models/                    Dart thuần, không import Flutter
│   ├── khoa_hoc.dart, bai_hoc.dart, nguoi_dung.dart, tien_do.dart
│   ├── bo_loc.dart            Lọc + sắp xếp + đổi qua lại với tham số URL
│   ├── tim_kiem.dart          Bỏ dấu tiếng Việt để tìm kiếm
│   └── dinh_dang.dart         Thời lượng, tiền, điểm — không dùng gói intl
├── data/
│   ├── kho_du_lieu.dart       BA GIAO DIỆN TRỪU TƯỢNG — ranh giới của dự án
│   ├── kho_hive.dart          Bản cài đặt dùng Hive
│   ├── bo_chuyen_doi.dart     TypeAdapter viết tay, không cần build_runner
│   ├── khoi_tao_hive.dart     Mở hộp trước runApp
│   └── du_lieu_mau.dart       Danh mục khoá học YouTube
├── viewmodels/                Biết models và data; KHÔNG import material.dart
│   ├── providers.dart         Toàn bộ provider gom một chỗ
│   ├── tien_do_vm.dart        AsyncNotifier + cập nhật lạc quan
│   ├── phien_vm.dart          AsyncNotifier cho phiên đăng nhập
│   └── chu_de_vm.dart         Notifier đồng bộ (sáng/tối)
├── dinh_tuyen/
│   ├── duong_dan.dart         Mọi URL của ứng dụng — hàm thuần, kiểm thử được
│   └── bo_dinh_tuyen.dart     GoRouter, ShellRoute, redirect bảo vệ
├── widgets/                   Widget dùng lại, không biết go_router lẫn Hive
└── screens/                   Bảy màn hình
```

Quy tắc phân tầng, đọc từ trên xuống — **mũi tên chỉ đi một chiều**:

```
screens/  →  widgets/  →  viewmodels/  →  data/  →  models/
                                      ↘  dinh_tuyen/
```

Cách kiểm tra trong mười giây: mở một tệp trong `viewmodels/` và nhìn danh
sách `import`. Thấy `package:flutter/material.dart` là có gì đó đã đi sai
đường.

---

## 4. Ba điều web khác di động, và dự án này xử lý ra sao

### 4.1. URL là một phần của giao diện

Bộ lọc của trang danh sách **không** nằm trong `State` cũng **không** nằm
trong provider nào. Nó nằm trong tham số truy vấn:

```
/khoa-hoc?q=dieu%20huong&danh-muc=Web&sap=danh-gia
```

Luồng dữ liệu đi một chiều:

```
bấm chip → context.go(URL mới) → go_router dựng lại màn hình
         → BoLoc.tuThamSo(thamSo) → BoLoc.apDung(danh sách)
```

Nhờ vậy ba việc sau tự nhiên đúng mà không phải viết thêm dòng nào: bấm Back
quay lại bộ lọc trước, F5 giữ nguyên bộ lọc, gửi link cho người khác thì họ
thấy đúng cái mình thấy.

Thêm một provider giữ bản sao của bộ lọc là tạo ra nguồn sự thật thứ hai — và
hai nguồn thì sớm muộn cũng lệch nhau, thường là ngay sau khi người dùng bấm
nút Back.

### 4.2. Người dùng gõ tay được địa chỉ

Trên di động, "đường dẫn không tồn tại" gần như không xảy ra. Trên web thì
đó là chuyện thường ngày. Dự án xử lý ba mức:

* `errorBuilder` → trang 404 nói rõ địa chỉ nào hỏng và đưa về chỗ dùng được;
* mã khoá học không có thật → thông báo riêng, cụ thể hơn trang 404;
* `?tiep=...` sau đăng nhập → **chỉ chấp nhận đường dẫn nội bộ**, chặn lỗ
  hổng *open redirect*.

### 4.3. Chuột không vuốt được như ngón tay

Dải khoá học cuộn ngang luôn hiện thanh cuộn (`thumbVisibility: true`). Bản
viết cho di động không cần, bản web thì không có là người dùng không biết còn
nội dung bị khuất.

---

## 5. Bộ kiểm thử

```bash
flutter test
```

Hơn 100 phép kiểm tra, chạy trong vài trăm mili giây vì **gần như toàn bộ là
logic thuần** — không nạp Hive, không dựng widget.

| Tệp | Kiểm cái gì |
|---|---|
| `tim_kiem_test.dart` | bỏ dấu tiếng Việt, khớp nhiều từ khoá |
| `bo_loc_test.dart` | lọc, sắp xếp, đổi qua lại với tham số URL |
| `dinh_dang_test.dart` | thời lượng, tiền, điểm, rút gọn số |
| `tien_do_test.dart` | phần trăm hoàn thành, dọn dữ liệu cũ |
| `duong_dan_test.dart` | dựng URL, chặn truy cập, chọn tab, open redirect |
| `diem_ngat_test.dart` | khổ màn hình và số cột lưới |
| `providers_test.dart` | ViewModel, dùng `ProviderContainer.test()` + kho giả lập |
| `widget_test.dart` | `ThanhLoc` và `KhoiRong` — phần **buộc** phải dựng widget |

Ba kho giả lập trong `test/kho_gia_lap.dart` viết tay, chưa tới 80 dòng,
không dùng `mockito` hay `mocktail`. Với một tầng kho chỉ có tám phương thức
thì viết tay vừa ngắn hơn vừa dễ đọc hơn — và không thêm một bước sinh mã.

Chúng thay được kho thật chỉ nhờ `lib/data/kho_du_lieu.dart` khai báo giao
diện trừu tượng. Nếu màn hình gọi thẳng `Hive.box(...)` thì không có bài kiểm
thử nào ở trên viết được.

---

## 6. Dựng bản phát hành và triển khai

### 6.1. Dựng

```bash
flutter build web --release
```

Kết quả nằm trong `build/web/`. Muốn biên dịch sang WebAssembly:

```bash
flutter build web --release --wasm
```

> Cờ `--web-renderer` đã bị **gỡ bỏ** từ Flutter 3.29. Mã trong sách 2022
> dùng cờ này sẽ báo lỗi tham số không hợp lệ.

Đặt trong thư mục con (ví dụ GitHub Pages của một kho dự án):

```bash
flutter build web --release --base-href "/ten-kho/"
```

Quên `--base-href` là ra **trang trắng** và console báo không tải được
`main.dart.js`. Đây là lỗi triển khai phổ biến nhất.

### 6.2. Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting     # thư mục công khai: build/web, chọn SPA = Yes
flutter build web --release
firebase deploy --only hosting
```

`firebase.json` đã có sẵn trong dự án, kèm hai thứ hay bị quên:

* **`rewrites`** — không có thì tải lại `/khoa-hoc/dart-co-ban` ra lỗi 404,
  vì máy chủ không biết đường dẫn đó là gì (điều hướng chạy phía trình duyệt);
* **`headers`** — `index.html` đặt `no-cache`, các tệp có vân tay trong tên
  đặt cache một năm. Làm ngược lại thì triển khai xong người dùng vẫn thấy
  bản cũ.

### 6.3. GitHub Pages + CI/CD

`.github/workflows/web.yml` có sẵn hai việc:

* `kiem-thu` — chạy `flutter analyze --fatal-infos` và `flutter test` trên
  **mọi** pull request;
* `trien-khai` — chỉ chạy trên `main`, chỉ khi kiểm thử đã xanh, tự đặt
  `--base-href` theo tên kho và chép `index.html` thành `404.html`.

Bước chép `404.html` là cần thiết vì GitHub Pages không có cơ chế rewrite.

---

## 7. Muốn sửa gì thì sửa ở đâu

| Muốn làm gì | Sửa ở đâu |
|---|---|
| Thêm / sửa khoá học | `lib/data/du_lieu_mau.dart` và `assets/bai_hoc_ai.json`. Tăng phiên bản hộp danh mục trong `kho_hive.dart` để trình duyệt đã dùng bản cũ tự nạp lại danh mục. |
| Đổi màu thương hiệu | `ChuDe.mauGoc` trong `lib/cau_hinh/mau_sac.dart` |
| Đổi ngưỡng khổ màn hình | `lib/cau_hinh/diem_ngat.dart` |
| Thêm một trang mới | thêm `GoRoute` trong `lib/dinh_tuyen/bo_dinh_tuyen.dart` |
| Bảo vệ một trang | thêm đường dẫn vào `DuongDan.canDangNhap` |
| Đổi kiểu sắp xếp | thêm giá trị vào `enum ThuTuSapXep` |
| Đổi phong cách ảnh bìa | sửa `cong-cu/sinh_anh_bia.py` rồi chạy lại |
| **Thay Hive bằng máy chủ** | viết lớp `implements KhoKhoaHoc`, sửa ba dòng trong `main.dart` |

---

## 8. Bài tập mở rộng

Xếp theo độ khó tăng dần, bám đúng mạch các chương của sách.

1. **Mức 1** — Lưu lựa chọn sáng/tối xuống Hive để không mất khi tải lại
   trang. Gợi ý: thêm một hộp `cai_dat`, đổi `ChuDeVM` thành `AsyncNotifier`.
2. **Mức 1** — Thêm kiểu sắp xếp "Nhiều bài nhất" vào `ThuTuSapXep` và viết
   bài kiểm thử cho nó.
3. **Mức 1** — Thêm nút "Đánh dấu cả khoá đã xong" ở trang chi tiết.
4. **Mức 2** — Thêm chức năng đánh dấu khoá học yêu thích: một hộp Hive mới,
   một kho dữ liệu mới, một trang mới trong thanh điều hướng.
5. **Mức 2** — Phân trang danh sách khoá học bằng tham số `?trang=2`, và giữ
   đúng khi bấm Back.
6. **Mức 2** — Thêm ghi chú cá nhân cho từng bài học, lưu bằng Hive.
7. **Mức 3** — Chuyển `ShellRoute` sang `StatefulShellRoute.indexedStack` để
   mỗi tab giữ riêng vị trí cuộn và ngăn xếp điều hướng.
8. **Mức 3** — Thay `HiveKhoKhoaHoc` bằng `FirebaseKhoKhoaHoc` đọc từ
   Firestore, giữ Hive làm bộ nhớ đệm khi ngoại tuyến.
9. **Mức 3** — Dựng bản `--wasm`, đo thời gian tải lần đầu của hai bản bằng
   tab Network của DevTools, viết một trang so sánh.

---

## 9. Điều cần biết trước khi dùng làm bài mẫu

* **Chưa chạy `flutter analyze` và `flutter test` trên máy biên soạn**, vì
  môi trường dựng tài liệu không cài được Dart SDK. Mã nguồn được viết theo
  tài liệu API chính thức của từng gói (đã tra `pub.dev` và tài liệu
  `riverpod.dev`, `docs.flutter.dev` tại thời điểm biên soạn) và đã rà soát
  thủ công bằng công cụ kiểm tra cú pháp riêng. Hãy chạy
  `flutter pub get && flutter analyze && flutter test` trước khi phát cho
  sinh viên.
* Kỳ vọng của các bài kiểm thử về **thứ tự sắp xếp** đã được kiểm chứng bằng
  một bản dịch sang Python chạy độc lập — đặc biệt là chi tiết dễ sai:
  sau khi bỏ dấu, `"kiem thu"` đứng **trước** `"kien truc"` vì `m < n`.
* Video được phát từ YouTube. Nếu trình phát nhúng không khả dụng, dùng
  nút **Xem trên YouTube** ngay dưới video.
* "Đăng nhập" không có mật khẩu và không xác thực gì cả. Nó tồn tại để dạy
  phần điều hướng có bảo vệ và trạng thái phiên.
* Danh mục YouTube được nạp vào hộp Hive riêng khi mở bản mới lần đầu.
  Tiến độ học và phiên đăng nhập dùng các hộp riêng.

---

## 10. Nguồn tham khảo

| Địa chỉ | Nội dung |
|---|---|
| pub.dev/packages/go_router | go_router 18, publisher flutter.dev |
| riverpod.dev/docs/whats_new | Danh sách thay đổi của Riverpod 3 |
| pub.dev/packages/hive_ce | Hive Community Edition |
| docs.hive.isar.community | Tài liệu Hive CE |
| docs.flutter.dev/platform-integration/web | Flutter trên web, WebAssembly |
| docs.flutter.dev/deployment/web | Dựng và triển khai bản web |
| Damodar Lohani, *Taking Flutter to the Web*, Packt 2022 | Sách gốc |
