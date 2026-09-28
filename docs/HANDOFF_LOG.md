# Handoff log

Không sửa/xóa entry cũ. Sau mỗi task, thêm entry mới lên đầu phần “Nhật ký” theo UTC+7 và ghi rõ người nhận bàn giao.

## Mẫu

```markdown
### YYYY-MM-DD HH:mm — GYM-XX: Tên task
- Người thực hiện: TVx / Họ tên
- Trạng thái: Done | Partial | Blocked
- Thay đổi: ...
- Contract ảnh hưởng: bảng/cột/SP/View/Function/API hoặc `Không`
- Kiểm thử: lệnh/kịch bản + kết quả
- Bằng chứng rubric: đường dẫn file/ảnh
- Bàn giao cho: TVx
- Việc tiếp theo/rủi ro: ...
```

## Nhật ký

### 2026-09-28 — GYM-12: Chuyển sang task branch theo Issue

- Người thực hiện: TV1 / Leader
- Trạng thái: Done
- Thay đổi: thay quy ước nhánh theo người bằng task branch theo Issue; cập nhật README, rule Git, bảng phân công và CI.
- Contract ảnh hưởng: Không.
- Kiểm thử: kiểm tra mỗi nhánh cũ không khác nội dung so với `develop`; kiểm tra cấu hình workflow nhận nhánh `feature/**`.
- Bằng chứng rubric: `docs/CONTRIBUTING.md`, `docs/TEAM_TASKS.md`, `.github/workflows/build-and-test.yml`.
- Bàn giao cho: TV2 (GYM-05), TV3 (GYM-07).
- Việc tiếp theo/rủi ro: tạo Issue GitHub và task branch từ `develop`; cần GitHub username thật của TV2/TV3 trước khi gán assignee trên GitHub.

### 2026-09-25 — GYM-01/02/03/04: Core, security và application foundation

- Người thực hiện: TV1 / Leader
- Trạng thái: Done
- Thay đổi: contract 15 bảng; security roles và auth procedures; seed/smoke runner; ASP.NET Core MVC login/authorization; CI và test.
- Contract ảnh hưởng: baseline v1.0 được freeze tại `docs/DATA_DICTIONARY.md`.
- Kiểm thử: SQL smoke pass (15 tables, 38 CHECK, 19 FK); Release build 0 warning/error; 8/8 unit tests; health/login end-to-end pass.
- Bằng chứng rubric: `database/01_schema.sql`, `database/08_security.sql`, `database/09_seed_demo.sql`, `database/10_smoke_tests.sql`, `src/`.
- Bàn giao cho: TV2, TV3, TV4.
- Việc tiếp theo/rủi ro: các module owner phải bổ sung trigger/view/index/SP/function và không đổi schema nền khi chưa review.
