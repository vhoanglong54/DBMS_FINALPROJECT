# Data dictionary v1.0

Contract này được freeze bởi TV1. Mọi thay đổi cột/kiểu/khóa phải có issue, migration, cập nhật tài liệu và review của TV1.

## Identity và nhân sự

### `VaiTro`

| Cột | Kiểu | Null | Ý nghĩa/ràng buộc |
|---|---|---:|---|
| `RoleId` | `smallint identity` | Không | PK |
| `RoleCode` | `varchar(30)` | Không | Unique, mã uppercase dùng cho authorization claim |
| `RoleName` | `nvarchar(100)` | Không | Unique, tên hiển thị |
| `Description` | `nvarchar(500)` | Có | Mô tả quyền |
| `IsActive` | `bit` | Không | Default 1 |
| `CreatedAt` | `datetime2(0)` | Không | UTC |

### `NguoiDung`

| Cột | Kiểu | Null | Ý nghĩa/ràng buộc |
|---|---|---:|---|
| `UserId` | `int identity` | Không | PK |
| `RoleId` | `smallint` | Không | FK `VaiTro` |
| `Username` | `varchar(50)` | Không | Unique, 4–50 ký tự an toàn |
| `PasswordHash` / `PasswordSalt` | `varbinary(64/32)` | Không | PBKDF2-SHA256; không trả cho UI |
| `PasswordIterations` | `int` | Không | 100.000–1.000.000 |
| `MustChangePassword` | `bit` | Không | Cờ đổi mật khẩu tạm |
| `FailedLoginCount` | `tinyint` | Không | Số lần sai liên tiếp |
| `LockedUntil` / `LastLoginAt` | `datetime2(0)` | Có | UTC; lockout/audit đăng nhập |
| `IsActive` | `bit` | Không | Khóa mềm tài khoản |
| `CreatedAt` / `UpdatedAt` | `datetime2(0)` | Không | UTC |
| `RowVersion` | `rowversion` | Không | Chống lost update |

### `NhanVien`

| Cột | Kiểu | Null | Ý nghĩa/ràng buộc |
|---|---|---:|---|
| `EmployeeId` | `int identity` | Không | PK |
| `UserId` | `int` | Có | FK, unique filtered; nhân viên có thể chưa có tài khoản |
| `EmployeeCode` | `varchar(20)` | Không | Unique |
| `FullName` | `nvarchar(120)` | Không | Họ tên |
| `DateOfBirth` | `date` | Có | Ngày sinh |
| `Gender` | `varchar(10)` | Có | `MALE/FEMALE/OTHER` |
| `Phone` / `Email` | `varchar(15/254)` | Không/Có | Liên hệ |
| `Address` | `nvarchar(300)` | Có | Địa chỉ |
| `HireDate` | `date` | Không | Ngày vào làm |
| `EmployeeType` | `varchar(20)` | Không | `MANAGER/RECEPTIONIST/TRAINER/ACCOUNTANT` |
| `IsActive`, timestamps, `RowVersion` | hệ thống | Không | Khóa mềm/audit/concurrency |

## Hội viên và tài chính

### `HoiVien`

`MemberId` (PK), `MemberCode` (unique), `FullName`, `DateOfBirth`, `Gender`, `Phone`, `Email` (unique filtered), `Address`, `EmergencyContact`, `MedicalNote`, `JoinedAt`, `IsActive`, timestamps và `RowVersion`. `MedicalNote` là dữ liệu nhạy cảm, không nằm trong view cơ bản.

### `GoiTap`

`PlanId` (PK), `PlanCode` (unique), `PlanName`, `Description`, `DurationDays` (1–1095), `Price` (`decimal(18,2)` không âm), `MaxCheckInsPerDay` (1–10), `AllowsClasses`, `IsActive`, timestamps và `RowVersion`.

### `DangKyGoi`

`MembershipId` (PK bigint), FK `MemberId`, `PlanId`, `SoldByEmployeeId`; `StartDate`, `EndDate`; `PriceAtPurchase`; `Status`; `CancellationReason`; timestamps và `RowVersion`. Ngày kết thúc không trước ngày bắt đầu; hủy phải có lý do.

### `HoaDon`

`InvoiceId` (PK bigint), `InvoiceCode` (unique), FK `MembershipId`, `CreatedByEmployeeId`; `IssuedAt`, `TotalAmount`, `PaidAmount`, `Status`, `Note`, timestamps và `RowVersion`. `0 ≤ PaidAmount ≤ TotalAmount`.

### `CTHoaDon`

`InvoiceDetailId` (PK bigint), FK `InvoiceId`; `ItemType`, `Description`, `Quantity`, `UnitPrice`, `DiscountAmount`, `LineTotal` computed persisted, `CreatedAt`. Chiết khấu không vượt thành tiền trước chiết khấu.

### `ThanhToan`

`PaymentId` (PK bigint), `PaymentCode` (unique), FK `InvoiceId`, `ReceivedByEmployeeId`; `Amount`, `PaymentMethod`, `Status`, `TransactionReference`, `PaidAt`, `Note`, `CreatedAt`. Số tiền phải dương.

## Lớp và vận hành

### `PhongTap`

`RoomId` (PK), `RoomCode` (unique), `RoomName`, `Capacity` (1–500), `Location`, `IsActive`, timestamps và `RowVersion`.

### `LopTap`

`ClassId` (PK), `ClassCode` (unique), `ClassName`, `Description`, `DefaultDurationMinutes` (15–240), `DifficultyLevel`, `IsActive`, timestamps và `RowVersion`.

### `LichLop`

`SessionId` (PK bigint), FK `ClassId`, `RoomId`, `TrainerId`; `StartAt`, `EndAt`, `Capacity`, `Status`, `Note`, timestamps và `RowVersion`. `EndAt > StartAt`; trigger TV3 sẽ kiểm sức chứa phòng và trùng lịch.

### `DatLop`

`BookingId` (PK bigint), FK `MemberId`, `SessionId`; unique cặp hội viên–buổi; `Status`, `BookedAt`, `CancelledAt`, `CancellationReason`, timestamps và `RowVersion`. Trạng thái hủy bắt buộc có thời điểm hủy.

### `CheckIn`

`CheckInId` (PK bigint), FK `MemberId`, `EmployeeId`, `SessionId` nullable; `CheckedAt`, `CheckInMethod`, `Note`, `CreatedAt`. `SessionId` rỗng nghĩa là check-in tập tự do.

## Audit

### `AuditLog`

`AuditId` (PK bigint), `TableName`, `ActionType`, `EntityKey`, `OldValues`, `NewValues`, FK nullable `ChangedByUserId`, `CorrelationId`, `ChangedAt`. Giá trị cũ/mới phải là JSON hợp lệ; bảng chỉ thêm, không cập nhật/xóa trong nghiệp vụ thường.
