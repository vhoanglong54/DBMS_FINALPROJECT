# Quy tắc Git, code và quản trị thay đổi

## Nhánh và Issue

`main` chỉ chứa bản đã nghiệm thu. `develop` là nhánh tích hợp. Mọi thay đổi mới phải nằm trên task branch, không dùng nhánh dài hạn theo người.

Mỗi Issue có một owner, phạm vi, dependency, Definition of Done và một branch theo mẫu `feature/<issue-number>-gym-xx-short-name`, ví dụ `feature/12-gym-05-membership-billing-db`. Tiêu đề Issue bắt buộc theo mẫu `[GYM-XX][TVx] <mô tả ngắn>` để owner hiển thị ngay trong danh sách Issue; sau khi nhóm cung cấp GitHub username, TV1 cũng gán người đó vào trường `Assignees` của GitHub. Một branch chỉ giải quyết một Issue. Các nhánh `tv1`, `tv2`, `tv3`, `tv4` là lịch sử trước khi chuyển mô hình, không nhận công việc mới.

Tạo Issue bằng mẫu `.github/ISSUE_TEMPLATE/task.md` và PR bằng `.github/pull_request_template.md`; không xóa checklist, chỉ đánh dấu sau khi đã kiểm chứng.

Không push trực tiếp vào `main`/`develop`. Owner được push vào task branch của Issue mình phụ trách. Chỉ TV1 được merge sau Pull Request (PR) có checklist xanh và tối thiểu một người review. Không force-push `main`, `develop` hoặc branch đã có PR review.

### Khi nào tạo branch

Không tạo trước branch cho mọi Issue. Branch tồn tại lâu khi Issue còn phụ thuộc sẽ nhanh cũ, khó rebase và tạo cảm giác task đã được bắt đầu dù chưa có người làm. Quy ước bắt buộc:

| Trạng thái Issue | Có branch? | Hành động |
|---|---|---|
| `Backlog` | Không | Scope có thể thay đổi; chưa được phép code. |
| `Ready` | Có, do owner tạo từ `origin/develop` mới nhất | Dependency đã đạt, owner xác nhận bắt đầu. |
| `In progress` | Có | Commit và push chỉ vào branch của Issue đó. |
| `In review` | Có PR vào `develop` | Chỉ sửa theo review; không thêm scope mới. |
| `Done` | Không | PR đã merge, Issue đã đóng, TV1 xóa remote branch. |

