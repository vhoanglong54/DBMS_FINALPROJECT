# SQL Server scripts

TV1 sẽ tạo các file theo thứ tự dưới đây; mọi file cần idempotent hoặc có hướng dẫn chạy trên database mới.

```text
00_create_database.sql
01_schema.sql
02_constraints.sql
03_triggers.sql
04_views.sql
05_indexes.sql
06_procedures.sql
07_functions.sql
08_security.sql
09_seed_demo.sql
10_smoke_tests.sql
```

Không ghi password thật vào script. Script security dùng login demo cục bộ hoặc biến placeholder có hướng dẫn rõ ràng.

