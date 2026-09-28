USE [GymManagementDB];
GO

-- 1. VIEW: Báo cáo hội viên sắp hết hạn gói tập
CREATE OR ALTER VIEW dbo.vw_HoiVienSapHetHan AS
SELECT 
    hv.MemberId AS MaHV,
    hv.FullName AS HoTen,
    hv.Phone AS SoDienThoai,
    gt.PlanName AS TenGoi,
    dk.EndDate AS NgayKetThuc,
    DATEDIFF(DAY, GETDATE(), dk.EndDate) AS SoNgayConLai
FROM dbo.DangKyGoi dk
JOIN dbo.HoiVien hv ON dk.MemberId = hv.MemberId
JOIN dbo.GoiTap gt ON dk.PlanId = gt.PlanId
WHERE dk.Status = 'ACTIVE' 
  AND DATEDIFF(DAY, GETDATE(), dk.EndDate) BETWEEN 0 AND 15;
GO

-- 2. SP: Đăng ký gói tập & Thanh toán (Transaction)
CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoiTapMoi
    @MemberId INT,
    @PlanId INT,
    @EmployeeId INT,
    @StartDate DATE,
    @PaymentMethod VARCHAR(20) -- 'CASH', 'BANK_TRANSFER', 'CARD'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Chặn đăng ký nếu đang có gói ACTIVE chưa hết hạn
        IF EXISTS (SELECT 1 FROM dbo.DangKyGoi WHERE MemberId = @MemberId AND Status = 'ACTIVE' AND EndDate >= @StartDate)
            THROW 51200, N'Hội viên đang có gói tập ACTIVE. Yêu cầu hủy gói cũ trước khi đăng ký!', 1;
            
        -- Lấy thông tin gói tập
        DECLARE @DurationDays SMALLINT, @Price DECIMAL(18,2);
        SELECT @DurationDays = DurationDays, @Price = Price FROM dbo.GoiTap WHERE PlanId = @PlanId;
        
        DECLARE @EndDate DATE = DATEADD(DAY, @DurationDays, @StartDate);
        
        -- Insert Đăng Ký
        INSERT INTO dbo.DangKyGoi (MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
        VALUES (@MemberId, @PlanId, @EmployeeId, @StartDate, @EndDate, @Price, 'ACTIVE');
        
        DECLARE @MembershipId BIGINT = SCOPE_IDENTITY();
        
        -- Insert Hóa Đơn
        DECLARE @InvoiceCode VARCHAR(30) = 'INV-' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + CAST(@MembershipId AS VARCHAR);
        INSERT INTO dbo.HoaDon (InvoiceCode, MembershipId, CreatedByEmployeeId, TotalAmount, PaidAmount, Status, Note)
        VALUES (@InvoiceCode, @MembershipId, @EmployeeId, @Price, @Price, 'PAID', N'Thanh toán đăng ký gói tập');
        
        DECLARE @InvoiceId BIGINT = SCOPE_IDENTITY();
        
        -- Insert CT Hóa Đơn
        INSERT INTO dbo.CTHoaDon (InvoiceId, ItemType, Description, Quantity, UnitPrice, DiscountAmount)
        VALUES (@InvoiceId, 'MEMBERSHIP', N'Đăng ký gói tập', 1, @Price, 0);
        
        -- Insert Thanh Toán
        DECLARE @PaymentCode VARCHAR(30) = 'PAY-' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + CAST(@InvoiceId AS VARCHAR);
        INSERT INTO dbo.ThanhToan (PaymentCode, InvoiceId, ReceivedByEmployeeId, Amount, PaymentMethod, Status)
        VALUES (@PaymentCode, @InvoiceId, @EmployeeId, @Price, @PaymentMethod, 'COMPLETED');
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 3. SP: Hủy đăng ký gói
CREATE OR ALTER PROCEDURE dbo.sp_HuyGoiTap
    @MembershipId BIGINT
AS
BEGIN
    UPDATE dbo.DangKyGoi 
    SET Status = 'CANCELLED', CancellationReason = N'Khách hàng hủy gói tập'
    WHERE MembershipId = @MembershipId AND Status = 'ACTIVE';
END;
GO