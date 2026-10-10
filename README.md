# Hệ thống quản lý phòng gym — DBMS330284

ASP.NET Core MVC .NET 8 kết nối Microsoft SQL Server, bao phủ hồ sơ hội viên, gói tập, đăng ký–hóa đơn–thanh toán, phòng/lớp/lịch, đặt chỗ, check-in, dashboard và báo cáo theo vai trò.

## Chạy database

Yêu cầu SQL Server Express và `sqlcmd`:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDB' -DropExisting
```

Runner tạo database sạch, chạy toàn bộ schema/module/security/seed và bốn tầng smoke test. Không dùng `-DropExisting` trên database có dữ liệu cần giữ.

Kết quả chuẩn đã kiểm chứng: 15 bảng, 43 CHECK, 19 FK, 6 trigger, 9 view, 20 non-PK index, 42 procedure, 9 function, 16 procedure transaction và 5 database role.

Tài khoản ứng dụng demo:

| Username | Password | Vai trò |
|---|---|---|
| `admin` | `Admin@123` | Quản trị |
| `letan` | `LeTan@123` | Lễ tân |
| `trainer` | `Trainer@123` | Huấn luyện viên |
| `ketoan` | `KeToan@123` | Kế toán |

## Chạy ứng dụng

Connection string không được commit. Cấu hình bằng User Secrets:

```powershell
dotnet user-secrets --project src/GymManagement.Web set "ConnectionStrings:GymDb" "Server=.\SQLEXPRESS;Database=GymManagementDB;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=True"
dotnet test GymManagement.sln --configuration Release
dotnet run --project src/GymManagement.Web
```

Mở URL được in trong terminal. `/health` trả `Healthy` khi kết nối SQL Server hoạt động.

## Chức năng và phân quyền

- Admin: toàn bộ dashboard, hội viên, danh mục gói, billing, vận hành và báo cáo.
- Lễ tân: hội viên, đăng ký gói, đặt lớp, check-in và báo cáo vận hành.
- Huấn luyện viên: lịch lớp, danh sách đặt chỗ, điểm danh và báo cáo lớp.
- Kế toán: hóa đơn/thanh toán và báo cáo doanh thu.

Ứng dụng ghi dữ liệu qua stored procedure; `rl_GymApp` bị `DENY` DML/SELECT trực tiếp trên schema và chỉ được `GRANT EXECUTE` các entry point cần thiết.

## Kiểm thử và hồ sơ

- `database/10*.sql`: smoke test schema, membership/billing, class operations và toàn bộ gate rubric.
- `tests/sql/`: kiểm tra lockout và quyền `GRANT/DENY`.
- `tests/concurrency/`: kịch bản hai session chống overbooking.
- `tests/index/tv3_benchmark.sql`: so sánh `STATISTICS IO/TIME` trước/sau index.
- [TEST_EVIDENCE.md](docs/TEST_EVIDENCE.md): kết quả kiểm thử đã chạy.
- [RUBRIC_COMPLIANCE.md](docs/RUBRIC_COMPLIANCE.md): ma trận đối chiếu rubric.
- `deliverables/`: báo cáo Word, ảnh minh họa thực tế và slide bảo vệ; thay `NhomXX` và thông tin thành viên trước khi nộp.

Quy trình cộng tác ngắn gọn tại [CONTRIBUTING.md](docs/CONTRIBUTING.md). Từ thời điểm hoàn thiện, mọi giao việc và bàn giao đều thực hiện bằng GitHub Issues/PR.
