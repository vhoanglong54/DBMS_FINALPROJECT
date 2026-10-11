USE [GymManagementDemo];
GO

SET NOCOUNT ON;

DECLARE @BeforeMemberships int = (SELECT COUNT(*) FROM dbo.DangKyGoi);
DECLARE @MembershipId bigint, @InvoiceId bigint;

BEGIN TRANSACTION;

EXEC dbo.sp_DangKyGoiTapMoi
    @MemberId = 2,
    @PlanId = 1,
    @EmployeeId = 1,
    @StartDate = '2031-01-01',
    @InitialPayment = 500000,
    @PaymentMethod = 'CASH',
    @MembershipId = @MembershipId OUTPUT,
    @InvoiceId = @InvoiceId OUTPUT;

SELECT
    [GiaiDoan] = N'Trong transaction: procedure đã tạo đủ dữ liệu',
    dk.MembershipId,
    hd.InvoiceId,
    dk.Status AS [TrangThaiGoi],
    hd.Status AS [TrangThaiHoaDon],
    hd.PaidAmount
FROM dbo.DangKyGoi AS dk
INNER JOIN dbo.HoaDon AS hd ON hd.MembershipId = dk.MembershipId
WHERE dk.MembershipId = @MembershipId;

ROLLBACK TRANSACTION;

SELECT
    [GiaiDoan] = N'Sau ROLLBACK: dữ liệu trở về trạng thái ban đầu',
    [SoDangKyTruoc] = @BeforeMemberships,
    [SoDangKySau] = COUNT(*),
    [DuLieuThuNghiemConLai] = COUNT(CASE WHEN MembershipId = @MembershipId THEN 1 END),
    [KetQua] = IIF(COUNT(*) = @BeforeMemberships
                    AND COUNT(CASE WHEN MembershipId = @MembershipId THEN 1 END) = 0,
                    N'PASS', N'FAIL')
FROM dbo.DangKyGoi;
GO
