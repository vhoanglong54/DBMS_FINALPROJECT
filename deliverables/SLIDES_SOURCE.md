---
title: "HỆ THỐNG QUẢN LÝ PHÒNG GYM"
subtitle: "Đồ án DBMS330284"
date: "2026"
---

# 1. Bài toán

- Một nguồn dữ liệu cho hội viên, tài chính, lớp và check-in
- Giảm nhập trùng, sai công nợ, trùng lịch và overbooking
- Báo cáo trực tiếp trên SQL Server theo vai trò

---

# 2. Phạm vi

- Hồ sơ hội viên và thể trạng
- Gói tập, đăng ký, hóa đơn, thanh toán
- Phòng, loại lớp, lịch, booking, hàng chờ
- Check-in, dashboard và bốn nhóm báo cáo

---

# 3. Kiến trúc

```text
Razor MVC → Authorization → ADO.NET Repository
          → Stored Procedure / View / Function
          → SQL Server
```

- Ghi dữ liệu chỉ qua stored procedure
- Connection string nằm ngoài source

---

# 4. Mô hình dữ liệu

- 15 bảng, 19 khóa ngoại, chuẩn hóa 3NF
- Nhóm Identity: VaiTro, NguoiDung, NhanVien
- Nhóm Membership: HoiVien, GoiTap, DangKyGoi
- Nhóm Billing: HoaDon, CTHoaDon, ThanhToan
- Nhóm Operations: PhongTap, LopTap, LichLop, DatLop, CheckIn

---

# 5. Đối tượng SQL

| Hạng mục | Kết quả |
|---|---:|
| CHECK đáng tin cậy | 43 |
| Trigger / View / Index | 6 / 9 / 20 |
| Procedure / Function | 42 / 9 |
| Procedure transaction | 16 |

---

# 6. Luồng membership & billing

1. Tạo/cập nhật hội viên
2. Chọn gói và ngày bắt đầu
3. Tạo đăng ký + hóa đơn + chi tiết
4. PENDING/PARTIAL cho đến khi trả đủ
5. Thanh toán đủ → hóa đơn PAID, gói ACTIVE

---

# 7. Luồng lớp và check-in

- Chặn phòng/HLV trùng lịch
- Chặn sức chứa lịch vượt phòng
- Đặt chỗ tuần tự bằng `UPDLOCK, HOLDLOCK`
- Hết chỗ → WAITLISTED; hủy → tự đôn
- Check-in kiểm gói và giới hạn lượt/ngày

---

# 8. Bảo mật

- PBKDF2-SHA256, salt riêng, 100.000 vòng
- Khóa 15 phút sau 5 lần sai
- 5 DB role; có GRANT, DENY, REVOKE
- `rl_GymApp`: chỉ EXECUTE, không DML bảng trực tiếp
- Cookie policy theo ADMIN/RECEPTIONIST/TRAINER/ACCOUNTANT

---

# 9. Ứng dụng

- CRUD hội viên, gói, phòng, loại lớp
- Đăng ký, thanh toán, lịch, booking, check-in
- Tìm kiếm phân trang
- Dashboard theo vai trò
- Báo cáo doanh thu, công suất, điểm danh, hết hạn

---

# 10. Clean-install test

```powershell
.\database\run-database.ps1 -DatabaseName GymRubricAudit -DropExisting
```

- Tạo schema → module → security → seed → smoke
- Tất cả bốn tầng smoke test PASS
- Rollback và catalog gate PASS

---

# 11. End-to-end

```text
HV000101
→ PREMIUM-90
→ ACTIVE + PAID
→ Booking CONFIRMED
→ CheckIn = 1
```

- Đăng nhập thật từ SQL Server
- Health và 10 route chính: HTTP 200

---

# 12. Concurrency & index

- Session B chờ 4,835 giây
- Kết quả: 1 CONFIRMED + 1 WAITLISTED
- Không overbooking
- Logical reads `LichLop`: 18 → 3, giảm 83,3%

---

# 13. Demo bảo vệ

1. Login theo bốn vai trò
2. Tạo hội viên và giao dịch PARTIAL → PAID
3. Đặt lớp, hàng chờ và check-in
4. Dashboard/report
5. Chạy security + concurrency + index evidence

---

# 14. Kết luận

- Bao phủ toàn bộ nhóm tiêu chí kỹ thuật của rubric
- Database là nguồn sự thật nghiệp vụ
- Bộ cài và test tái tạo bằng một lệnh
- Hướng mở rộng: QR, thanh toán thật, đa chi nhánh, audit nâng cao

**Xin cảm ơn!**
