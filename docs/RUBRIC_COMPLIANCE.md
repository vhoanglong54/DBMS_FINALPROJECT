# Ma trận tuân thủ rubric DBMS330284

Mỗi checkbox chỉ được đánh dấu khi script chạy mới được trên SQL Server và có bằng chứng/ảnh demo. Leader rà soát bảng này trước merge vào `main`.

| Tiêu chí rubric | Mức yêu cầu tốt/xuất sắc | Artifact cần nộp / kiểm tra | Owner |
|---|---|---|---|
| Thiết kế CSDL — 15% | ERD trực quan, 3NF, mô tả bảng chính xác; ≥8 bảng | `docs/ARCHITECTURE.md`, ERD, data dictionary, `01_schema.sql` | TV1 + cả nhóm review |
| Constraint/trigger/view/index — 15% | ≥5 mỗi loại, nghiệp vụ thực, có giải thích/chứng minh index | `02_constraints.sql` đến `05_indexes.sql`, `tests/index_evidence.sql` | TV2, TV3 |
| SP/function — 15% | ≥5 mỗi loại, `TRY...CATCH`, app dùng thật | `06_procedures.sql`, `07_functions.sql`, ảnh app gọi SP/FN | TV2, TV3, TV4 |
| Transaction & bảo mật — 10% | ≥5 transaction, demo lỗi/đồng thời, ≥4 role và GRANT/REVOKE/DENY | `08_security.sql`, `tests/concurrency/`, báo cáo Chương 4 | TV1 + TV2/TV3 |
| Ứng dụng SQL Server — 20% | cấu hình kết nối, login/role, CRUD, search/report, SP/FN, lỗi | `src/`, `appsettings.example.json`, test manual | TV4 + module owners |
| UX — 5% | nhất quán, dễ dùng, validate đầu vào | screenshots, checklist UX | TV4 |
| Báo cáo — 10% | 50–100 trang, đúng 6 chương, trích dẫn, minh họa | `docs/report/`, PDF cuối | TV1 điều phối + tất cả |
| Bảo vệ & teamwork — 10% | mỗi người nắm toàn hệ thống, demo thật, lịch sử Git rõ | `docs/TEAM_TASKS.md`, commits/PRs, `docs/presentation/` | TV1 + tất cả |

## Gate không được bỏ qua

- [ ] SQL Server khởi tạo sạch được từ script theo đúng thứ tự, seed demo thành công.
- [ ] Đếm thực tế: ≥8 tables; ≥5 constraints/triggers/views/indexes/SP/functions; ≥5 transactions; ≥4 roles/logins.
- [ ] App kết nối SQL Server thật trong máy demo và thao tác ghi gọi procedure.
- [ ] Có ảnh/kết quả cho query plan index, rollback transaction và concurrency.
- [ ] Báo cáo 50–100 trang (không tính bìa/mục lục/phụ lục); slide ≤15 trang.
- [ ] Backup `.bak` hoặc bộ script hoàn chỉnh, source, README chạy và lịch sử Git được đóng gói theo `Nhom_STT_TenDeTai`.

