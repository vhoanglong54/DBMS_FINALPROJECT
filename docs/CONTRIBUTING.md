# Quy tắc Git, code và quản trị thay đổi

## Nhánh và Issue

`main` chỉ chứa bản đã nghiệm thu. `develop` là nhánh tích hợp. Mọi thay đổi mới phải nằm trên task branch, không dùng nhánh dài hạn theo người.

Mỗi Issue có một owner, phạm vi, dependency, Definition of Done và một branch theo mẫu `feature/<issue-number>-gym-xx-short-name`, ví dụ `feature/12-gym-05-membership-billing-db`. Tiêu đề Issue bắt buộc theo mẫu `[GYM-XX][TVx] <mô tả ngắn>` để owner hiển thị ngay trong danh sách Issue; sau khi nhóm cung cấp GitHub username, TV1 cũng gán người đó vào trường `Assignees` của GitHub. Một branch chỉ giải quyết một Issue. Các nhánh `tv1`, `tv2`, `tv3`, `tv4` là lịch sử trước khi chuyển mô hình, không nhận công việc mới.

Không push trực tiếp vào `main`/`develop`. Owner được push vào task branch của Issue mình phụ trách. Chỉ TV1 được merge sau Pull Request (PR) có checklist xanh và tối thiểu một người review. Không force-push `main`, `develop` hoặc branch đã có PR review.

## Bắt đầu và cập nhật task

```powershell
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch -c feature/<issue-number>-gym-xx-short-name
```

Chỉ tạo task branch khi Issue đã ở trạng thái `Ready`. Khi `develop` thay đổi trong lúc thực hiện, owner phải rebase task branch trên `origin/develop` trước PR. Không mở hai Issue cùng sửa một SQL script hoặc cùng thay đổi một contract nếu chưa thống nhất owner.

Trước PR phải chạy bộ script SQL sạch, kiểm tra module app liên quan, cập nhật `docs/RUBRIC_COMPLIANCE.md`/tài liệu khi có thay đổi thiết kế, và tự review diff. Nếu conflict schema, TV1 là người quyết định bản chuẩn.

## Commit và Pull Request

- Commit nhỏ, một mục đích, dùng tiền tố: `feat(db):`, `fix(sql):`, `docs:`, `test:`, `chore:`.
- Mỗi Issue nêu owner, phạm vi, dependency, branch dự kiến và Definition of Done. Trạng thái đi theo `Backlog → Ready → In progress → In review → Done`.
- PR tiêu đề: `[GYM-XX][TVx] <mô tả ngắn>`; mô tả bắt đầu bằng `Closes #<issue-number>`, nêu bảng/script/API/UI ảnh hưởng, test đã chạy và yêu cầu rubric được cover.
- Không commit `.bak`, mật khẩu, connection string thật, `bin/obj`, ảnh không liên quan hoặc file build lớn.
- Mọi script thay đổi chạy lại được; tránh sửa tay database rồi quên commit script.
- Sau merge, TV1 đóng Issue, cập nhật `docs/HANDOFF_LOG.md` và xóa branch task trên remote.

## Quy tắc SQL Server

- Tên PascalCase tiếng Anh; bảng số ít (`HoiVien`), PK `<Bang>Id`, FK theo đúng tên cột; mọi FK có index khi phục vụ join phổ biến.
- Dùng schema `dbo`; `DECIMAL(18,2)` cho tiền, `DATETIME2` cho thời điểm, `NVARCHAR` cho tiếng Việt; không dùng `FLOAT` cho tiền.
- Không dùng `SELECT *`; procedure ghi phải có `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `TRY...CATCH` và transaction khi nhiều thay đổi phụ thuộc.
- Trigger xử lý tập bản ghi trong `inserted/deleted`, không giả định chỉ có một dòng, không ghi đệ quy không kiểm soát.
- Bất cứ cột nào được thêm/sửa phải được phản ánh tại ERD, data dictionary, seed, SP/view/app có liên quan.
- TV2 chỉ sửa script hậu tố `a_membership_*`; TV3 chỉ sửa hậu tố `b_operations_*`. TV4 chỉ thêm reporting view được owner dữ liệu đồng ý. TV1 quyết định thứ tự runner cuối.

## Quản trị leader (TV1)

TV1 tạo GitHub Issues theo các ID trong `docs/TEAM_TASKS.md`, giữ board `Backlog → Ready → In progress → In review → Done`, họp 15 phút mỗi tuần và cập nhật owner/trạng thái/rủi ro. TV1 tạo branch task từ `develop` sau khi Issue `Ready`, điều phối contract xuyên module và merge PR. Một task chỉ Done khi merge `develop`, test và bằng chứng rubric đã có.
