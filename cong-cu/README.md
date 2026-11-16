# Công cụ sinh tài nguyên

## `sinh_anh_bia.py`

Vẽ toàn bộ 12 ảnh bìa khoá học trong `assets/images/`.

```bash
pip install pillow
python3 cong-cu/sinh_anh_bia.py
```

Ảnh **đã có sẵn** trong kho mã, chỉ cần chạy lại khi muốn đổi phong cách đồ
hoạ hoặc khi thêm khoá học mới.

### Vì sao tự vẽ thay vì tải ảnh về

Dự án là tài liệu dạy học, sẽ phát cho sinh viên và đưa lên kho mã công khai.
Ảnh tải từ Internet gần như luôn kèm một giấy phép mà không ai đọc. Toàn bộ
ảnh ở đây do đoạn mã này vẽ ra nên không có ràng buộc bản quyền nào.

### Ảnh luôn giống nhau ở mọi lần chạy

Hạt giống của bộ sinh số ngẫu nhiên lấy từ **tên tệp**
(`hashlib.sha256(ten_tep)`), nên chạy lại script không làm ảnh nhảy lung tung
trong lịch sử Git. Muốn đổi một bìa: đổi kiểu hoa văn của nó trong danh sách
`KHOA_HOC`.

### Bảy kiểu hoa văn

| Kiểu | Hình | Dùng cho |
|---|---|---|
| `luoi` | lưới nghiêng + chấm | bài nền tảng |
| `cay` | cây nhị phân | cây widget |
| `khung` | khung lồng nhau | bố cục |
| `song` | đường hình sin lệch pha | hoạt ảnh |
| `tomau` | tổ ong | Hive |
| `hat` | nút nối nhau | mạng, API |
| `tang` | ba tầng + mũi tên | kiến trúc |
| `dothi` | đồ thị phụ thuộc | Riverpod |
| `duong` | cây phân nhánh | định tuyến |

### Thêm khoá học mới

Phải sửa **hai** chỗ và giữ chúng khớp nhau:

1. `lib/data/du_lieu_mau.dart` — thêm một `KhoaHoc`, đặt `anhBia: 'bia_x.png'`;
2. `cong-cu/sinh_anh_bia.py` — thêm một dòng vào `KHOA_HOC` với đúng tên tệp
   đó, rồi chạy lại script.

Quên bước 2 thì ứng dụng vẫn chạy: `AnhBia` có phương án dự phòng vẽ một bìa
chuyển màu kèm tiêu đề. Nhưng bìa dự phòng đơn giản hơn nhiều.

Bảng màu `MAU_DANH_MUC` trong script phải khớp `ChuDe.mauDanhMuc` trong
`lib/cau_hinh/mau_sac.dart`.
