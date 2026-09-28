# Phân công và điều hành nhóm 4 người

Điền họ tên/MSSV trước khi nộp. Người là owner nghiệp vụ; branch là tài sản tạm thời của một Issue, không thuộc lâu dài bất kỳ thành viên nào.

| TV | Vai trò | Trách nhiệm chính | Deliverable / tiêu chí Done |
|---|---|---|---|
| TV1 - **Leader** | kiến trúc sư, tích hợp, bảo mật | data contract, user/role/employee, login nền tảng, security, CI/test, tích hợp và điều phối | schema chuẩn, 4+ role/login + GRANT/REVOKE/DENY, app foundation/login, checklist rubric, biên bản review |
| TV2 | membership & billing | hội viên/gói/đăng ký/hóa đơn/thanh toán, logic thu phí | CRUD + 2 transaction/SP, constraints/triggers/functions/views tương ứng, màn hình & test |
| TV3 | vận hành lớp & check-in | phòng/lớp/lịch/HLV/booking/check-in, concurrency | CRUD + 3 transaction/SP, trigger capacity/lịch, 2-session concurrency evidence, màn hình & test |
| TV4 | ứng dụng & reporting | UI layout, dashboard, report/search, error UX, tài liệu demo | các view/report được gọi từ app, UX/validation, screenshots, README chạy, slide hỗ trợ |

## Backlog có owner rõ ràng

Mỗi dòng dưới đây liên kết trực tiếp tới GitHub Issue tương ứng, là nguồn tiến độ chính thức. Tiêu đề Issue luôn theo mẫu `[GYM-XX][TVx] ...` để nhìn thấy ngay người nhận việc; body Issue lưu phạm vi, dependency, branch và Definition of Done. Khi một mục chuyển `Ready`, TV1 tạo GitHub Issue; số Issue được dùng trong tên branch. Owner đổi trạng thái `In progress` khi có commit đầu tiên. Một task chỉ `Done` sau khi PR merge vào `develop`.

