# Index performance evidence

TV2/TV3 lưu query benchmark và kết quả `SET STATISTICS IO, TIME ON` tại đây. Với mỗi index:

- Nêu workload và lý do chọn cột/key/include.
- Chạy trên cùng bộ dữ liệu trước và sau index.
- Lưu logical reads, elapsed/CPU time và Actual Execution Plan.
- Kiểm tra index không trùng PK/UNIQUE và không làm chậm ghi vô lý.

Ảnh execution plan đặt tại `docs/evidence/indexes/`.
