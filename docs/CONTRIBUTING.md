# Quy trình làm việc qua GitHub Issues

GitHub Issues là nguồn duy nhất để giao việc, theo dõi tiến độ và bàn giao. Không duy trì bảng task hoặc handoff riêng trong repository.

1. TV1 tạo Issue có phạm vi, owner, dependency và Definition of Done.
2. Owner tạo nhánh từ `develop`: `feature/<issue>-<ten-ngan>`.
3. Mỗi commit tập trung một thay đổi; không commit secret, `bin/obj`, database local hoặc file sinh tạm.
4. Trước PR phải chạy bộ cài SQL sạch nếu đổi database và chạy `dotnet test GymManagement.sln --configuration Release` nếu đổi ứng dụng.
5. PR luôn vào `develop`, liên kết Issue bằng `Closes #<issue>`, ghi rõ script/run order, test và rủi ro.
6. TV1 review contract database, security và rubric trước khi merge. Chỉ merge `develop` vào `main` khi clean-install và end-to-end smoke test đều đạt.

Quy ước code cốt lõi:

- Thao tác ghi nghiệp vụ phải qua stored procedure có parameter; transaction nhiều bước dùng `XACT_ABORT`, `TRY...CATCH` và rollback.
- Không hard-code database name, connection string hoặc mật khẩu.
- Tiền dùng `decimal(18,2)`, thời điểm audit dùng UTC, thời gian lịch lớp là giờ Việt Nam.
- Trigger phải xử lý theo tập bản ghi; mọi thay đổi schema phải cập nhật data dictionary và smoke test.
