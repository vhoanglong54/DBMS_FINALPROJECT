# SQL Server scripts

Chạy duy nhất runner tích hợp từ thư mục gốc:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName GymManagementDB -DropExisting
```

Thứ tự do runner quản lý: tạo database → schema/constraint → function → trigger/view/index → procedure → security → seed → smoke test. Tên database luôn truyền qua SQLCMD variable, không hard-code.

Các nhóm file:

- `00`–`01`: database và 15 bảng chuẩn hóa.
- `02a`–`07a`: hội viên, gói tập, billing.
- `02b`–`09b`: phòng/lớp/lịch, booking, check-in.
- `04c`, `06c`, `08c`: dashboard và báo cáo.
- `08*`: 5 role, `GRANT`, `DENY`, `REVOKE` và quyền execute.
- `09*`: dữ liệu demo idempotent.
- `10*`: kiểm thử tự động và gate rubric.

`-DropExisting` xóa đúng database được truyền vào; không dùng trên dữ liệu cần giữ. Để demo bốn SQL login riêng, bật `-CreateDemoLogins` và truyền bốn mật khẩu không phải placeholder.

Để cập nhật riêng procedure và quyền bảo mật cho database đã có dữ liệu (bao gồm chức năng cấp tài khoản nhân viên), chạy:

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName GymManagementDemo -SecurityOnly
```

Chế độ này không chạy lại schema, seed hoặc smoke test và không cho dùng chung với `-DropExisting`.

Sau khi pull bản sửa nghiệp vụ/web, cập nhật function, view, procedure và grant trên database **đã có dữ liệu** bằng lệnh sau (không tạo lại bảng, không chạy seed, không xóa dữ liệu):

```powershell
.\database\run-database.ps1 -Server '.\SQLEXPRESS' -DatabaseName GymManagementDemo -UpdateLogicOnly
```

Không dùng `-DropExisting` trên database đang sử dụng. `-UpdateLogicOnly` không chạy smoke test ghi dữ liệu; kiểm thử đầy đủ trên một database riêng trước khi áp dụng nếu cần.
