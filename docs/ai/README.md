# Ghi chú sử dụng AI

Nhóm dùng Codex để đối chiếu rubric với source, triển khai cùng nhóm và viết kiểm thử. Các trích đoạn dưới đây được rút gọn từ trao đổi làm việc. Hồ sơ lưu phần cần cho việc rà mã và nghiệm thu, cùng đường dẫn kiểm thử có liên quan.

## 1. Tutor và lịch sử

> Người dùng — AI Tutor đã hoàn thành phần triển khai và các kiểm thử được báo cáo.
>
> Codex — Lịch sử lưu theo tài khoản và bài. Đóng chat sẽ hủy stream và giữ phần đã nhận để thử lại.

Phần rà soát gồm phạm vi lưu lịch sử, hủy stream khi đổi bài và hiển thị phiên đang chờ. Bằng chứng UI Chrome dùng **Demo**, gồm đăng nhập, streaming, trích dẫn, quiz và mở lại chat. [ViewModel](../../lib/viewmodels/gia_su_ai_vm.dart) · [Widget test](../../test/gia_su_ai_widget_test.dart)

## 2. Hàng đợi Coin thưởng

> Người dùng — Hoàn thiện coin thưởng tích hợp vào chuỗi ngày học hiện có.
>
> Codex — Ca mới phát hiện thêm một lỗi khi thử lại: thao tác dọn trạng thái đồng bộ trả về chính Future đang chờ hoàn tất.

Phần rà soát gồm giải phóng Future sau khi gửi, giữ sự kiện gặp lỗi tạm thời và đồng bộ tiếp sau khi bỏ một sự kiện sai vĩnh viễn. [Kho đồng bộ](../../lib/data/kho_thuong_chuoi.dart) · [Test hàng đợi](../../test/kho_thuong_chuoi_test.dart)

## 3. Thử lại đổi Pro

> Người dùng — Giữ nhãn rõ ràng cho Coin SQLite và token thưởng Hardhat theo thiết kế hiện tại.
>
> Codex — Khi Hardhat RPC mất dấu `txHash`, người dùng có thể ký lại **cùng mã yêu cầu**.

Phần rà soát gồm thử thách ký, trừ Coin đúng một lần, cấp Pro sau khi backend khởi động lại và hạn mức Tutor. Ca tích hợp ký bằng signer Hardhat. [Backend đối soát](../../server/reward-chain.mjs) · [Test tích hợp](../../blockchain/test/FlutterAcademyRewards.test.js)

## 4. Timeout Gemini

> Người dùng — Ưu tiên chẩn đoán Gemini live bị timeout.
>
> Codex — **Gemini live đã chạy thành công qua backend trên `review/rubic`.**

Phần rà soát gồm giới hạn chờ phần đầu, dòng báo chờ và xử lý dừng luồng. Ca backend live ghi HTTP 200, bảy phần văn bản và sự kiện hoàn tất kèm nguồn, quiz. [Backend streaming](../../server/tutor-stream.mjs) · [Test Tutor Node](../../server/ai-tutor.test.mjs)

## 5. Phiên MetaMask trên Android

> Người dùng — Xử lý kết nối, ngắt kết nối, kết nối lại và khôi phục phiên.
>
> Codex — MetaMask vẫn từ chối `personal_sign` vì thiếu quyền tài khoản trên mạng này. Mình đang kiểm tra luồng xin lại quyền trước khi ký.

Trang ký giữ thử thách khi WebView tải lại và xin quyền tài khoản lại trên Hardhat nếu cần. Đã ký xác minh, đổi Pro, ngắt và kết nối lại ví trên Android. [Trang ký](../../server/meta-vi.js) · [Test tải lại](../../server/meta-vi.test.mjs)

## Xác nhận rà soát

| Phần | Thành viên rà soát | Commit hoặc PR duyệt |
| --- | --- | --- |
| Tutor và lịch sử | Chờ nhóm điền | Chờ nhóm điền |
| Hàng đợi Coin thưởng | Chờ nhóm điền | Chờ nhóm điền |
| Thử lại đổi Pro | Chờ nhóm điền | Chờ nhóm điền |
| Timeout Gemini | Chờ nhóm điền | Chờ nhóm điền |
| Phiên MetaMask trên Android | Chờ nhóm điền | Chờ nhóm điền |

Chỉ bổ sung liên kết hội thoại nếu nhóm đã xem trước nội dung chia sẻ. Giữ khóa, token, dữ liệu đăng nhập và cấu hình local ngoài hồ sơ. [Báo cáo nghiệm thu](../bao-cao-nghiem-thu.md)
