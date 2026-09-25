# TASK — TV1 (Leader): Core, Security & Integration

## Mục tiêu nhánh

Thiết lập contract kỹ thuật chung để ba module còn lại phát triển không xung đột: cấu trúc SQL chuẩn, danh tính/phân quyền, khung ứng dụng, kiểm thử tích hợp và kiểm soát rubric.

## Issue phải thực hiện

- [x] **GYM-01** Chốt glossary, ERD và data dictionary v1; tên nhóm/danh sách thật cập nhật khi leader cung cấp.
- [x] **GYM-02** Tạo `00_create_database.sql`, `01_schema.sql`, `09_seed_demo.sql`, `10_smoke_tests.sql`; sở hữu `VaiTro`, `NguoiDung`, `NhanVien` và các FK/cột audit chung.
- [x] **GYM-03** Tạo `08_security.sql`: `rl_GymAdmin`, `rl_LeTan`, `rl_HuanLuyenVien`, `rl_KeToan`, service role; tùy chọn 4 login; minh họa `GRANT/REVOKE/DENY`.
- [x] **GYM-04** Scaffold ASP.NET Core MVC .NET 8, User Secrets/env config, `Microsoft.Data.SqlClient`, PBKDF2 login, lockout và role authorization.
- [x] **GYM-11 (phần TV1)** Tạo CI/test convention và clean-install/security evidence. Index/concurrency evidence chờ module TV2/TV3.
- [x] **GYM-12 (khởi tạo)** Tạo report/slide outline, PR template, branch rules và handoff log. Điều phối/rehearsal tiếp tục đến cuối project.

## Điều kiện nghiệm thu

1. Một máy SQL Server mới chạy scripts theo thứ tự thành công và seed được dữ liệu xuyên module.
2. App khởi động với connection string cấu hình ngoài source; đăng nhập Admin/Lễ tân/HLV/Kế toán cho kết quả quyền khác nhau.
3. Không role nghiệp vụ nào có quyền ghi trực tiếp rộng vào bảng dữ liệu; dùng `EXECUTE` procedure/`SELECT` view theo policy đã ghi.
4. `docs/RUBRIC_COMPLIANCE.md` thể hiện bằng chứng thật, không tick hộ khi chưa chạy test.
5. Mọi PR integration được test với `develop`; có mô tả migration/impact khi schema đổi.

## Không thuộc phạm vi nhánh

Không tự ý đổi quy tắc membership, thanh toán, booking hay check-in thuộc TV2/TV3. Khi cần đổi contract chung, mở issue, trao đổi và cập nhật ERD trước.

## Quy tắc riêng

- Là leader, không được tự merge PR của chính mình khi chưa có ít nhất một thành viên review.
- Commit của TV1 phải ưu tiên atomic, có test đi kèm thay đổi security/schema.
- Mỗi cuối tuần cập nhật trạng thái/risks/next action trong issue hoặc board; không chỉ báo miệng.
