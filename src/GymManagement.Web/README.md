# Ứng dụng ASP.NET Core MVC

Ứng dụng ASP.NET Core MVC .NET 8 hiển thị dữ liệu SQL Server thật. Dashboard và màn hình tìm kiếm/báo cáo không tạo dữ liệu mẫu trong UI; mọi số liệu đến từ reporting stored procedure.

## Chạy local

Yêu cầu .NET 8 SDK, SQL Server và `sqlcmd`. Dựng toàn bộ database bằng runner tích hợp từ thư mục gốc:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName 'GymManagementDB' -DropExisting
```

Đặt chuỗi kết nối ngoài source rồi chạy ứng dụng:

```powershell
dotnet user-secrets --project src/GymManagement.Web set "ConnectionStrings:GymDb" "Server=.\SQLEXPRESS;Database=GymManagementDB;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=True"
dotnet run --project src/GymManagement.Web
```

Seed có các tài khoản demo `admin`, `letan`, `trainer`, `ketoan`; mật khẩu được ghi trong `README.md` ở thư mục gốc. Đăng nhập được xác thực qua SQL Server và PBKDF2, không dùng tài khoản giả trong code.

## Dashboard và quyền truy cập

- **Admin** quản lý phòng, loại lớp, tạo/hủy buổi, đặt chỗ và check-in.
- **Accountant** xem doanh thu.
- **Receptionist** tìm hội viên, đăng ký/hủy gói, đặt/hủy chỗ, xem sắp hết hạn, lịch lớp và check-in.
- **Accountant** xem đăng ký/hóa đơn và ghi thanh toán tiếp; không đăng ký hoặc hủy gói.
- **Trainer** xem lịch/công suất lớp và check-in cho lớp mình phụ trách trong giờ cho phép; không sửa danh mục hay tạo/hủy buổi.

Middleware yêu cầu đăng nhập. Controller chặn từng thao tác theo role, không chỉ ẩn liên kết trên giao diện. Trang CRUD hội viên giới hạn role Admin/Lễ tân.

## Tìm kiếm và báo cáo

- Tra cứu hội viên theo tên, mã hoặc số điện thoại; lọc trạng thái membership, chọn 10/20/50/100 dòng và phân trang bằng output total count.
- Báo cáo doanh thu theo ngày, hội viên sắp hết hạn trong 30 ngày, công suất theo buổi và lịch sử check-in; khoảng ngày bao gồm cả ngày kết thúc và giới hạn tối đa 366 ngày.
- Timestamps lưu UTC được lọc và hiển thị theo giờ Việt Nam (UTC+7); lịch lớp đã lưu giờ địa phương theo contract TV3.
- Dashboard hiển thị doanh thu tháng/7 ngày, hội viên active/sắp hết hạn, lịch lớp và check-in hôm nay tùy role.
- Trạng thái rỗng và lỗi SQL có thông báo an toàn; exception kỹ thuật được ghi log phía server.

## Hợp đồng SQL và quyền service

App chỉ gọi các stored procedure sau; không `SELECT` trực tiếp bảng hay view:

| Stored procedure | Nguồn dữ liệu |
|---|---|
| `sp_TV4_DashboardHoiVien` | `vw_TV4_HoiVienTraCuu`, `vw_HoiVienSapHetHan` |
| `sp_TV4_TimKiemHoiVien` | `vw_TV4_HoiVienTraCuu`, lọc trạng thái và `OFFSET/FETCH` |
| `sp_TV4_BaoCaoDoanhThu` | `vw_TV4_DoanhThuTheoNgay` |
| `sp_TV4_BaoCaoCongSuatLop` | `fn_LichLopTheoKhoang`, `fn_ChoTrongLop` từ TV3 |
| `sp_TV4_BaoCaoDiemDanh` | `vw_LichSuCheckIn` từ TV3 |

Script `08c_tv4_reporting_security_grants.sql` chỉ cấp `EXECUTE` lên các procedure cho `rl_GymApp`; role service vẫn bị từ chối `SELECT` trực tiếp trên schema `dbo`.
