# Hệ thống quản lý phòng gym — DBMS330284

ASP.NET Core MVC .NET 8 kết nối Microsoft SQL Server, bao phủ hồ sơ hội viên, gói tập, đăng ký–hóa đơn–thanh toán, phòng/lớp/lịch, đặt chỗ, check-in, dashboard và báo cáo theo vai trò.

## Cấu trúc repository

| Đường dẫn | Nội dung |
|---|---|
| `src/GymManagement.Web/` | Ứng dụng web MVC, controller, repository ADO.NET, Razor views và CSS |
| `database/` | Schema, constraint, trigger, view, index, procedure, function, security, seed và runner SQL Server |
| `tests/` | Unit test .NET, security test, concurrency test, index benchmark và HTTP smoke test |
| `docs/ARCHITECTURE.md` | Kiến trúc, ERD, luồng nghiệp vụ và các đối tượng SQL chính |
| `docs/DATA_DICTIONARY.md` | Từ điển 15 bảng, kiểu dữ liệu và ràng buộc |
| `docs/RUBRIC_COMPLIANCE.md` | Ma trận đối chiếu từng tiêu chí rubric |
| `docs/TEST_EVIDENCE.md` | Kết quả kiểm thử đã chạy và số liệu thực nghiệm |
| `deliverables/` | Báo cáo Word, slide và ảnh minh họa |
| `tools/` | Công cụ tái tạo báo cáo và chụp ảnh giao diện |

Điểm bắt đầu để đọc project là tài liệu kiến trúc, sau đó đến data dictionary và `database/run-database.ps1`. Luồng làm việc Git được mô tả ngắn gọn trong `docs/CONTRIBUTING.md`.

## Vai trò của các nhánh

- `main`: phiên bản phát hành ổn định, đã vượt clean-install, unit test và smoke test. Dùng nhánh này để chấm bài, demo hoặc triển khai.
- `develop`: nhánh tích hợp cho chu kỳ phát triển kế tiếp. Mọi thay đổi mới được hợp nhất vào đây trước khi phát hành.
- `feature/<issue>-<ten-ngan>`, `fix/<issue>-<ten-ngan>` hoặc `docs/<issue>-<ten-ngan>`: nhánh ngắn hạn tạo từ `develop` cho đúng một GitHub Issue. Sau review và kiểm thử, merge vào `develop` rồi xóa nhánh.

Không phát triển trực tiếp trên `main`. Chỉ merge `develop` vào `main` khi toàn bộ gate phát hành đạt.

## Tạo database demo

Yêu cầu SQL Server Express và `sqlcmd`. Nên dùng database riêng để thử thao tác:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDemo' -DropExisting
```

Runner tạo database sạch, chạy toàn bộ schema/module/security/seed và bốn tầng smoke test. Không dùng `-DropExisting` với database có dữ liệu cần giữ.

Kết quả chuẩn đã kiểm chứng: 15 bảng, 43 CHECK, 19 FK, 6 trigger, 9 view, 20 non-PK index, 42 procedure, 9 function, 16 procedure transaction và 5 database role.

## Chạy ứng dụng

Connection string không được commit. Cấu hình bằng User Secrets:

```powershell
dotnet user-secrets --project src/GymManagement.Web set "ConnectionStrings:GymDb" "Server=.\SQLEXPRESS;Database=GymManagementDemo;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=True"
dotnet test GymManagement.sln --configuration Release
dotnet run --project src/GymManagement.Web
```

Mở URL được in trong terminal. `/health` phải trả `Healthy`.

Tài khoản demo:

| Username | Password | Vai trò |
|---|---|---|
| `admin` | `Admin@123` | Quản trị |
| `letan` | `LeTan@123` | Lễ tân |
| `trainer` | `Trainer@123` | Huấn luyện viên |
| `ketoan` | `KeToan@123` | Kế toán |

## Kiểm tra thao tác nghiệp vụ

Đăng nhập bằng `admin` và thực hiện tuần tự:

1. Tạo hoặc sửa một hội viên tại **Hội viên**.
2. Tạo gói tại **Danh mục gói** rồi đăng ký gói cho hội viên.
3. Thanh toán một phần, kiểm tra hóa đơn `PARTIAL`, sau đó thanh toán đủ để đăng ký chuyển `ACTIVE` và hóa đơn chuyển `PAID`.
4. Tạo phòng, loại lớp và một buổi lớp trong tương lai tại **Vận hành lớp**.
5. Đặt lớp cho hội viên; thử lớp hết chỗ để kiểm tra `WAITLISTED`.
6. Check-in hội viên và mở dashboard/báo cáo để xác nhận dữ liệu vừa phát sinh.
7. Đăng xuất rồi đăng nhập bằng các tài khoản còn lại để kiểm tra menu và quyền theo vai trò.

Muốn đưa dữ liệu demo về trạng thái ban đầu, dừng ứng dụng và chạy lại runner với `GymManagementDemo -DropExisting`.

## Kiểm thử tự động và hồ sơ

- `database/10*.sql`: smoke test schema, membership/billing, class operations và toàn bộ gate rubric.
- `tests/sql/`: kiểm tra lockout và quyền `GRANT/DENY`.
- `tests/concurrency/`: kịch bản hai session chống overbooking.
- `tests/index/tv3_benchmark.sql`: so sánh `STATISTICS IO/TIME` trước/sau index.
- `tests/run-app-smoke.ps1`: đăng nhập thật và kiểm tra các route chính.
- [TEST_EVIDENCE.md](docs/TEST_EVIDENCE.md): kết quả kiểm thử đã chạy.
- [RUBRIC_COMPLIANCE.md](docs/RUBRIC_COMPLIANCE.md): ma trận đối chiếu rubric.

Mọi công việc mới và bàn giao đều thực hiện bằng GitHub Issues/Pull Requests theo [CONTRIBUTING.md](docs/CONTRIBUTING.md).
