USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Đăng ký gói & Thanh toán (Giao dịch ACID)
CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoiTapMoi
    @MemberId INT,
    @PlanId INT,
    @EmployeeId INT,
    @StartDate DATE,
    @PaymentMethod VARCHAR(20)
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DurationDays SMALLINT, @Price DECIMAL(18,2);
        SELECT @DurationDays = DurationDays, @Price = Price FROM dbo.GoiTap WHERE PlanId = @PlanId;
        IF @Price IS NULL THROW 53001, N'Gói tập không hợp lệ', 1;

        -- Kiểm tra xem hội viên đã có gói ACTIVE chưa
        IF EXISTS (SELECT 1 FROM dbo.DangKyGoi WHERE MemberId = @MemberId AND Status = 'ACTIVE' AND EndDate >= @StartDate)
            THROW 51200, N'Hội viên đang có gói tập ACTIVE. Yêu cầu hủy gói cũ trước khi đăng ký!', 1;

        DECLARE @EndDate DATE = DATEADD(DAY, @DurationDays, @StartDate);

        INSERT INTO dbo.DangKyGoi (MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
        VALUES (@MemberId, @PlanId, @EmployeeId, @StartDate, @EndDate, @Price, 'ACTIVE');
        DECLARE @MembershipId BIGINT = SCOPE_IDENTITY();

        DECLARE @InvoiceCode VARCHAR(30) = 'HD-' + RIGHT(CAST(NEWID() AS VARCHAR(36)), 8);
        INSERT INTO dbo.HoaDon (InvoiceCode, MembershipId, CreatedByEmployeeId, TotalAmount, PaidAmount, Status)
        VALUES (@InvoiceCode, @MembershipId, @EmployeeId, @Price, @Price, 'PAID');
        DECLARE @InvoiceId BIGINT = SCOPE_IDENTITY();

        DECLARE @PaymentCode VARCHAR(30) = 'TT-' + RIGHT(CAST(NEWID() AS VARCHAR(36)), 8);
        INSERT INTO dbo.ThanhToan (PaymentCode, InvoiceId, ReceivedByEmployeeId, Amount, PaymentMethod, Status)
        VALUES (@PaymentCode, @InvoiceId, @EmployeeId, @Price, @PaymentMethod, 'COMPLETED');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 2. Hủy gói tập
CREATE OR ALTER PROCEDURE dbo.sp_HuyGoiTap
    @MembershipId BIGINT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;
    
    UPDATE dbo.DangKyGoi 
    SET Status = 'CANCELLED', CancellationReason = @Reason, UpdatedAt = SYSUTCDATETIME() 
    WHERE MembershipId = @MembershipId;
END;
GO

-- 3. Cập nhật thông tin thể hình hội viên
CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTheHinh
    @MemberId INT,
    @ChieuCao INT,
    @CanNang INT,
    @ThoiGianTap NVARCHAR(50) = NULL
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;
    
    UPDATE dbo.HoiVien 
    SET ChieuCao = @ChieuCao, CanNang = @CanNang, ThoiGianTap = @ThoiGianTap, UpdatedAt = SYSUTCDATETIME()
    WHERE MemberId = @MemberId;
END;
GO

-- 4. Tạo gói tập mới
CREATE OR ALTER PROCEDURE dbo.sp_TaoGoiTap
    @PlanCode VARCHAR(20),
    @PlanName NVARCHAR(120),
    @DurationDays SMALLINT,
    @Price DECIMAL(18,2),
    @Description NVARCHAR(500) = NULL
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;
    
    -- Ép kiểu NVARCHAR tường minh cho tên gói
    DECLARE @SafePlanName NVARCHAR(120) = CAST(@PlanName AS NVARCHAR(120));
    DECLARE @SafeDesc NVARCHAR(500) = CAST(@Description AS NVARCHAR(500));

    INSERT INTO dbo.GoiTap (PlanCode, PlanName, DurationDays, Price, Description)
    VALUES (@PlanCode, @SafePlanName, @DurationDays, @Price, @SafeDesc);
END;
GO

-- 5. Thêm hội viên mới (Ép kiểu NVARCHAR tường minh chống lỗi font tiếng Việt)
CREATE OR ALTER PROCEDURE dbo.sp_ThemHoiVien
    @FullName NVARCHAR(120),
    @Phone VARCHAR(15),
    @Email VARCHAR(254) = NULL,
    @DateOfBirth DATE,
    @Gender VARCHAR(10)
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;
    
    DECLARE @MemCode VARCHAR(20) = 'HV-' + RIGHT(CAST(NEWID() AS VARCHAR(36)), 8);
    
    -- Ép kiểu tường minh NVARCHAR để giữ nguyên dấu tiếng Việt khi chạy qua sqlcmd
    DECLARE @SafeFullName NVARCHAR(120) = CAST(@FullName AS NVARCHAR(120));
    
    INSERT INTO dbo.HoiVien (MemberCode, FullName, Phone, Email, DateOfBirth, Gender)
    VALUES (@MemCode, @SafeFullName, @Phone, @Email, @DateOfBirth, @Gender);
END;
GO