| Issue | ID | Việc | Owner | Trạng thái | Dependency | Nhánh task khi Ready | Done khi |
|---|---|---|---|---|---|---|---|
| [#1](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/1) | GYM-01 | Xác nhận tên nhóm, scope, glossary và ERD v1 | TV1 | Done | - | - | cả nhóm duyệt PR thiết kế |
| [#2](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/2) | GYM-02 | Tạo schema, seed dữ liệu và migration run-order | TV1 | Done | GYM-01 | - | database dựng sạch thành công |
| [#3](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/3) | GYM-03 | Login/role, security scripts và policy | TV1 | Done | GYM-02 | - | 4 role + demo GRANT/REVOKE/DENY |
| [#4](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/4) | GYM-04 | Scaffold web, cấu hình không lộ secret, CI/test template | TV1 | Done | GYM-02 | - | app kết nối bằng cấu hình local |
| [#5](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/5) | GYM-05 | Membership, plan, invoice, payment database logic | TV2 | In progress | GYM-02 | `feature/5-gym-05-membership-billing-db` | tests và 2 SP transaction pass |
| [#6](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/6) | GYM-06 | UI CRUD membership/billing | TV2 | Backlog | GYM-04, GYM-05 | `feature/<issue>-gym-06-membership-billing-ui` | thao tác thật qua SP |
| [#7](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/7) | GYM-07 | Class/session/booking/check-in database logic | TV3 | Ready | GYM-02 | `feature/7-gym-07-classes-booking-checkin-db` | test capacity/trùng lịch pass |
| [#8](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/8) | GYM-08 | UI vận hành lớp/check-in | TV3 | Backlog | GYM-04, GYM-07 | `feature/<issue>-gym-08-operations-ui` | thao tác thật qua SP |
| [#9](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/9) | GYM-09 | Dashboard, search, report Views/Functions | TV4 | Backlog | GYM-05, GYM-07 | `feature/<issue>-gym-09-dashboard-reporting` | 5+ view/FN dùng trong app |
| [#10](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/10) | GYM-10 | UX validation, error/reconnect handling, screenshots | TV4 | Backlog | GYM-04..09 | `feature/<issue>-gym-10-ux-evidence` | checklist UX pass |
| [#11](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/11) | GYM-11 | Benchmark index, test rollback/concurrency/security | TV1 điều phối; TV2/TV3 thực hiện | Backlog | GYM-05, GYM-07 | `feature/<issue>-gym-11-verification` | evidence lưu repo |
| [#12](https://github.com/vhoanglong54/DBMS_FINALPROJECT/issues/12) | GYM-12 | Báo cáo 50-100 trang, slide <=15, rehearsal Q&A | TV1 điều phối; cả nhóm | Backlog | tất cả | `feature/<issue>-gym-12-delivery` | đủ artifact, mọi người demo được phần mình |

## Thứ tự thực hiện và cổng duyệt

Không triển khai theo số Issue một cách máy móc; triển khai theo dependency. Một Issue chỉ được TV1 chuyển sang `Ready` sau khi tất cả dependency trong bảng là `Done` trên `develop`, scope/DoD đã rõ và owner còn dưới giới hạn một Issue `In progress`.

| Giai đoạn | Issue được phép làm song song | Cổng để chuyển sang giai đoạn sau |
|---|---|---|
| Nền tảng | #1, #2, #3, #4 | Đã xong: schema baseline, bảo mật và app foundation đã ở `develop`. |
| Logic nghiệp vụ | #5 (TV2) và #7 (TV3) | Mỗi Issue có PR merge, smoke test SQL và test transaction/capacity đạt. |
| UI vận hành | #6 (TV2) sau #5; #8 (TV3) sau #7 | UI gọi dữ liệu thật qua procedure/query đã review, không dùng dữ liệu giả. |
| Báo cáo và trải nghiệm | #9 (TV4) sau #5 + #7; #10 (TV4) sau các màn hình liên quan | View/function/report chạy trên schema đã merge; UX và ảnh minh chứng đạt checklist. |
| Xác minh tích hợp | #11 (TV1 điều phối, TV2/TV3 thực hiện) sau #5 + #7 | Bằng chứng rollback, concurrency, security và index có thể chạy lại. |
| Bàn giao | #12 (cả nhóm) sau #6, #8, #9, #10, #11 | Freeze schema, artifact đủ, rehearsal/demo đạt. |

### Quyết định `Ready`, `In review`, `Done`

- **TV1 chuyển sang `Ready`:** kiểm dependency đã merge vào `develop`, xác định owner và reviewer dự kiến, xác nhận không đụng script/contract đang bị Issue khác khóa.
- **Owner chuyển sang `In progress`:** sau commit đầu tiên trên task branch và ghi link branch vào Issue.
- **TV1 chuyển sang `In review`:** owner đã mở PR vào `develop`, điền đầy đủ checklist test/rubric và không còn scope mới.
- **TV1 xác nhận `Done`:** PR được merge, CI/test đạt, `Closes #...` đã đóng Issue và log bàn giao được cập nhật.

Trạng thái hiện tại: #1–#4 đã `Done`; #5 là `In progress` của TV2; #7 là `Ready` của TV3. Các Issue còn lại giữ `Backlog`, không có branch và chưa được phép bắt đầu.

## Quy tắc cập nhật tiến độ

- Mỗi người chỉ có một Issue `In progress` tại một thời điểm.
- Khi bị blocker do dependency hoặc contract, owner ghi ngay vào Issue và không tự đổi schema/script thuộc module của người khác.
- Mọi thay đổi đã merge phải được phản ánh vào trạng thái trong bảng này, GitHub Issue và `HANDOFF_LOG.md`.
- Không có PR, CI/test và approval thì không được đánh dấu `Done`.
- Chỉ sau #6, #8, #9, #10 và #11 đều `Done` mới freeze schema và bắt đầu #12.

## Trách nhiệm báo cáo và bảo vệ

TV1: Chương 1, kiến trúc app/Chương 5 phần nền tảng, Chương 4 security, tổng hợp. TV2: Chương 2-3 phần membership/billing. TV3: Chương 2-4 phần lớp/check-in/transaction/concurrency. TV4: Chương 5 UI/report/error handling, ảnh màn hình, slide. Tất cả review toàn báo cáo, ghi nguồn tham khảo và chuẩn bị phần hỏi đáp chung.
