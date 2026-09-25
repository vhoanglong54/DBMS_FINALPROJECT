# Evidence index

Chỉ lưu bằng chứng có thể đối chiếu với script/commit. Tên file: `GYM-XX_<loai>_<yyyy-mm-dd>.<ext>`.

- `database/`: clean install, smoke test, object counts.
- `security/`: GRANT/REVOKE/DENY và login theo role.
- `transactions/`: success/rollback của 5 transaction.
- `concurrency/`: hai session tranh chấp.
- `indexes/`: plan và STATISTICS IO/TIME trước/sau.
- `ui/`: màn hình thật kết nối SQL Server.

Không lưu password, connection string có secret hoặc dữ liệu cá nhân thật trong ảnh/log.
