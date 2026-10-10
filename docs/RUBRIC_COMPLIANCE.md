# Ma trận tuân thủ rubric DBMS330284

Đối chiếu theo rubric tại `docs/HuongDan_Project_Rubric_DBMS330284.docx.pdf`. Kết quả kỹ thuật được chạy ngày 10/10/2026 trên SQL Server Express; chi tiết ở `docs/TEST_EVIDENCE.md`.

| Tiêu chí | Hiện trạng | Bằng chứng |
|---|---|---|
| Thiết kế CSDL — 15% | Đạt: ERD, 3NF, 15 bảng, 19 FK, data dictionary | `ARCHITECTURE.md`, `DATA_DICTIONARY.md`, `01_schema.sql` |
| Constraint/trigger/view/index — 15% | Đạt: 43 CHECK, 6 trigger, 9 view, 20 non-PK index; benchmark 18→3 reads | `02*`–`05*`, `tests/index/`, `TEST_EVIDENCE.md` |
| SP/function — 15% | Đạt: 42 procedure, 9 function; ứng dụng gọi procedure thật | `06*`, `07*`, `src/GymManagement.Web/Data/` |
| Transaction & security — 10% | Đạt: 16 procedure transaction+TRY/CATCH, rollback PASS, concurrency PASS, 5 role, GRANT/DENY/REVOKE | `08*`, `10c`, `tests/sql/`, `tests/concurrency/` |
| Ứng dụng SQL Server — 20% | Đạt: login/RBAC, CRUD chính, billing, booking, check-in, search và report | `src/`; HTTP/SQL E2E trong `TEST_EVIDENCE.md` |
| UX — 5% | Đạt kỹ thuật: responsive, validation, anti-forgery, thông báo lỗi, health check | Razor views, `site.css`, `/health` |
| Báo cáo — 10% | Đạt artifact: Word Times New Roman 13, giãn dòng 1.5, 59 page break, 6 chương đúng cấu trúc và 8 hình minh họa thật | `deliverables/NhomXX_HeThongQuanLyPhongGym_Report.docx` |
| Bảo vệ & teamwork — 10% | Slide 15 trang và lịch sử Git có đủ đóng góp; việc trình bày của từng thành viên cần rehearsal | `deliverables/*Slides.pptx`, Git history |

## Gate cuối

- [x] SQL Server khởi tạo sạch bằng một runner, seed và toàn bộ smoke test thành công.
- [x] Đủ ≥8 table; ≥5 constraint/trigger/view/index/procedure/function; ≥5 transaction; ≥4 role.
- [x] Ứng dụng kết nối SQL Server thật; luồng ghi end-to-end gọi stored procedure thành công.
- [x] Có kết quả rollback, security, concurrency và benchmark index.
- [x] Báo cáo Word 50–100 trang theo cấu trúc 6 chương; slide không quá 15 trang.
- [x] Có bộ script hoàn chỉnh, source, README chạy và lịch sử Git.
- [ ] Trước khi nộp: thay `NhomXX`, điền họ tên/MSSV/giảng viên và đổi tên gói nộp theo `Nhom_STT_TenDeTai`.
- [ ] Cả bốn thành viên rehearsal và xác nhận có mặt trong buổi bảo vệ.

Hai dòng cuối cần thông tin/hành động của nhóm, không thể suy ra từ source code.
