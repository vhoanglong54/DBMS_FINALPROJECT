# Handoff log — tv2

Không sửa/xóa entry cũ. Sau mỗi task, thêm entry mới lên đầu phần “Nhật ký” theo UTC+7.

## Mẫu

```markdown
### YYYY-MM-DD HH:mm — GYM-XX: Tên task
- Người thực hiện: TV2 / Họ tên
- Trạng thái: Done | Partial | Blocked
- Thay đổi: ...
- Contract ảnh hưởng: bảng/cột/SP/View/Function hoặc `Không`
- Kiểm thử: lệnh/kịch bản + kết quả
- Bằng chứng rubric: đường dẫn file/ảnh
- Bàn giao cho: TVx
- Việc tiếp theo/rủi ro: ...
```

## Nhật ký

### 2026-09-25 — Khởi tạo quy trình nhánh

- Người thực hiện: TV1 / Leader
- Trạng thái: Done
- Thay đổi: tạo rule và mẫu handoff cho module membership/billing.
- Contract ảnh hưởng: Không.
- Kiểm thử: Không áp dụng.
- Bằng chứng rubric: `TASK.md`, `BRANCH_RULES.md`.
- Bàn giao cho: TV2.
- Việc tiếp theo/rủi ro: TV2 đọc contract từ nhánh TV1/develop sau khi PR TV1 được merge; không tự sửa schema nền.
