# Concurrency evidence

TV3 đặt script hai session cho `sp_DatLop` tại đây. Bằng chứng bắt buộc:

1. Seed một lịch còn đúng một chỗ.
2. Session A giữ transaction sau khi khóa lịch.
3. Session B gọi đặt chỗ cho hội viên khác.
4. Sau khi A commit, B phải rollback/báo hết chỗ.
5. Query cuối chứng minh booking `CONFIRMED` không vượt capacity.

Đính kèm script A/B, kết quả và ảnh SSMS vào `docs/evidence/concurrency/`.
