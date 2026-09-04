# TASK — TV2: Membership & Billing

## Mục tiêu nhánh

Hoàn thiện chuỗi nghiệp vụ từ hồ sơ hội viên đến bán/gia hạn gói, phát sinh hóa đơn, nhận thanh toán và truy vấn công nợ. Mọi thao tác ghi từ app phải gọi Stored Procedure.

## Phạm vi database

- [ ] Bảng/contract: `HoiVien`, `GoiTap`, `DangKyGoi`, `HoaDon`, `CTHoaDon`, `ThanhToan` (theo schema TV1 chốt).
- [ ] Constraints meaningful: mã hội viên duy nhất, giá/duration gói dương, ngày bắt đầu-kết thúc hợp lệ, số tiền thanh toán dương, phương thức/trạng thái hợp lệ, default ngày tạo.
- [ ] Procedure có `TRY...CATCH`: `sp_DangKyGoi`, `sp_GhiNhanThanhToan`, CRUD/search hội viên/gói, `sp_BaoCaoDoanhThu` (phối hợp TV4 phần hiển thị).
- [ ] Function: `fn_TrangThaiGoi`, `fn_SoNgayConLai`, `fn_TuoiHoiVien`, `fn_TongChiHoiVien` và một function nghiệp vụ khác nếu cần đạt quota chung.
- [ ] Trigger set-based: tái tính tổng hóa đơn khi chi tiết thay đổi; cập nhật trạng thái hóa đơn khi thanh toán; audit thay đổi trạng thái đăng ký. Phối hợp TV3 để tổng số trigger đạt/qua 5 mà không trùng logic.
- [ ] View: hội viên còn hiệu lực, hóa đơn còn nợ, doanh thu theo ngày/khoảng thời gian.
- [ ] Transaction 1: đăng ký/gia hạn = registration + invoice + invoice detail. Transaction 2: ghi thanh toán = payment + invoice status/balance. Cả hai có rollback test.

## Phạm vi app và tài liệu

- [ ] Màn hình CRUD hội viên/gói; trang đăng ký/gia hạn và thanh toán; lịch sử thanh toán/công nợ.
- [ ] Validate email/số điện thoại/ngày/tiền tại UI và DB; thông báo lỗi từ SP thân thiện.
- [ ] Viết data dictionary, mô tả SP/FN/trigger/view thuộc module cho Chương 2–3; thêm screenshot test.

## Điều kiện nghiệm thu

1. Tạo/gia hạn gói trên app sinh đúng đăng ký+hóa đơn; lỗi ở bất cứ bước nào không để dữ liệu nửa vời.
2. Không thanh toán âm, vượt dư nợ, hoặc trên hóa đơn không hợp lệ; trạng thái hóa đơn cập nhật đúng.
3. App đọc báo cáo/danh sách qua view/SP/function, không dùng SQL nối chuỗi để ghi.
4. Có test success, invalid input và forced rollback; script chạy được cùng database sạch.

## Ranh giới và rule

Không sửa `NguoiDung`, `VaiTro`, `NhanVien` hay schema chung mà không qua TV1. Không sửa room/class/booking/check-in của TV3. Trước PR, rebase `develop`, chạy smoke test và liệt kê các file SQL/app ảnh hưởng.
