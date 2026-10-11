USE [GymManagementDemo];
GO

SET NOCOUNT ON;

DECLARE @MembershipBefore int = (SELECT COUNT(*) FROM dbo.DangKyGoi);
DECLARE @InvoiceBefore int = (SELECT COUNT(*) FROM dbo.HoaDon);
DECLARE @PaymentBefore int = (SELECT COUNT(*) FROM dbo.ThanhToan);
DECLARE @ErrorNumber int, @ErrorMessage nvarchar(4000);

BEGIN TRY
    DECLARE @MembershipId bigint, @InvoiceId bigint;
    EXEC dbo.sp_DangKyGoiTapMoi
        @MemberId = 2,
        @PlanId = 1,
        @EmployeeId = 1,
        @StartDate = '2032-01-01',
        @InitialPayment = 600000,
        @PaymentMethod = 'CASH',
        @MembershipId = @MembershipId OUTPUT,
        @InvoiceId = @InvoiceId OUTPUT;
END TRY
BEGIN CATCH
    SELECT @ErrorNumber = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE();
END CATCH;

SELECT
    [NghiepVu] = N'Đăng ký gói với số tiền vượt giá gói',
    [MaLoi] = @ErrorNumber,
    [ThongBao] = @ErrorMessage,
    [DangKyKhongDoi] = IIF(@MembershipBefore = (SELECT COUNT(*) FROM dbo.DangKyGoi), N'PASS', N'FAIL'),
    [HoaDonKhongDoi] = IIF(@InvoiceBefore = (SELECT COUNT(*) FROM dbo.HoaDon), N'PASS', N'FAIL'),
    [ThanhToanKhongDoi] = IIF(@PaymentBefore = (SELECT COUNT(*) FROM dbo.ThanhToan), N'PASS', N'FAIL');

DECLARE @SessionBefore int = (SELECT COUNT(*) FROM dbo.LichLop);
DECLARE @TriggerError int, @TriggerMessage nvarchar(4000);

BEGIN TRY
    INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
    SELECT TOP (1) ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, 'SCHEDULED'
    FROM dbo.LichLop
    WHERE Status <> 'CANCELLED'
    ORDER BY SessionId;
END TRY
BEGIN CATCH
    SELECT @TriggerError = ERROR_NUMBER(), @TriggerMessage = ERROR_MESSAGE();
END CATCH;

SELECT
    [Trigger] = N'trg_LichLop_NoOverlap',
    [MaLoi] = @TriggerError,
    [ThongBao] = @TriggerMessage,
    [SoLichKhongDoi] = IIF(@SessionBefore = (SELECT COUNT(*) FROM dbo.LichLop), N'PASS', N'FAIL');
GO
