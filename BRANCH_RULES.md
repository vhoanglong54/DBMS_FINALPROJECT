# Branch rules — tv3 (Classes, Booking & Check-in)

## Phạm vi được sở hữu

- Phòng tập, lớp tập, lịch lớp, booking, hủy booking, check-in và điểm danh.
- SQL module dùng hậu tố `b_operations_*` để không conflict với TV2.
- Controller/service/repository/view model/UI thuộc vận hành lớp và check-in.

## Không được tự ý thay đổi

- `database/01_schema.sql`, identity/security/login và contract cột/FK do TV1 quản lý.
- Membership/hóa đơn/thanh toán thuộc TV2; layout/report dùng chung thuộc TV4.
- Nếu contract chưa đủ, mở issue migration và chờ TV1 review trước khi code phụ thuộc.

## Quy tắc thực hiện

1. Làm database GYM-07 trước UI GYM-08.
2. Booking phải khóa hàng `LichLop` bằng `UPDLOCK, HOLDLOCK` trong transaction và kiểm capacity ngay trước insert/update.
3. Chặn trùng lịch phòng/HLV theo khoảng thời gian, không chỉ so sánh cùng `StartAt`.
4. Check-in kiểm hồ sơ, gói `ACTIVE`, ngày hiệu lực, giới hạn lượt/ngày và quyền lớp.
5. Không xóa cứng booking/check-in; dùng trạng thái và audit. Trigger phải set-based.
6. Bắt buộc test concurrency bằng hai SSMS session cho chỗ cuối cùng và lưu kết quả cuối.
7. Trước PR: rebase `origin/develop`, chạy clean database/test module, cập nhật tài liệu và `HANDOFF_LOG.md`.

## Definition of Done

- Không overbooking, double-booking, trùng phòng/HLV hoặc check-in gói hết hạn.
- Ba transaction đặt/hủy/check-in có success, invalid, rollback và concurrency evidence.
- App gọi SP/View/Function thật; PR liên kết Issue, CI xanh và có reviewer.
