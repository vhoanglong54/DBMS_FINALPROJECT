# TASK — TV3: Lớp tập, Đặt chỗ & Check-in

## Mục tiêu nhánh

Hoàn thiện vận hành tại phòng gym: quản lý phòng/HLV/lớp/buổi học, đặt-hủy chỗ không vượt sức chứa, và check-in chỉ với hội viên hợp lệ. Đây là module bắt buộc phải có minh chứng concurrency.

## Phạm vi database

- [ ] Bảng/contract: `PhongTap`, `LopTap`, `LichLop`, `DatLop`, `CheckIn`; dùng `NhanVien`, `HoiVien`, `DangKyGoi` của contract chung.
- [ ] Constraints: sức chứa/duration dương, thời gian kết thúc > bắt đầu, unique hợp lý của booking/check-in, default trạng thái.
- [ ] Trigger set-based: chặn booking vượt công suất, chặn lịch trùng phòng/HLV, chặn check-in khi không có gói hiệu lực hoặc trùng ngày. Thảo luận TV2 để không overlap trigger.
- [ ] Procedure có `TRY...CATCH`: `sp_DatLop`, `sp_HuyDatLop`, `sp_CheckInHoiVien`, CRUD lịch lớp/phòng/lớp và nghiệp vụ điểm danh.
- [ ] Function: `fn_ChoTrongLop` và các function còn thiếu để quota toàn dự án ≥5.
- [ ] View: công suất lớp, lịch sử điểm danh, lịch lớp sắp tới (phối hợp TV4 chọn view hiển thị dashboard).
- [ ] Index: tối thiểu `LichLop(RoomId, StartAt)`, `DatLop(SessionId, Status)`, `CheckIn(MemberId, CheckedAt)`; phối hợp benchmark để toàn dự án ≥5 index và có evidence.
- [ ] Transaction 3: đặt lớp với `UPDLOCK, HOLDLOCK`; Transaction 4: hủy đặt; Transaction 5: check-in + cập nhật attendance booking nếu có.

## Kịch bản concurrency bắt buộc

Với một buổi còn đúng 1 chỗ, mở hai SSMS session, bắt đầu hai lần `sp_DatLop` gần đồng thời. Kết quả: đúng một booking `Confirmed`, session còn lại rollback/báo hết chỗ; không quá capacity. Lưu hướng dẫn tái tạo và ảnh/kết quả ở `tests/concurrency/` và `docs/evidence/`.

## Phạm vi app và tài liệu

- [ ] CRUD phòng/lớp/lịch; lọc lịch theo ngày/HLV/phòng.
- [ ] Trang đặt/hủy lớp, check-in theo mã hội viên, danh sách điểm danh.
- [ ] Viết mô tả bảng/logic transaction/concurrency cho Chương 2–4 và screenshot.

## Điều kiện nghiệm thu và rule

- Không được phép có booking confirmed vượt sức chứa, trùng cùng hội viên-cùng buổi, trùng phòng/HLV theo thời gian, hoặc check-in gói hết hạn.
- Không sửa logic hóa đơn/thanh toán TV2 hay contract user TV1 nếu chưa mở issue và có review.
- Trước PR chạy migration database sạch, tests capacity/trùng lịch/concurrency và ghi rõ script nào được thêm/sửa.
