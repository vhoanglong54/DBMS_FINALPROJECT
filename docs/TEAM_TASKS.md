# Phân công và điều hành nhóm 4 người

Điền họ tên/MSSV trước khi nộp. Khối lượng được chia theo module có thể kiểm thử độc lập; mỗi người phải vừa code vừa viết phần báo cáo và tự bảo vệ phần mình.

| TV | Vai trò | Nhánh | Trách nhiệm chính | Deliverable / tiêu chí Done |
|---|---|---|---|---|
| TV1 — **Leader** | kiến trúc sư, tích hợp, bảo mật | `feature/tv1-leader-core-security` | data contract, user/role/employee, login nền tảng, security, CI/test, tích hợp và điều phối | schema chuẩn, 4+ role/login + GRANT/REVOKE/DENY, app foundation/login, checklist rubric, biên bản review |
| TV2 | membership & billing | `feature/tv2-membership-billing` | hội viên/gói/đăng ký/hóa đơn/thanh toán, logic thu phí | CRUD + 2 transaction/SP, constraints/triggers/functions/views tương ứng, màn hình & test |
| TV3 | vận hành lớp & check-in | `feature/tv3-classes-checkin` | phòng/lớp/lịch/HLV/booking/check-in, concurrency | CRUD + 3 transaction/SP, trigger capacity/lịch, 2-session concurrency evidence, màn hình & test |
| TV4 | ứng dụng & reporting | `feature/tv4-web-reporting` | UI layout, dashboard, report/search, error UX, tài liệu demo | các view/report được gọi từ app, UX/validation, screenshots, README chạy, slide hỗ trợ |

## Backlog có owner rõ ràng

| ID | Việc | Owner | Phụ thuộc | Done khi |
|---|---|---|---|---|
| GYM-01 | Xác nhận tên nhóm, scope, glossary và ERD v1 | TV1 | — | cả nhóm duyệt PR thiết kế |
| GYM-02 | Tạo schema, seed dữ liệu và migration run-order | TV1 | GYM-01 | database dựng sạch thành công |
| GYM-03 | Login/role, security scripts và policy | TV1 | GYM-02 | 4 role + demo GRANT/REVOKE/DENY |
| GYM-04 | Scaffold web, cấu hình không lộ secret, CI/test template | TV1 | GYM-02 | app kết nối bằng cấu hình local |
| GYM-05 | Membership, plan, invoice, payment database logic | TV2 | GYM-02 | tests và 2 SP transaction pass |
| GYM-06 | UI CRUD membership/billing | TV2 | GYM-04, GYM-05 | thao tác thật qua SP |
| GYM-07 | Class/session/booking/check-in database logic | TV3 | GYM-02 | test capacity/trùng lịch pass |
| GYM-08 | UI vận hành lớp/check-in | TV3 | GYM-04, GYM-07 | thao tác thật qua SP |
| GYM-09 | Dashboard, search, report Views/Functions | TV4 | GYM-05, GYM-07 | 5+ view/FN dùng trong app |
| GYM-10 | UX validation, error/reconnect handling, screenshots | TV4 | GYM-04..09 | checklist UX pass |
| GYM-11 | Benchmark index, test rollback/concurrency/security | TV1 điều phối; TV2/TV3 thực hiện | GYM-05,07 | evidence lưu repo |
| GYM-12 | Báo cáo 50–100 trang, slide ≤15, rehearsal Q&A | TV1 điều phối; cả nhóm | tất cả | đủ artifact, mọi người demo được phần mình |

## Nhịp quản lý của TV1

- Đầu tuần: chốt mục tiêu tuần, giới hạn WIP 1 issue/người, xác nhận dependency.
- Giữa tuần: 15 phút blocker review; sự cố schema phải thông báo trước khi đổi contract.
- Cuối tuần: demo trên `develop`; leader đối chiếu `RUBRIC_COMPLIANCE.md`, ghi rủi ro và quyết định PR nào merge.
- Trước bảo vệ: freeze schema; chạy clean install + demo kịch bản 6 phút; từng thành viên trả lời chéo 3 câu về module khác.

## Trách nhiệm báo cáo và bảo vệ

TV1: Chương 1, kiến trúc app/Chương 5 phần nền tảng, Chương 4 security, tổng hợp. TV2: Chương 2–3 phần membership/billing. TV3: Chương 2–4 phần lớp/check-in/transaction/concurrency. TV4: Chương 5 UI/report/error handling, ảnh màn hình, slide. Tất cả review toàn báo cáo, ghi nguồn tham khảo và chuẩn bị phần hỏi đáp chung.

