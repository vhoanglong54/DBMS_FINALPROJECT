# Glossary và quy tắc nghiệp vụ v1

| Thuật ngữ | Định nghĩa chuẩn |
|---|---|
| Hội viên | Cá nhân có hồ sơ tại gym; `IsActive` chỉ cho biết hồ sơ được phép sử dụng, không thay thế trạng thái gói tập. |
| Gói tập | Sản phẩm định nghĩa thời lượng, giá niêm yết, số lượt check-in/ngày và quyền tham gia lớp. |
| Đăng ký gói | Một lần hội viên mua/gia hạn gói; giữ giá tại thời điểm bán bằng `PriceAtPurchase`. |
| Hóa đơn | Chứng từ công nợ gắn với một đăng ký gói, có nhiều chi tiết và nhiều lần thanh toán. |
| Thanh toán | Một lần nhận tiền của hóa đơn; chỉ `COMPLETED` được tính vào số đã trả. |
| Lớp tập | Danh mục loại lớp (Yoga, HIIT); chưa có thời gian/phòng/HLV cụ thể. |
| Lịch lớp | Một buổi diễn ra cụ thể của lớp tập, tại một phòng, với một HLV và sức chứa xác định. |
| Đặt lớp | Quan hệ hội viên–lịch lớp; một hội viên chỉ có một bản ghi cho mỗi buổi, trạng thái có thể thay đổi. |
| Check-in | Lượt hội viên vào gym hoặc điểm danh một lịch lớp, được nhân viên xác nhận. |
| Role ứng dụng | `ADMIN`, `RECEPTIONIST`, `TRAINER`, `ACCOUNTANT`; được đưa vào cookie claim sau đăng nhập. |
| Database role | `rl_GymAdmin`, `rl_LeTan`, `rl_HuanLuyenVien`, `rl_KeToan`; dùng minh họa GRANT/REVOKE/DENY trên SQL Server. |

## State machine bắt buộc

- Đăng ký gói: `PENDING → ACTIVE ↔ SUSPENDED → EXPIRED`; `PENDING/ACTIVE/SUSPENDED → CANCELLED` khi có lý do.
- Hóa đơn: `PENDING → PARTIAL → PAID`; chỉ hóa đơn chưa thanh toán nghiệp vụ mới được `CANCELLED`.
- Thanh toán: `PENDING → COMPLETED`; `COMPLETED → VOIDED/REFUNDED` phải có nghiệp vụ đối soát do TV2 bổ sung.
- Lịch lớp: `SCHEDULED → IN_PROGRESS → COMPLETED`; `SCHEDULED → CANCELLED`.
- Đặt lớp: `WAITLISTED → CONFIRMED → ATTENDED/NO_SHOW`; `WAITLISTED/CONFIRMED → CANCELLED`.

## Quy tắc xuyên module

1. Không suy ra gói còn hiệu lực chỉ từ `HoiVien.IsActive`; phải đồng thời kiểm tra đăng ký `ACTIVE` và ngày hiện tại trong `[StartDate, EndDate]`.
2. Giá và mô tả trên hóa đơn là snapshot tại thời điểm bán; đổi giá gói không làm đổi hóa đơn cũ.
3. `LichLop.Capacity` không vượt `PhongTap.Capacity`; TV3 chịu trách nhiệm trigger/procedure bảo vệ quy tắc này.
4. Booking phải khóa và kiểm lại số chỗ trong cùng transaction; không dùng số chỗ tính ở UI làm căn cứ ghi.
5. Check-in phải kiểm tra hồ sơ hoạt động, gói hiệu lực, giới hạn lượt/ngày và quyền lớp nếu check-in vào lịch lớp.
6. Không xóa cứng chứng từ tài chính hoặc lịch sử check-in; dùng trạng thái hủy/void và audit.
7. Tất cả tiền, ngày, trạng thái phải được validate ở cả UI và database.
