USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF (SELECT COUNT(*) FROM sys.objects WHERE type = 'P' AND name IN
    ('sp_HoiVien_Luu', 'sp_HoiVien_SetActive', 'sp_GoiTap_Luu', 'sp_DangKyGoiTapMoi',
     'sp_ThanhToan_Them', 'sp_HuyGoiTap', 'sp_DangKyGoi_DanhSach')) <> 7
    THROW 52301, N'Smoke test membership: thiếu stored procedure bắt buộc.', 1;

IF OBJECT_ID(N'dbo.vw_HoiVienSapHetHan', N'V') IS NULL
    THROW 52302, N'Smoke test membership: thiếu view hội viên sắp hết hạn.', 1;

IF (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN', 'IF', 'TF')
    AND name IN ('fn_TongDoanhThuHoiVien', 'fn_XepHangHoiVien')) <> 2
    THROW 52303, N'Smoke test membership: thiếu function.', 1;

BEGIN TRANSACTION SmokeMembership;
BEGIN TRY
    DECLARE @MemberId int, @PlanId int, @MembershipId bigint, @InvoiceId bigint, @PaymentId bigint;
    DECLARE @EmployeeId int = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'RECEPTIONIST' AND IsActive = 1);
    IF @EmployeeId IS NULL THROW 52304, N'Smoke test membership: thiếu lễ tân.', 1;

    EXEC dbo.sp_HoiVien_Luu
        @FullName=N'Hội viên Smoke Test', @Phone='0900000801', @Email='membership-smoke@example.test',
        @DateOfBirth='20000101', @Gender='OTHER', @ChieuCao=170, @CanNang=65,
        @SavedMemberId=@MemberId OUTPUT;

    EXEC dbo.sp_GoiTap_Luu
        @PlanCode='SMOKE-30', @PlanName=N'Gói smoke 30 ngày', @DurationDays=30,
        @Price=300000, @MaxCheckInsPerDay=2, @AllowsClasses=1,
        @SavedPlanId=@PlanId OUTPUT;

    DECLARE @StartDate date = CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()));

    EXEC dbo.sp_DangKyGoiTapMoi
        @MemberId=@MemberId, @PlanId=@PlanId, @EmployeeId=@EmployeeId,
        @StartDate=@StartDate, @InitialPayment=100000, @PaymentMethod='CASH',
        @MembershipId=@MembershipId OUTPUT, @InvoiceId=@InvoiceId OUTPUT;

    IF (SELECT Status FROM dbo.HoaDon WHERE InvoiceId=@InvoiceId) <> 'PARTIAL'
        THROW 52305, N'Smoke test membership: hóa đơn phải ở trạng thái PARTIAL.', 1;
    IF (SELECT Status FROM dbo.DangKyGoi WHERE MembershipId=@MembershipId) <> 'PENDING'
        THROW 52306, N'Smoke test membership: gói chưa trả đủ phải PENDING.', 1;
    IF dbo.fn_TongDoanhThuHoiVien(@MemberId) <> 100000
        THROW 52310, N'Smoke test membership: function doanh thu phải tính cả khoản đã trả một phần.', 1;

    EXEC dbo.sp_ThanhToan_Them @InvoiceId=@InvoiceId, @EmployeeId=@EmployeeId,
         @Amount=200000, @PaymentMethod='BANK_TRANSFER', @TransactionReference='SMOKE',
         @PaymentId=@PaymentId OUTPUT;

    IF (SELECT Status FROM dbo.HoaDon WHERE InvoiceId=@InvoiceId) <> 'PAID'
        THROW 52307, N'Smoke test membership: hóa đơn phải chuyển PAID.', 1;
    IF (SELECT Status FROM dbo.DangKyGoi WHERE MembershipId=@MembershipId) <> 'ACTIVE'
        THROW 52308, N'Smoke test membership: gói phải kích hoạt sau khi trả đủ.', 1;
    IF dbo.fn_TongDoanhThuHoiVien(@MemberId) <> 300000
        THROW 52311, N'Smoke test membership: tổng tiền thực nhận không đúng.', 1;

    BEGIN TRY
        DELETE dbo.HoiVien WHERE MemberId=@MemberId;
        THROW 52309, N'Smoke test membership: trigger phải chặn xóa hội viên có gói active.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 53020 THROW;
    END CATCH;

    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION SmokeMembership;
    PRINT N'ALL MEMBERSHIP AND BILLING SMOKE TESTS PASSED.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Một hóa đơn mới trả một phần không được hủy gói để lại công nợ treo.
-- Lỗi kỳ vọng tự rollback toàn bộ dữ liệu ZZ-TEST-PARTIAL của phép thử.
BEGIN TRY
    BEGIN TRANSACTION SmokePartialCancel;
    DECLARE @PartialMemberId int, @PartialMembershipId bigint;
    DECLARE @PartialPlanId int = (SELECT TOP (1) PlanId FROM dbo.GoiTap WHERE IsActive = 1);
    DECLARE @PartialEmployeeId int = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE IsActive = 1);
    DECLARE @PartialToday date = CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()));

    INSERT dbo.HoiVien(MemberCode, FullName, DateOfBirth, Phone)
    VALUES ('ZZ-TEST-PARTIAL', N'Hội viên test công nợ', '20000101', '0900000899');
    SET @PartialMemberId = SCOPE_IDENTITY();
    INSERT dbo.DangKyGoi(MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
    VALUES (@PartialMemberId, @PartialPlanId, @PartialEmployeeId,
            @PartialToday, DATEADD(DAY, 30, @PartialToday), 100000, 'PENDING');
    SET @PartialMembershipId = SCOPE_IDENTITY();
    INSERT dbo.HoaDon(InvoiceCode, MembershipId, CreatedByEmployeeId, TotalAmount, PaidAmount, Status)
    VALUES ('ZZ-TEST-PARTIAL', @PartialMembershipId, @PartialEmployeeId, 100000, 50000, 'PARTIAL');

    EXEC dbo.sp_HuyGoiTap @MembershipId = @PartialMembershipId, @Reason = N'Test hủy công nợ';
    THROW 52312, N'Smoke test membership: phải chặn hủy gói đang trả một phần.', 1;
END TRY
BEGIN CATCH
    DECLARE @PartialError int = ERROR_NUMBER();
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF @PartialError <> 53022 THROW;
END CATCH;
GO
