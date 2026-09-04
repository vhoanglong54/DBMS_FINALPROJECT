# Quy tắc Git, code và quản trị thay đổi

## Nhánh

`main` chỉ chứa bản đã nghiệm thu. `develop` là nhánh tích hợp. Mỗi người chỉ làm trực tiếp trên nhánh được giao: `feature/tv1-leader-core-security`, `feature/tv2-membership-billing`, `feature/tv3-classes-checkin`, `feature/tv4-web-reporting`.

Không push trực tiếp vào `main`/`develop`. Chỉ TV1 được merge sau Pull Request (PR) có checklist xanh và tối thiểu một người review. Không force-push nhánh dùng chung.

## Trước khi bắt đầu và trước PR

```powershell
git switch feature/<nhanh-cua-ban>
git pull origin feature/<nhanh-cua-ban>
git fetch origin
git rebase origin/develop
```

Trước PR phải chạy bộ script SQL sạch, kiểm tra module app liên quan, cập nhật `docs/RUBRIC_COMPLIANCE.md`/tài liệu khi có thay đổi thiết kế, và tự review diff. Nếu conflict schema, TV1 là người quyết định bản chuẩn.

## Commit và Pull Request

- Commit nhỏ, một mục đích, dùng tiền tố: `feat(db):`, `fix(sql):`, `docs:`, `test:`, `chore:`.
- Ví dụ: `feat(db): add transactional class booking procedure`.
- PR tiêu đề: `[TVx] <mô tả ngắn>`; mô tả nêu bảng/script/API/UI ảnh hưởng, test đã chạy và yêu cầu rubric được cover.
- Không commit `.bak`, mật khẩu, connection string thật, `bin/obj`, ảnh không liên quan hoặc file build lớn.
- Mọi script thay đổi chạy lại được; tránh sửa tay database rồi quên commit script.

## Quy tắc SQL Server

- Tên PascalCase tiếng Anh; bảng số ít (`HoiVien`), PK `<Bang>Id`, FK theo đúng tên cột; mọi FK có index khi phục vụ join phổ biến.
- Dùng schema `dbo`; `DECIMAL(18,2)` cho tiền, `DATETIME2` cho thời điểm, `NVARCHAR` cho tiếng Việt; không dùng `FLOAT` cho tiền.
- Không dùng `SELECT *`; procedure ghi phải có `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `TRY...CATCH` và transaction khi nhiều thay đổi phụ thuộc.
- Trigger xử lý tập bản ghi trong `inserted/deleted`, không giả định chỉ có một dòng, không ghi đệ quy không kiểm soát.
- Bất cứ cột nào được thêm/sửa phải được phản ánh tại ERD, data dictionary, seed, SP/view/app có liên quan.

## Quản trị leader (TV1)

TV1 tạo GitHub Issues theo các ID trong `docs/TEAM_TASKS.md`, board `Backlog → In progress → Review → Done`, họp 15 phút mỗi tuần và cập nhật owner/trạng thái/rủi ro. PR phải liên kết issue; một task chỉ Done khi merge `develop`, test và bằng chứng rubric đã có.

