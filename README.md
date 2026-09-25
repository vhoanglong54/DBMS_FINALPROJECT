# NhomXX_QuanLyPhongGym

Ứng dụng web quản lý phòng gym kết nối trực tiếp Microsoft SQL Server. Hệ thống quản lý trọn vòng đời hội viên: hồ sơ, gói tập, đăng ký, hóa đơn/thanh toán, lịch lớp, đặt lớp và check-in; đồng thời cung cấp báo cáo vận hành theo phân quyền.

> `NhomXX` là chỗ giữ chỗ. Leader thay `XX` bằng số nhóm đã được giảng viên xác nhận trước khi nộp hoặc tạo remote GitHub.

## Mục tiêu chất lượng

Thiết kế này được lập trực tiếp theo rubric DBMS330284, nhắm mức Tốt/Xuất sắc: 3NF, thành phần SQL có ý nghĩa nghiệp vụ, minh chứng index/concurrency, app gọi Stored Procedure/Function thực tế và demo kết nối SQL Server trực tiếp.

Tài liệu bắt đầu tại [kiến trúc & luồng nghiệp vụ](docs/ARCHITECTURE.md), [data dictionary](docs/DATA_DICTIONARY.md), [ma trận tuân thủ rubric](docs/RUBRIC_COMPLIANCE.md), [phân công 4 thành viên](docs/TEAM_TASKS.md) và [quy tắc Git](docs/CONTRIBUTING.md).

## Cấu trúc repo

```text
database/       SQL Server scripts nền, security, seed và smoke test
src/GymManagement.Web/  ASP.NET Core MVC .NET 8, đăng nhập và role authorization
docs/           Thiết kế, kiểm thử, báo cáo và slide
tests/          Unit test và bằng chứng SQL/hiệu năng/concurrency
```

## Quy trình nhanh

1. Leader cập nhật tên nhóm và danh sách thành viên trong `docs/TEAM_TASKS.md`.
2. Mỗi thành viên checkout `tv1`, `tv2`, `tv3` hoặc `tv4`; đọc `docs/team/<tv>/TASK.md`, `docs/team/<tv>/BRANCH_RULES.md` trước khi code và cập nhật `docs/team/<tv>/HANDOFF_LOG.md` sau mỗi task.
3. Dựng database: `.\database\run-tv1.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDB'`.
4. Cấu hình connection string ngoài source:

   ```powershell
   dotnet user-secrets --project src/GymManagement.Web set "ConnectionStrings:GymDb" "Server=.\SQLEXPRESS;Database=GymManagementDB;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=True"
   ```

5. Chạy `dotnet restore`, `dotnet test GymManagement.sln`, sau đó `dotnet run --project src/GymManagement.Web`.
6. Tạo Pull Request vào `develop`, có checklist test và ít nhất một reviewer; chỉ leader merge `develop` vào `main` sau khi demo end-to-end thành công.

## Phạm vi v1

Bao gồm membership/billing, lịch lớp/đặt chỗ/check-in, nhân sự–phòng tập, báo cáo và phân quyền. Không nhận phạm vi ngoài rubric như cổng thanh toán thật, SMS/email, nhận diện khuôn mặt hoặc đa chi nhánh nếu chưa hoàn tất checklist rubric.

## Tài liệu tham khảo nghiệp vụ

Các luồng membership, billing, booking, check-in, staff management và reporting được chọn theo các năng lực phổ biến của hệ thống gym thương mại, rồi thu gọn về phạm vi có thể demo và bảo vệ tốt trong học phần: [ABC Glofox – Gym Management Software](https://www.glofox.com/business-types/gym-management-software/).

