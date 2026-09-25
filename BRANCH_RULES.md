# Branch rules — tv2 (Membership & Billing)

## Phạm vi được sở hữu

- Hội viên, gói tập, đăng ký/gia hạn, hóa đơn, chi tiết hóa đơn và thanh toán.
- SQL module dùng hậu tố `a_membership_*` để không conflict với TV3.
- Controller/service/repository/view model/UI thuộc membership và billing.

## Không được tự ý thay đổi

- `database/01_schema.sql`, identity/security/login và contract cột/FK do TV1 quản lý.
- Phòng/lớp/lịch/booking/check-in thuộc TV3; layout/report dùng chung thuộc TV4.
- Nếu contract chưa đủ, mở issue migration và chờ TV1 review trước khi code phụ thuộc.

## Quy tắc thực hiện

1. Làm theo thứ tự GYM-05 trước GYM-06; database API phải ổn định trước UI.
2. Mọi thao tác ghi từ app gọi Stored Procedure có parameter; không nối chuỗi SQL.
3. Hai transaction tối thiểu: đăng ký gói+tạo hóa đơn+chi tiết và ghi thanh toán+cập nhật công nợ. Dùng `SET XACT_ABORT ON`, `TRY/CATCH`, rollback và test lỗi.
4. Không xóa cứng chứng từ tài chính; payment void/refund phải có audit và lý do.
5. Trigger phải set-based; index phải có benchmark trước/sau; giá dùng `decimal(18,2)`.
6. Trước PR: rebase `origin/develop`, chạy clean database/test module, cập nhật tài liệu và `HANDOFF_LOG.md`.

## Definition of Done

- Success/invalid/rollback tests pass; app gọi SP/View/Function thật.
- Không thanh toán âm/vượt dư nợ; giá hóa đơn không đổi khi giá gói đổi.
- PR liên kết Issue, CI xanh, có reviewer và evidence rubric.
