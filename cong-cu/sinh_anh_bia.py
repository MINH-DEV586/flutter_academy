#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh toàn bộ ảnh bìa khoá học cho Flutter Academy.

    python3 cong-cu/sinh_anh_bia.py

Vì sao tự sinh thay vì tải ảnh về: dự án là tài liệu dạy học, phát cho sinh
viên và đưa lên kho mã công khai. Ảnh tải từ Internet gần như luôn kèm giấy
phép mà không ai đọc. Toàn bộ ảnh ở đây do đoạn mã này vẽ ra, nên không có
ràng buộc bản quyền nào.

Mỗi bìa là một hình hình học trừu tượng dựng từ mã khoá học: cùng một mã thì
luôn ra cùng một bìa (dùng bộ sinh số ngẫu nhiên có hạt giống), nên chạy lại
script không làm ảnh nhảy lung tung trong lịch sử Git.

Yêu cầu: Pillow (`pip install pillow`).
"""

import hashlib
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RONG, CAO = 1280, 720
THU_MUC = os.path.join(os.path.dirname(__file__), "..", "assets", "images")

FONT_DAM = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_THUONG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
if os.name == "nt":
    THU_MUC_FONT = os.path.join(os.environ["WINDIR"], "Fonts")
    FONT_DAM = os.path.join(THU_MUC_FONT, "arialbd.ttf")
    FONT_THUONG = os.path.join(THU_MUC_FONT, "arial.ttf")

# Màu nền theo danh mục — phải khớp `ChuDe.mauDanhMuc` trong
# lib/cau_hinh/mau_sac.dart. Đổi một bên thì nhớ đổi bên kia.
MAU_DANH_MUC = {
    "Nhập môn":  (0x1B, 0x5E, 0x9B),
    "Giao diện": (0x7B, 0x3F, 0x9E),
    "Dữ liệu":   (0x0E, 0x7C, 0x66),
    "Kiến trúc": (0xB5, 0x4A, 0x17),
    "Web":       (0x1C, 0x6F, 0xA8),
    "Nâng cao":  (0x8A, 0x28, 0x46),
}

# (tên tệp, danh mục, tiêu đề, kiểu hoa văn)
# Danh sách này phải khớp `lib/data/du_lieu_mau.dart`.
KHOA_HOC = [
    ("bia_dart_co_ban.png",          "Nhập môn",  "Dart từ số không",                 "luoi"),
    ("bia_widget_nhap_mon.png",      "Nhập môn",  "Widget: viên gạch của Flutter",    "cay"),
    ("bia_bo_cuc_thich_ung.png",     "Giao diện", "Bố cục co giãn và thích ứng",      "khung"),
    ("bia_hieu_ung_hoat_anh.png",    "Giao diện", "Hoạt ảnh và chuyển cảnh",          "song"),
    ("bia_luu_tru_hive.png",         "Dữ liệu",   "Lưu trữ cục bộ với Hive CE",       "tomau"),
    ("bia_goi_api_json.png",         "Dữ liệu",   "Gọi API và xử lý JSON",            "hat"),
    ("bia_kien_truc_mvvm.png",       "Kiến trúc", "Kiến trúc MVVM cho Flutter",       "tang"),
    ("bia_riverpod_3.png",           "Kiến trúc", "Quản lý trạng thái Riverpod 3",    "dothi"),
    ("bia_flutter_web_nen_tang.png", "Web",       "Flutter Web: bên dưới lớp vỏ",     "luoi"),
    ("bia_dieu_huong_url.png",       "Web",       "Điều hướng theo URL, go_router",   "duong"),
    ("bia_kiem_thu_flutter.png",     "Nâng cao",  "Kiểm thử ứng dụng Flutter",        "tomau"),
    ("bia_trien_khai_ci_cd.png",     "Nâng cao",  "Đóng gói, triển khai và CI/CD",    "tang"),
    ("bia_python_co_ban.png",       "Nhập môn",  "Python cơ bản",                   "luoi"),
    ("bia_java_co_ban.png",         "Nhập môn",  "Java cơ bản",                     "khung"),
]


def toi(mau, ti):
    """Trộn màu với đen theo tỉ lệ ti (0..1)."""
    return tuple(int(c * (1 - ti)) for c in mau)


def sang(mau, ti):
    return tuple(int(c + (255 - c) * ti) for c in mau)


def nen_chuyen_mau(goc):
    """Nền chuyển màu chéo, vẽ từng dòng rồi làm mờ nhẹ cho mịn."""
    tren = sang(goc, 0.10)
    duoi = toi(goc, 0.55)
    anh = Image.new("RGB", (RONG, CAO))
    ve = ImageDraw.Draw(anh)
    for y in range(CAO):
        t = y / (CAO - 1)
        mau = tuple(int(tren[i] + (duoi[i] - tren[i]) * t) for i in range(3))
        ve.line([(0, y), (RONG, y)], fill=mau)
    return anh


def hoa_van(anh, goc, kieu, rng):
    """Vẽ hoa văn trừu tượng lên lớp trong suốt rồi dán đè."""
    lop = Image.new("RGBA", (RONG, CAO), (0, 0, 0, 0))
    ve = ImageDraw.Draw(lop)
    nhat = sang(goc, 0.75)

    if kieu == "luoi":
        # Lưới nghiêng — gợi hình toạ độ, hợp với bài nền tảng.
        buoc = 64
        for i in range(-CAO // buoc, RONG // buoc + 2):
            x = i * buoc
            ve.line([(x, 0), (x + CAO, CAO)], fill=nhat + (46,), width=2)
            ve.line([(x + CAO, 0), (x, CAO)], fill=nhat + (26,), width=2)
        for _ in range(18):
            x = rng.randrange(0, RONG)
            y = rng.randrange(0, CAO)
            r = rng.choice((5, 7, 10))
            ve.ellipse([x - r, y - r, x + r, y + r], fill=nhat + (150,))

    elif kieu == "cay":
        # Cây nhị phân — hình ảnh của cây widget.
        def nhanh(x, y, dai, goc_do, sau):
            if sau == 0 or dai < 12:
                return
            x2 = x + dai * math.cos(goc_do)
            y2 = y - dai * math.sin(goc_do)
            ve.line([(x, y), (x2, y2)], fill=nhat + (70 + sau * 16,),
                    width=max(1, sau))
            r = 3 + sau
            ve.ellipse([x2 - r, y2 - r, x2 + r, y2 + r],
                       fill=nhat + (90 + sau * 18,))
            lech = math.radians(rng.uniform(22, 34))
            nhanh(x2, y2, dai * 0.72, goc_do + lech, sau - 1)
            nhanh(x2, y2, dai * 0.72, goc_do - lech, sau - 1)

        nhanh(RONG * 0.78, CAO + 20, 150, math.radians(96), 6)

    elif kieu == "khung":
        # Các khung lồng nhau — bố cục co giãn.
        for i in range(9):
            m = 40 + i * 34
            ve.rounded_rectangle(
                [m, m * 0.62, RONG - m, CAO - m * 0.62],
                radius=18,
                outline=nhat + (max(10, 80 - i * 8),),
                width=2,
            )

    elif kieu == "song":
        # Các đường hình sin lệch pha — chuyển động.
        for k in range(7):
            diem = []
            bien = 40 + k * 12
            pha = rng.uniform(0, 6.28)
            y0 = CAO * (0.2 + k * 0.1)
            for x in range(0, RONG + 8, 8):
                y = y0 + bien * math.sin(x / 150.0 + pha)
                diem.append((x, y))
            ve.line(diem, fill=nhat + (36 + k * 9,), width=3, joint="curve")

    elif kieu == "tomau":
        # Tổ ong — Hive nghĩa là tổ ong.
        canh = 46
        cao_o = canh * math.sqrt(3)
        hang = 0
        y = -cao_o
        while y < CAO + cao_o:
            x = -canh if hang % 2 == 0 else -canh + canh * 1.5
            while x < RONG + canh * 2:
                diem = [
                    (x + canh * math.cos(math.radians(60 * i)),
                     y + canh * math.sin(math.radians(60 * i)))
                    for i in range(6)
                ]
                dam = rng.random() < 0.10
                ve.polygon(diem, outline=nhat + (48,),
                           fill=nhat + (60,) if dam else None)
                x += canh * 3
            y += cao_o / 2
            hang += 1

    elif kieu == "hat":
        # Các nút nối với nhau — gói tin trên mạng.
        nut = [(rng.randrange(60, RONG - 60), rng.randrange(60, CAO - 60))
               for _ in range(22)]
        for i, a in enumerate(nut):
            for b in nut[i + 1:]:
                d = math.dist(a, b)
                if d < 230:
                    mo = int(70 * (1 - d / 230))
                    ve.line([a, b], fill=nhat + (mo,), width=2)
        for x, y in nut:
            r = rng.choice((4, 6, 9))
            ve.ellipse([x - r, y - r, x + r, y + r], fill=nhat + (170,))

    elif kieu == "tang":
        # Ba tầng chồng lên nhau, có mũi tên một chiều — kiến trúc phân tầng.
        for i in range(3):
            y = 150 + i * 160
            ve.rounded_rectangle([RONG * 0.52, y, RONG * 0.92, y + 96],
                                 radius=14, outline=nhat + (110,), width=3)
            if i < 2:
                gx = RONG * 0.72
                ve.line([(gx, y + 96), (gx, y + 152)],
                        fill=nhat + (110,), width=3)
                ve.polygon([(gx - 9, y + 142), (gx + 9, y + 142),
                            (gx, y + 158)], fill=nhat + (150,))

    elif kieu == "dothi":
        # Một đồ thị phụ thuộc — provider phụ thuộc provider.
        muc = [[(RONG * 0.62, CAO * 0.22)],
               [(RONG * 0.50, CAO * 0.52), (RONG * 0.74, CAO * 0.52)],
               [(RONG * 0.44, CAO * 0.82), (RONG * 0.62, CAO * 0.82),
                (RONG * 0.84, CAO * 0.82)]]
        for i in range(len(muc) - 1):
            for a in muc[i]:
                for b in muc[i + 1]:
                    ve.line([a, b], fill=nhat + (60,), width=2)
        for hang in muc:
            for x, y in hang:
                r = 18
                ve.ellipse([x - r, y - r, x + r, y + r],
                           fill=nhat + (60,), outline=nhat + (190,), width=3)

    elif kieu == "duong":
        # Đường phân nhánh có nút tròn — cây định tuyến URL.
        goc_x, goc_y = RONG * 0.50, CAO * 0.16
        ve.ellipse([goc_x - 12, goc_y - 12, goc_x + 12, goc_y + 12],
                   fill=nhat + (190,))
        for i, dx in enumerate((-190, 0, 190)):
            x2, y2 = goc_x + dx, CAO * 0.5
            ve.line([(goc_x, goc_y), (x2, y2)], fill=nhat + (80,), width=3)
            ve.ellipse([x2 - 10, y2 - 10, x2 + 10, y2 + 10],
                       fill=nhat + (160,))
            for ddx in (-70, 70):
                x3, y3 = x2 + ddx, CAO * 0.82
                ve.line([(x2, y2), (x3, y3)], fill=nhat + (55,), width=2)
                ve.ellipse([x3 - 7, y3 - 7, x3 + 7, y3 + 7],
                           fill=nhat + (130,))

    anh.paste(lop, (0, 0), lop)
    return anh


def xuong_dong(chu, font, ve, rong_toi_da):
    """Ngắt dòng theo bề rộng thật của chữ."""
    tu = chu.split()
    dong, hien = [], ""
    for t in tu:
        thu = (hien + " " + t).strip()
        if ve.textlength(thu, font=font) <= rong_toi_da or not hien:
            hien = thu
        else:
            dong.append(hien)
            hien = t
    if hien:
        dong.append(hien)
    return dong


def ve_chu(anh, danh_muc, tieu_de):
    ve = ImageDraw.Draw(anh)

    # Dải tối ở đáy để chữ luôn đọc được dù hoa văn sáng tới đâu.
    phu = Image.new("RGBA", (RONG, CAO), (0, 0, 0, 0))
    vp = ImageDraw.Draw(phu)
    for y in range(int(CAO * 0.45), CAO):
        t = (y - CAO * 0.45) / (CAO * 0.55)
        vp.line([(0, y), (RONG, y)], fill=(0, 0, 0, int(175 * t * t)))
    anh.paste(phu, (0, 0), phu)

    f_nhan = ImageFont.truetype(FONT_THUONG, 30)
    f_tieu = ImageFont.truetype(FONT_DAM, 62)

    # Nhãn danh mục trong khung bo góc.
    #
    # Khung phải vẽ trên một lớp RGBA rồi dán đè: vẽ thẳng lên ảnh RGB thì
    # kênh alpha bị bỏ qua, khung ra màu trắng đặc và chữ trắng biến mất.
    # Đây đúng là lỗi đã gặp ở lần chạy đầu tiên.
    rong_nhan = ve.textlength(danh_muc, font=f_nhan)
    khung = Image.new("RGBA", (RONG, CAO), (0, 0, 0, 0))
    vk = ImageDraw.Draw(khung)
    vk.rounded_rectangle([64, 56, 64 + rong_nhan + 40, 56 + 54],
                         radius=10, fill=(255, 255, 255, 46),
                         outline=(255, 255, 255, 130), width=2)
    anh.paste(khung, (0, 0), khung)

    ve = ImageDraw.Draw(anh)
    ve.text((84, 68), danh_muc, font=f_nhan, fill=(255, 255, 255))

    dong = xuong_dong(tieu_de, f_tieu, ve, RONG - 128)
    y = CAO - 96 - len(dong) * 76
    for d in dong:
        ve.text((64, y), d, font=f_tieu, fill=(255, 255, 255))
        y += 76
    return anh


def mot_bia(ten_tep, danh_muc, tieu_de, kieu):
    goc = MAU_DANH_MUC[danh_muc]
    # Hạt giống lấy từ tên tệp: cùng khoá học thì luôn ra cùng một bìa.
    hat = int(hashlib.sha256(ten_tep.encode("utf-8")).hexdigest()[:8], 16)
    rng = random.Random(hat)

    anh = nen_chuyen_mau(goc)
    anh = hoa_van(anh, goc, kieu, rng)
    anh = anh.filter(ImageFilter.SMOOTH)
    anh = ve_chu(anh, danh_muc, tieu_de)

    os.makedirs(THU_MUC, exist_ok=True)
    duong = os.path.join(THU_MUC, ten_tep)
    anh.save(duong, "PNG", optimize=True)
    return duong


def main():
    for ten, dm, td, kieu in KHOA_HOC:
        d = mot_bia(ten, dm, td, kieu)
        print(f"  {os.path.basename(d):34s} {os.path.getsize(d) // 1024:4d} KB")
    print(f"Đã sinh {len(KHOA_HOC)} ảnh bìa vào assets/images/")


if __name__ == "__main__":
    main()
