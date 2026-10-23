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
| `tools/` | Công cụ tái tạo báo cáo và bằng chứng SQL Server |

Điểm bắt đầu để đọc project là tài liệu kiến trúc, sau đó đến data dictionary và `database/run-database.ps1`.

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

Kết quả chuẩn của bản cài mới: 15 bảng, 43 CHECK, 19 FK, 6 trigger, 9 view, 20 non-PK index, 45 procedure, 9 function, 17 procedure transaction và 5 database role.

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

Sau khi đăng nhập, nhân viên có thể chọn **Đổi mật khẩu** trên thanh tài khoản. Hệ thống yêu cầu nhập mật khẩu hiện tại, mật khẩu mới (8–128 ký tự) và xác nhận. Nếu `NguoiDung.MustChangePassword = 1`, tài khoản sẽ được đưa thẳng đến trang đổi mật khẩu và chưa thể mở các chức năng khác; đổi thành công sẽ xóa cờ này qua `dbo.sp_ChangePassword`. Các tài khoản seed ở trên có cờ bằng `0`; nếu đổi mật khẩu demo, mật khẩu mẫu trong bảng sẽ không còn đăng nhập được trên database đó.

Quản trị viên có thể mở **Nhân sự → Thêm nhân viên** để tạo hồ sơ nhân viên và cấp tài khoản cùng lúc. Mật khẩu ban đầu chỉ được băm và lưu bằng salt riêng; nhân viên sẽ đổi mật khẩu khi đăng nhập lần đầu. Mã nhân viên được gợi ý tự động từ dữ liệu hiện có (`NV-0001`, `NV-0002`…), nhưng quản trị viên vẫn có thể sửa trước khi lưu. Nếu nhập mã đã có, form báo riêng “Mã nhân viên đã được sử dụng.”; ràng buộc `UNIQUE` tại database vẫn chặn trùng khi hai người cùng mở form.

Nếu database đã được cài trước khi có chức năng này, chạy lệnh sau một lần để cập nhật procedure/quyền, **không chạy lại schema hoặc seed**:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDemo' -SecurityOnly
```

Sau khi cập nhật logic đặt chỗ, check-in và thanh toán, dùng `-UpdateLogicOnly` thay vì `-SecurityOnly`; lệnh này cập nhật function/view/procedure/quyền, giữ nguyên bảng và dữ liệu:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDemo' -UpdateLogicOnly
```

Quyền web: admin quản lý phòng/loại lớp, tạo và hủy buổi; lễ tân đăng ký/hủy gói và đặt/hủy chỗ; kế toán ghi thanh toán tiếp; HLV xem lịch và check-in lớp mình phụ trách trong khoảng từ 30 phút trước giờ bắt đầu đến khi kết thúc. Admin được thực hiện các thao tác trên. Check-in tập tự do dành cho admin/lễ tân. Hủy gói không tự hoàn tiền; gói còn chỗ lớp sắp tới hoặc hóa đơn đang trả một phần phải được xử lý trước khi hủy.

## Kiểm tra thao tác nghiệp vụ

Đăng nhập bằng `admin` và thực hiện tuần tự:

1. Tạo hoặc sửa một hội viên tại **Hội viên**.
2. Tạo gói tại **Danh mục gói** rồi đăng ký gói cho hội viên.
3. Thanh toán một phần, kiểm tra hóa đơn `PARTIAL`, sau đó thanh toán đủ để đăng ký chuyển `ACTIVE` và hóa đơn chuyển `PAID`.
4. Tạo phòng, loại lớp và một buổi lớp trong tương lai tại **Vận hành lớp**.
5. Đặt lớp cho hội viên; thử lớp hết chỗ để kiểm tra `WAITLISTED`.
6. Check-in bằng mã công khai của hội viên (ví dụ `HV0001`) và mở dashboard/báo cáo để xác nhận dữ liệu vừa phát sinh.
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
