# Biên bản nghiệm thu phần TV1

## Đã hoàn thành

- GYM-01: scope, ERD, glossary, state machine và data dictionary v1.0.
- GYM-02: database có thể dựng sạch bằng runner; 15 bảng, seed xuyên module, smoke test.
- GYM-03: 5 database role (4 role rubric + service role), GRANT/REVOKE/DENY, tùy chọn 4 SQL Login không hard-code password.
- GYM-04: ASP.NET Core MVC .NET 8, ADO.NET `Microsoft.Data.SqlClient`, PBKDF2, cookie auth, role policy, lockout và health check.
- GYM-11 phần TV1: CI build/test, unit tests auth, SQL contract check và quy ước evidence. Benchmark/concurrency nghiệp vụ tiếp tục do TV2/TV3 cung cấp.
- GYM-12 phần khởi tạo: phân công, PR template, CODEOWNERS, branch rules, handoff log và checklist rubric. Báo cáo/slide cuối kỳ là trách nhiệm liên tục đến khi project kết thúc.

## Bằng chứng chạy ngày 25/09/2026

| Hạng mục | Kết quả |
|---|---|
| SQL Server | SQL Server 2022 Express |
| Clean database | `GymManagementDB_TV1Test2` |
| Schema smoke test | 15 tables, 38 CHECK, 19 FK, 4 demo users |
| Build | Release, 0 warning, 0 error |
| Unit test | 8/8 pass |
| Health check | HTTP 200 `Healthy` |
| Login end-to-end | `admin` xác thực thành công, dashboard có role `ADMIN` |

## Việc chưa được phép đánh dấu hoàn thành toàn dự án

Trigger/view/index/SP/function nghiệp vụ, 5 transaction, benchmark index và concurrency phụ thuộc TV2/TV3/TV4. TV1 chỉ đóng các issue này sau khi review evidence và merge vào `develop`.