Tại thời điểm ban hành quy tắc này, chỉ `feature/5-gym-05-membership-billing-db` (Issue #5, TV2, đang làm) và `feature/7-gym-07-classes-booking-checkin-db` (Issue #7, TV3, Ready) được tồn tại. Không tạo nhánh cho #6, #8–#12 cho đến khi TV1 chuyển Issue đó sang `Ready`.

## Bắt đầu và cập nhật task

```powershell
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch -c feature/<issue-number>-gym-xx-short-name
```

Trước khi tạo branch, owner kiểm tra Issue có đủ: title đúng mẫu, owner, scope không mơ hồ, dependency đã `Done`, Definition of Done, đường dẫn/script sẽ sửa và tiêu chí test. TV1 chuyển Issue `Backlog` sang `Ready` khi các điều kiện này đạt; đây là cổng duyệt bắt đầu, không phải chỉ đổi nhãn hình thức.

Chỉ tạo task branch khi Issue đã ở trạng thái `Ready`. Sau commit đầu tiên, owner đổi Issue thành `In progress` và thêm link branch/PR. Khi `develop` thay đổi trong lúc thực hiện, owner rebase task branch trên `origin/develop` **trước khi mở PR**. Sau khi PR đã được review, không force-push; nếu cần đồng bộ `develop`, merge `origin/develop` vào task branch và ghi một comment trên PR. Không mở hai Issue cùng sửa một SQL script hoặc cùng thay đổi một contract nếu chưa thống nhất owner.

Trước PR phải chạy bộ script SQL sạch, kiểm tra module app liên quan, cập nhật `docs/RUBRIC_COMPLIANCE.md`/tài liệu khi có thay đổi thiết kế, và tự review diff. Nếu conflict schema, TV1 là người quyết định bản chuẩn.

## Commit

- Mỗi commit chỉ chứa một thay đổi có thể giải thích và review độc lập: một migration/SP, một màn hình, một test, hoặc một sửa lỗi. Không trộn format toàn repo, file sinh tự động hay refactor không liên quan vào commit tính năng.
- Cú pháp: `<type>(<scope>): <mô tả mệnh lệnh, ngắn>`; type chỉ dùng `feat`, `fix`, `test`, `docs`, `chore`, `refactor`. Scope chuẩn: `db`, `app`, `security`, `ci`, `docs`. Ví dụ: `feat(db): add payment posting procedure`, `test(app): cover expired membership`, `fix(sql): reject duplicate booking`.
- Commit đầu tiên của một Issue hoặc PR description phải tham chiếu `#<issue-number>`; không dùng `Closes #...` trong commit thường. Chỉ PR cuối mới dùng `Closes #...` để GitHub đóng Issue sau merge.
- Commit phải giữ repository ở trạng thái build/test được theo phần công việc đã thay đổi. Nếu một thay đổi cần SQL và app cùng tồn tại, commit theo thứ tự contract/migration -> data access -> UI -> test, và giải thích dependency trong PR.
- Không commit `.bak`, mật khẩu, connection string thật, `bin/obj`, `__pycache__`, file build lớn, dữ liệu local, hay ảnh không phải bằng chứng rubric.
- Mọi script thay đổi chạy lại được; không sửa tay database rồi quên commit script.

## Pull Request và duyệt

1. Owner mở draft PR sớm khi đã có lát cắt chạy được; PR base luôn là `develop`, head là branch của chính Issue. Đổi Issue sang `In review` chỉ khi scope đã hoàn chỉnh.
2. PR tiêu đề là `[GYM-XX][TVx] <mô tả ngắn>`. Phần đầu mô tả phải là `Closes #<issue-number>`, tiếp theo là: thay đổi chính, bảng/cột/SP/View/API/UI ảnh hưởng, migration/run order, test đã chạy, bằng chứng rubric, rủi ro/rollback.
3. Trước khi xin review, owner tự kiểm: `git diff origin/develop...HEAD`, không conflict, không file cấm, CI xanh; chạy clean SQL runner cho thay đổi database và test/build module app liên quan.
4. Reviewer phải là người khác author. Reviewer kiểm scope Issue, contract, quyền/security, test và khả năng rollback; comment `Approve` chỉ khi checklist đầy đủ. PR của TV1 bắt buộc do TV2/TV3/TV4 review; TV1 không tự approve PR của mình.
5. TV1 chỉ merge khi CI xanh, có ít nhất một approval và không có comment unresolved. Dùng squash merge nếu commit nhỏ/không cần giữ lịch sử nội bộ; dùng merge commit khi cần giữ chuỗi migration rõ ràng. Không rebase/force-push một PR đã được duyệt.
6. Sau merge: GitHub đóng Issue bằng `Closes #...`; TV1 xác nhận `develop`, cập nhật `TEAM_TASKS.md` và `HANDOFF_LOG.md`, rồi xóa remote branch. Lỗi sau merge mở Issue mới, không reopen/sửa lén Issue đã Done.

## Quy tắc SQL Server

- Tên PascalCase tiếng Anh; bảng số ít (`HoiVien`), PK `<Bang>Id`, FK theo đúng tên cột; mọi FK có index khi phục vụ join phổ biến.
- Dùng schema `dbo`; `DECIMAL(18,2)` cho tiền, `DATETIME2` cho thời điểm, `NVARCHAR` cho tiếng Việt; không dùng `FLOAT` cho tiền.
- Không dùng `SELECT *`; procedure ghi phải có `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `TRY...CATCH` và transaction khi nhiều thay đổi phụ thuộc.
- Trigger xử lý tập bản ghi trong `inserted/deleted`, không giả định chỉ có một dòng, không ghi đệ quy không kiểm soát.
- Bất cứ cột nào được thêm/sửa phải được phản ánh tại ERD, data dictionary, seed, SP/view/app có liên quan.
- TV2 chỉ sửa script hậu tố `a_membership_*`; TV3 chỉ sửa hậu tố `b_operations_*`. TV4 chỉ thêm reporting view được owner dữ liệu đồng ý. TV1 quyết định thứ tự runner cuối.

## Quản trị leader (TV1)

TV1 tạo GitHub Issues theo các ID trong `docs/TEAM_TASKS.md`, giữ board `Backlog → Ready → In progress → In review → Done`, họp 15 phút mỗi tuần và cập nhật owner/trạng thái/rủi ro. TV1 tạo branch task từ `develop` sau khi Issue `Ready`, điều phối contract xuyên module và merge PR. Một task chỉ Done khi merge `develop`, test và bằng chứng rubric đã có.
