# SQL Server database

Các script TV1 tạo contract nền cho toàn dự án. Tên database được truyền bằng SQLCMD variable, không hard-code trong script.

## Chạy nhanh bằng Windows Authentication

```powershell
.\database\run-tv1.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDB'
```

Runner dừng ngay khi một script lỗi (`sqlcmd -b`) và chạy theo thứ tự:

1. `00_create_database.sql`: tạo database nếu chưa có, bật `READ_COMMITTED_SNAPSHOT`.
2. `01_schema.sql`: tạo 15 bảng, PK/FK/UNIQUE/CHECK/DEFAULT và rowversion.
3. `08_security.sql`: tạo role, view bảo mật, procedure xác thực/lockout/đổi mật khẩu.
4. `09_seed_demo.sql`: seed idempotent role, user, nhân viên và dữ liệu xuyên module.
5. `10_smoke_tests.sql`: kiểm tra catalog, constraint, role, procedure và seed.

`01_schema.sql` cố ý không chạy đè schema đã tồn tại. Thay đổi sau baseline phải dùng migration script được review, không sửa tay database.

## Phân chia file SQL còn lại

| File | Owner | Nội dung |
|---|---|---|
| `02a_membership_constraints.sql` / `02b_operations_constraints.sql` | TV2 / TV3 | constraint nghiệp vụ bổ sung ngoài contract nền |
| `03a_membership_triggers.sql` / `03b_operations_triggers.sql` | TV2 / TV3 | ≥5 trigger set-based toàn dự án |
| `04a_membership_views.sql` / `04b_operations_views.sql` / `04c_reporting_views.sql` | TV2 / TV3 / TV4 phối hợp | ≥5 view báo cáo/nghiệp vụ |
| `05a_membership_indexes.sql` / `05b_operations_indexes.sql` | TV2 / TV3 | ≥5 index và truy vấn benchmark |
| `06a_membership_procedures.sql` / `06b_operations_procedures.sql` | TV2 / TV3 | ≥5 procedure nghiệp vụ có TRY/CATCH/transaction |
| `07a_membership_functions.sql` / `07b_operations_functions.sql` | TV2 / TV3 | ≥5 scalar/TVF |
| `08_security.sql` | TV1 | role/login, GRANT/REVOKE/DENY, authentication API |

TV2/TV3 dùng đúng hậu tố module để tránh conflict khi phát triển song song; TV1 quyết định thứ tự chạy cuối. Không sửa table/column contract nếu chưa có migration và review của TV1.

## Tài khoản ứng dụng demo

| Username | Password | Role |
|---|---|---|
| `admin` | `Admin@123` | ADMIN |
| `letan` | `LeTan@123` | RECEPTIONIST |
| `trainer` | `Trainer@123` | TRAINER |
| `ketoan` | `KeToan@123` | ACCOUNTANT |

Đây chỉ là dữ liệu học tập. Không dùng các mật khẩu này trong môi trường thật. Hash được lưu bằng PBKDF2-SHA256, salt riêng, 100.000 vòng; ứng dụng khóa tài khoản 15 phút sau 5 lần sai.

## Tạo 4 SQL Login để demo phân quyền

`08_security.sql` luôn tạo 5 database role nhưng mặc định không tạo SQL Login để tránh commit password. Khi cần demo bằng SSMS, chạy riêng script với `CreateDemoLogins=1` và truyền 4 password mạnh qua biến SQLCMD. Không lưu câu lệnh đã điền password vào repo hoặc ảnh báo cáo.

## Quy tắc dữ liệu

- Thời điểm audit lưu UTC bằng `SYSUTCDATETIME()`; UI chịu trách nhiệm hiển thị múi giờ Việt Nam.
- Tiền dùng `decimal(18,2)`, không dùng `float`.
- Ghi nghiệp vụ phải đi qua Stored Procedure; các role không-admin bị `DENY` DML trực tiếp trên schema `dbo`.
- Trigger/procedure phải xử lý tập bản ghi và có test rollback/concurrency tương ứng.

