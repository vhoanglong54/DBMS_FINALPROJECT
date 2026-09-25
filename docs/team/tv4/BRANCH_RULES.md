# Branch rules — tv4 (Application & Reporting)

## Phạm vi được sở hữu

- Shared layout, dashboard, search/report, validation, error UX, screenshot và tài liệu demo.
- Tích hợp View/Stored Procedure/Function do TV1–TV3 cung cấp vào ASP.NET Core MVC.
- Controller/service/repository/view model/UI thuộc dashboard, báo cáo và trải nghiệm dùng chung.

## Không được tự ý thay đổi

- `database/01_schema.sql`, identity/security/login và contract cột/FK do TV1 quản lý.
- Membership/hóa đơn/thanh toán thuộc TV2; phòng/lớp/booking/check-in thuộc TV3.
- Không tạo SQL object trùng module owner hoặc dùng dữ liệu giả thay cho kết quả từ SQL Server.

## Quy tắc thực hiện

1. Làm GYM-09 sau khi TV2/TV3 xác nhận contract View/SP/Function; làm GYM-10 sau khi các luồng chính đã tích hợp.
2. UI gọi stored procedure, view hoặc function qua tầng data access có parameter; không tự ghép SQL hoặc tự tính lại nghiệp vụ đã nằm ở database.
3. Mỗi role chỉ thấy chức năng được cấp quyền; lỗi validation, permission và mất kết nối phải thân thiện, không lộ secret hay stack trace.
4. Dashboard/report phải có loading, empty, error, filter và paging phù hợp; ngày/tiền hiển thị nhất quán tiếng Việt.
5. Không commit connection string thật, password, `bin/obj`, database backup hoặc ảnh không liên quan.
6. Trước PR: rebase `origin/develop`, build/test module, kiểm tra manual các role và cập nhật tài liệu, screenshot cùng `HANDOFF_LOG.md`.

## Definition of Done

- Các trang CRUD/search/dashboard/report dùng dữ liệu thật từ SQL Server và xử lý lỗi hợp lý.
- Phân quyền, validation và trạng thái mất kết nối được kiểm thử; không rò rỉ secret.
- PR liên kết Issue, CI xanh, có reviewer và evidence rubric cho UI/report.
