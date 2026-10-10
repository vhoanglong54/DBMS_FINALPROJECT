# Ma trận tuân thủ rubric DBMS330284

Đối chiếu theo rubric tại `docs/HuongDan_Project_Rubric_DBMS330284.docx.pdf`. Kết quả kỹ thuật được chạy ngày 10/10/2026 trên SQL Server Express; chi tiết ở `docs/TEST_EVIDENCE.md`.

| Tiêu chí | Hiện trạng | Bằng chứng |
|---|---|---|
| Thiết kế CSDL — 15% | Đạt: ERD, 3NF, 15 bảng, 19 FK, data dictionary | `ARCHITECTURE.md`, `DATA_DICTIONARY.md`, `01_schema.sql` |
| Constraint/trigger/view/index — 15% | Đạt: 43 CHECK, 6 trigger, 9 view, 20 non-PK index; benchmark mới nhất 16→6 reads | `02*`–`05*`, `tests/index/`, `TEST_EVIDENCE.md` |
| SP/function — 15% | Đạt: 42 procedure, 9 function; ứng dụng gọi procedure thật | `06*`, `07*`, `src/GymManagement.Web/Data/` |
| Transaction & security — 10% | Đạt: 16 procedure transaction+TRY/CATCH, rollback PASS, concurrency PASS, 5 role, GRANT/DENY/REVOKE | `08*`, `10c`, `tests/sql/`, `tests/concurrency/` |
| Ứng dụng SQL Server — 20% | Đạt: login/RBAC, CRUD chính, billing, booking, check-in, search và report | `src/`; HTTP/SQL E2E trong `TEST_EVIDENCE.md` |
| UX — 5% | Đạt: giao diện responsive theo chủ đề gym, điều hướng active theo vai trò, focus/contrast rõ, validation, anti-forgery, trạng thái tiếng Việt, thông báo lỗi và health check | Razor views, `site.css`, `reporting.css`, `/health`, ảnh chụp thật |
| Báo cáo — 10% | Đạt artifact: Word Times New Roman 13, giãn dòng 1.5, 58 page break, 6 chương đúng cấu trúc và 8 hình minh họa thật | `deliverables/HeThongQuanLyPhongGym_Report.docx` |
| Bảo vệ & teamwork — 10% | Slide 15 trang và lịch sử Git có đủ đóng góp; việc trình bày của từng thành viên cần rehearsal | `deliverables/*Slides.pptx`, Git history |

## Gate cuối

- [x] SQL Server khởi tạo sạch bằng một runner, seed và toàn bộ smoke test thành công.
- [x] Đủ ≥8 table; ≥5 constraint/trigger/view/index/procedure/function; ≥5 transaction; ≥4 role.
- [x] Ứng dụng kết nối SQL Server thật; luồng ghi end-to-end gọi stored procedure thành công.
- [x] Có kết quả rollback, security, concurrency và benchmark index.
- [x] Báo cáo Word 50–100 trang theo cấu trúc 6 chương; slide không quá 15 trang.
- [x] Có bộ script hoàn chỉnh, source, README chạy và lịch sử Git.
- [x] Artifact công khai trong repository không chứa placeholder hoặc thông tin định danh cá nhân.
