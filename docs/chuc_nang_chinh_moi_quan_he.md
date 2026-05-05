# DANH SÁCH CHỨC NĂNG CHÍNH VÀ MỐI QUAN HỆ

## 1. NHẬT KÝ SỨC KHỎE (Diary)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 1 | UC1 | Dinh dưỡng | Theo dõi calories, thêm bữa ăn, quét barcode, tìm kiếm thực phẩm |
| 2 | UC2 | Nước | Theo dõi lượng nước uống hàng ngày |
| 3 | UC3 | Cân nặng | Theo dõi và ghi nhận cân nặng |
| 4 | UC4 | Giấc ngủ | Theo dõi và ghi nhận thời gian ngủ |
| 5 | UC5 | Nhịp tim | Đo và theo dõi nhịp tim |
| 6 | UC6 | Thống kê | Xem thống kê sức khỏe theo ngày/tuần/tháng |

---

## 2. CÔNG THỨC NẤU ĂN (Recipes)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 7 | UC7 | Tìm kiếm | Tìm kiếm công thức nấu ăn |
| 8 | UC8 | Chi tiết | Xem chi tiết công thức (nguyên liệu, cách nấu) |
| 9 | UC9 | Lọc theo mục tiêu | Lọc công thức theo mục tiêu (giảm cân, tăng cơ...) |

---

## 3. KẾ HOẠCH TẬP (Plans)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 10 | UC10 | Kế hoạch | Xem danh sách kế hoạch tập luyện |
| 11 | UC11 | Bài tập | Xem chi tiết bài tập, video hướng dẫn |

---

## 4. CỘNG ĐỒNG (Community)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 12 | UC12 | Feed | Xem bài viết của cộng đồng |
| 13 | UC13 | Đăng bài | Tạo bài viết mới (text, ảnh, video) |
| 14 | UC14 | Tương tác | Like, comment, share bài viết |

---

## 5. THỬ THÁCH (Challenges)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 15 | UC15 | Thử thách hàng ngày | Tham gia thử thách daily |
| 16 | UC16 | Thử thách hàng tuần | Tham gia thử thách weekly |
| 17 | UC17 | Thử thách hàng tháng | Tham gia thử thách monthly |

---

## 6. THIỀN ĐỊNH (Meditation)
| STT | Mã UC | Chức năng | Mô tả |
|-----|-------|-----------|-------|
| 18 | UC18 | Thiền định | Thiền tập, nghe nhạc thiền |

---

## MỐI QUAN HỆ GIỮA CÁC CHỨC NĂNG

### Include (──►) - Bắt buộc
| Từ | → | Đến | Ý nghĩa |
|----|---|-----|---------|
| Tìm kiếm (UC7) | ─► | Chi tiết (UC8) | Xem chi tiết sau khi tìm kiếm |
| Lọc theo mục tiêu (UC9) | ─► | Chi tiết (UC8) | Xem chi tiết sau khi lọc |
| Kế hoạch (UC10) | ─► | Bài tập (UC11) | Xem bài tập trong kế hoạch |
| Feed (UC12) | ─► | Đăng bài (UC13) | Đăng bài từ feed |
| Feed (UC12) | ─► | Tương tác (UC14) | Tương tác khi xem feed |

### Extend (⇢) - Mở rộng
| Từ | → | Đến | Ý nghĩa |
|----|---|-----|---------|
| Dinh dưỡng (UC1) | ⇢ | Thống kê (UC6) | Tổng hợp calories vào thống kê |
| Nước (UC2) | ⇢ | Thống kê (UC6) | Tổng hợp nước vào thống kê |
| Cân nặng (UC3) | ⇢ | Thống kê (UC6) | Tổng hợp cân nặng vào thống kê |
| Giấc ngủ (UC4) | ⇢ | Thống kê (UC6) | Tổng hợp giấc ngủ vào thống kê |
| Nhịp tim (UC5) | ⇢ | Thống kê (UC6) | Tổng hợp nhịp tim vào thống kê |
| Chi tiết recipe (UC8) | ⇢ | Dinh dưỡng (UC1) | Thêm recipe vào bữa ăn |
| Bài tập (UC11) | ⇢ | Dinh dưỡng (UC1) | Tính calories khi tập |
| Thử thách daily (UC15) | ⇢ | Thử thách weekly (UC16) | Mở rộng lên weekly |
| Thử thách weekly (UC16) | ⇢ | Thử thách monthly (UC17) | Mở rộng lên monthly |
| Thử thách daily (UC15) | ⇢ | Thiền định (UC18) | Meditation challenge |

---

## SƠ ĐỒ MỐI QUAN HỆ

```
NHẬT KÝ SỨC KHỎE
    │
    ├─UC1(Dinh dưỡng) ──────────┐
    ├─UC2(Nước)                 │
    ├─UC3(Cân nặng)             │   extend → UC6(Thống kê)
    ├─UC4(Giấc ngủ)             │
    └─UC5(Nhịp tim) ────────────┘

CÔNG THỨC NẤU ĂN
    │
    ├─UC7(Tìm kiếm) ──include──► UC8(Chi tiết) ──extend──► UC1(Dinh dưỡng)
    └─UC9(Lọc) ─────include────►

KẾ HOẠCH TẬP
    │
    └─UC10(Kế hoạch) ──include──► UC11(Bài tập) ──extend──► UC1(Dinh dưỡng)

CỘNG ĐỒNG
    │
    └─UC12(Feed) ──include──► UC13(Đăng bài)
                  └────include──► UC14(Tương tác)

THỬ THÁCH
    │
    └─UC15(Daily) ──extend──► UC16(Weekly) ──extend──► UC17(Monthly)
                    └──────extend──► UC18(Thiền định)

THIỀN ĐỊNH
    │
    └─UC18(Thiền định)
```

---

## TÓM TẮT
- **Tổng số chức năng chính**: 18 use cases
- **Số package**: 6
- **Số mối quan hệ Include**: 5
- **Số mối quan hệ Extend**: 11