# Bằng chứng concurrency — `sp_DatLop_DatCho` (TV3)

## Thiết lập

- Database bật `READ_COMMITTED_SNAPSHOT` (do `00_create_database.sql`), nên `sp_DatLop_DatCho` khóa dòng `LichLop` bằng `UPDLOCK, HOLDLOCK, ROWLOCK` trước khi đếm chỗ. Nếu không khóa tường minh thì hai session cùng đọc "còn chỗ" mà không chặn nhau.
- Buổi lớp demo có `Capacity = 1`.

## Các bước chạy

1. Session A: chạy khối 1–2 của `session_a_datlop.sql`, copy `SessionId` in ra.
2. Session A: điền `SessionId`, chạy khối 3 (đang `WAITFOR DELAY 20s`).
3. Session B: trong lúc A chờ, chạy `session_b_datlop.sql` với cùng `SessionId`.
4. Chờ A `COMMIT`, B trả kết quả.
5. Chạy `verify_result.sql`.

## Kết quả cần chụp vào `docs/evidence/concurrency/`

| # | Ảnh cần chụp | Nội dung phải thấy |
|---|---|---|
| 1 | Session A khi đang WAITFOR | Status = CONFIRMED, transaction chưa commit |
| 2 | Session B khi bị treo | Có dòng "Session B bắt đầu gọi" nhưng chưa có dòng kết quả |
| 3 | Session B sau khi A commit | Thời điểm kết quả trễ khoảng 20 giây so với lúc bắt đầu; Status = WAITLISTED |
| 4 | `verify_result.sql` | Đúng 1 CONFIRMED + 1 WAITLISTED, `fn_SoChoConLai` = 0 |
| 5 | (tuỳ chọn) `sys.dm_tran_locks` / Activity Monitor lúc B đang bị block | Thấy lock chờ trên `LichLop` |

## Lưu ý so với đặc tả ban đầu trong `tests/concurrency/README.md`

Đặc tả gốc ghi "B phải rollback/báo hết chỗ". Bản triển khai này cho B vào trạng thái `WAITLISTED` thay vì báo lỗi cứng (đúng với enum `WAITLISTED` đã có sẵn trong schema của TV1, và khi có người hủy thì `sp_DatLop_HuyCho` đôn người chờ lên). Cùng chứng minh một điều: không bao giờ có nhiều `CONFIRMED` hơn `Capacity`. Cần TV1 đồng ý sửa lại tiêu chí nghiệm thu. Nếu nhóm muốn báo lỗi cứng, chỉ cần thay dòng gán `@ResultStatus` trong `sp_DatLop_DatCho` bằng `THROW 52146, N'Buổi lớp đã đầy chỗ.', 1;` khi `@ConfirmedCount >= @Capacity`.

## Kịch bản ROLLBACK (bằng chứng phụ)

`10b_operations_smoke_tests.sql` chứa test trigger chống trùng lịch: trigger tự `ROLLBACK` toàn bộ transaction, smoke test xác nhận không còn dữ liệu `ZZ-TEST-*`. Chụp kết quả `ALL TV3 CLASS OPERATIONS SMOKE TESTS PASSED.` và truy vấn `SELECT COUNT(*) FROM dbo.HoiVien WHERE MemberCode LIKE 'ZZ-TEST-%'` = 0.
