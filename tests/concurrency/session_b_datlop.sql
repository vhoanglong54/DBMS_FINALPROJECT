/*
    SESSION B - cửa sổ SSMS thứ hai. Chạy TRONG LÚC Session A đang WAITFOR DELAY.
*/

USE [GymManagementDB]; -- đổi tên database cho đúng máy demo
GO

DECLARE @DemoSessionId bigint = 0; -- <-- sửa số 0 thành SessionId giống Session A
DECLARE @Member2 int, @Booking2 bigint, @Status2 varchar(20);

SELECT @Member2 = MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0002';

PRINT CONCAT(N'Session B bắt đầu gọi lúc ', CONVERT(varchar(30), SYSUTCDATETIME(), 121));

EXEC dbo.sp_DatLop_DatCho
    @MemberId = @Member2, @SessionId = @DemoSessionId,
    @NewBookingId = @Booking2 OUTPUT, @ResultStatus = @Status2 OUTPUT;

PRINT CONCAT(N'Session B nhận kết quả lúc ', CONVERT(varchar(30), SYSUTCDATETIME(), 121),
             N' - BookingId=', @Booking2, N', Status=', @Status2);
GO

/*
    Kỳ vọng:
    - "Session B bắt đầu gọi" hiện ngay, còn "nhận kết quả" chỉ hiện sau khi Session A
      COMMIT (chênh ~20 giây): B bị block bởi UPDLOCK/HOLDLOCK của A.
    - Status của B là WAITLISTED, không phải CONFIRMED: không có overbooking.
    - Lưu ý: HV0002 phải có gói ACTIVE với AllowsClasses = 1. Nếu seed chưa có,
      tạo một DangKyGoi ACTIVE cho HV0002 trước khi demo (xem docs/TASK_TV3.md).
*/
