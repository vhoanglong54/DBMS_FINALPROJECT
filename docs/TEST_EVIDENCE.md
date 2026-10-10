# Bằng chứng kiểm thử — 10/10/2026

Môi trường: SQL Server Express `DESKTOP-5QITA49\SQLEXPRESS`, database sạch `GymReleaseVerify`, .NET 8 Release.

## Clean install và rubric gate

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName GymReleaseVerify -DropExisting
```

Kết quả: PASS toàn bộ `10`, `10a`, `10b`, `10c`.

| Tables | Trusted CHECK | Trigger | View | Non-PK index | Procedure | Function | Transactional procedure | Role | Rollback |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 15 | 43 | 6 | 9 | 20 | 42 | 9 | 16 | 5 | PASS |

## Build và unit test

`dotnet test GymManagement.sln --configuration Release`: build 0 warning/error; 24/24 test PASS. Bộ test gồm validation model, policy phân quyền, đăng nhập, quy tắc mã hội viên và ánh xạ trạng thái thân thiện trên giao diện.

## End-to-end HTTP + SQL

Đăng nhập `admin` bằng PBKDF2 từ database, `/health` và 10 route dashboard/CRUD/report đều HTTP 200. Luồng ghi thực tế:

```text
Tạo hội viên HV000101
→ đăng ký PREMIUM-90 và thanh toán đủ
→ DangKyGoi=ACTIVE, HoaDon=PAID
→ đặt buổi lớp SessionId=1, DatLop=CONFIRMED
→ check-in FRONT_DESK, tổng lượt CheckIn=1
```

Kiểm thử cuối còn gửi POST thật từ giao diện với `MemberCode=HV0001`; controller phân giải mã công khai sang khóa nội bộ, procedure `sp_CheckIn_GhiNhan` tạo `CheckInId=1`, sau đó lịch sử trả đúng `HV0001`. Nhân viên không còn phải nhập `MemberId` nội bộ.

## Bảo mật

- `security_permissions_test.sql`: role lễ tân đọc được view cho phép; direct DML bị lỗi quyền 229 — PASS.
- `auth_lockout_test.sql`: khóa sau 5 lần sai và reset sau đăng nhập đúng — PASS.

## Concurrency

Hai kết nối cùng đặt buổi `Capacity=1`. Session A giữ `UPDLOCK/HOLDLOCK` 5 giây; Session B chờ 4.835 giây. Kết quả cuối:

```text
Session A: CONFIRMED
Session B: WAITLISTED
CONFIRMED=1, WAITLISTED=1
```

Không overbooking; cơ chế khóa và hàng chờ hoạt động đúng.

## Index benchmark

Chạy `tests/index/tv3_benchmark.sql` với 20.000 lịch demo. Truy vấn lọc phòng và khoảng thời gian:

| Trạng thái | Logical reads bảng `LichLop` |
|---|---:|
| Trước `IX_LichLop_RoomId_StartAt_EndAt` | 16 |
| Sau index | 6 |

Logical reads giảm 62,5%. Index đưa `Status` vào key sau `RoomId` để loại nhanh phần lớn lịch đã hủy trước khi xét khoảng thời gian. Script tự tạo lại index và dọn dữ liệu benchmark.
