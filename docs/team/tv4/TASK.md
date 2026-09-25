# TASK — TV4: Ứng dụng, Dashboard & Báo cáo

## Mục tiêu nhánh

Xây dựng trải nghiệm nhất quán để người dùng thao tác được các nghiệp vụ do TV1–TV3 cung cấp, và biến View/Stored Procedure/Function thành báo cáo thật. Không làm UI chỉ có dữ liệu giả.

## Phạm vi ứng dụng

- [ ] Hoàn thiện shared layout, sidebar theo role, trạng thái loading/empty/error, format tiền/ngày tiếng Việt và validation message nhất quán.
- [ ] Dashboard theo quyền: KPI doanh thu, hội viên hiệu lực/sắp hết hạn, lớp sắp diễn ra/công suất, điểm danh hôm nay.
- [ ] Search/filter/paging cho hội viên, hóa đơn, lịch lớp, check-in.
- [ ] Gọi `vw_*`, `sp_BaoCaoDoanhThu` và scalar/TVF nghiệp vụ qua tầng data access; hiển thị trạng thái gói, chỗ còn lại, tổng chi chứ không tự tính sai ở UI.
- [ ] Hoàn thiện error handling: input không hợp lệ, lỗi từ SP, permission denied và mất kết nối SQL Server; không lộ connection string/stack trace cho người dùng.
- [ ] Chuẩn bị `appsettings.example.json`, README cài đặt/chạy, ảnh màn hình và video/demo script; không chứa secret.

## Phối hợp bắt buộc

- Với TV1: dùng contract xác thực/role, cấu hình kết nối và chuẩn UI foundation.
- Với TV2: tích hợp màn hội viên/gói/đăng ký/thanh toán bằng procedure; xác minh UI gọi SP/FN thật.
- Với TV3: tích hợp lịch/booking/check-in; hiển thị số chỗ và thông báo transaction/concurrency rõ ràng.
- Không tạo SQL object trùng module owner. Nếu cần view/report mới, mở issue và pair review với owner dữ liệu.

## Tài liệu / báo cáo

- [ ] Viết Chương 5: kiến trúc, công nghệ, các màn hình và hình chụp có chú thích; review UX rubric.
- [ ] Soạn slide demo phần UI/báo cáo và kịch bản demo 10–15 phút cùng TV1.
- [ ] Lưu ảnh index/transaction/security theo thư mục evidence do TV1 điều phối; trích dẫn nguồn tham khảo.

## Điều kiện nghiệm thu

1. Mỗi role chỉ thấy và gọi được chức năng được cấp quyền; thao tác cấm có thông báo thân thiện.
2. Có CRUD cho đối tượng chính, search, dashboard/report; báo cáo dùng View/SP/FN của SQL Server.
3. App vẫn xử lý đúng input sai/mất kết nối và không rò rỉ secret.
4. Test end-to-end trên database seed mới, kèm ảnh màn hình thật cho báo cáo; UI responsive cơ bản, dễ dùng và nhất quán.

## Rule nhánh

Trước PR, rebase `develop`, build không warning nghiêm trọng, chạy manual checklist và ghi module SQL/UI đã kiểm. Không commit thư viện build, database backup hay ảnh/secret cá nhân.
