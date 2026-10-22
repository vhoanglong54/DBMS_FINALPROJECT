# Ma trận tuân thủ rubric DBMS330284

Đối chiếu theo rubric tại `docs/HuongDan_Project_Rubric_DBMS330284.docx.pdf`. Kết quả kỹ thuật và ảnh bằng chứng được chạy ngày 11/10/2026 trên SQL Server Express; chi tiết ở `docs/TEST_EVIDENCE.md` và `tools/ssms-evidence/`.

| Tiêu chí | Hiện trạng | Bằng chứng |
|---|---|---|
| Thiết kế CSDL — 15% | Đạt: ERD, 3NF, 15 bảng, 19 FK, data dictionary | `ARCHITECTURE.md`, `DATA_DICTIONARY.md`, `01_schema.sql` |
| Constraint/trigger/view/index — 15% | Đạt: 43 CHECK, 6 trigger, 9 view, 20 non-PK index; benchmark mới nhất 16→6 reads | `02*`–`05*`, `tests/index/`, `TEST_EVIDENCE.md` |
| SP/function — 15% | Đạt: 44 procedure, 9 function; ứng dụng gọi procedure thật | `06*`, `07*`, `08_security.sql`, `src/GymManagement.Web/Data/` |
| Transaction & security — 10% | Đạt: 17 procedure transaction+TRY/CATCH, rollback PASS, concurrency PASS, 5 role, GRANT/DENY/REVOKE | `08*`, `10c`, `tests/sql/`, `tests/concurrency/` |
| Ứng dụng SQL Server — 20% | Đạt: login/RBAC, cấp tài khoản nhân viên, CRUD chính, billing, booking, check-in, search và report | `src/`; HTTP/SQL E2E trong `TEST_EVIDENCE.md` |
| UX — 5% | Đạt: giao diện responsive theo chủ đề gym, điều hướng active theo vai trò, focus/contrast rõ, validation, anti-forgery, trạng thái tiếng Việt, thông báo lỗi và health check | Razor views, `site.css`, `reporting.css`, `/health`, ảnh chụp thật |
| Báo cáo — 10% | Đạt artifact: Word 57 trang, Times New Roman 13, giãn dòng 1.5, mục lục/danh mục có số trang thật, 6 chương đúng cấu trúc, 11 ảnh CSDL chụp trực tiếp trong SSMS và cắt đúng vùng bằng chứng, 6 ảnh ứng dụng, tài liệu tham khảo IEEE, phụ lục phân công/source chính | `deliverables/HeThongQuanLyPhongGym_Report.docx`, `deliverables/assets/ssms-*` |
| Bảo vệ & teamwork — 10% | Slide 15 trang và lịch sử Git có đủ đóng góp; việc trình bày của từng thành viên cần rehearsal | `deliverables/*Slides.pptx`, Git history |

## Gate cuối

- [x] SQL Server khởi tạo sạch bằng một runner, seed và toàn bộ smoke test thành công.
- [x] Đủ ≥8 table; ≥5 constraint/trigger/view/index/procedure/function; ≥5 transaction; ≥4 role.
- [x] Ứng dụng kết nối SQL Server thật; luồng ghi end-to-end gọi stored procedure thành công.
- [x] Có kết quả rollback, security, concurrency và benchmark index.
- [x] Báo cáo Word 50–100 trang theo cấu trúc 6 chương; slide không quá 15 trang.
- [x] Có bộ script hoàn chỉnh, source, README chạy và lịch sử Git.
- [x] Artifact công khai không chứa thông tin định danh cá nhân; các trường tên trường, giảng viên, họ tên và MSSV trên bìa/phụ lục được để trống có chủ ý để người nộp điền trước khi in.
