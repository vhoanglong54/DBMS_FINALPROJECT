USE GymManagementDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_TongDoanhThuHoiVien(@MemberId INT) 
RETURNS DECIMAL(18,2) 
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;
    SELECT @Total = SUM(PaidAmount) 
    FROM dbo.HoaDon hd 
    JOIN dbo.DangKyGoi dk ON hd.MembershipId = dk.MembershipId 
    WHERE dk.MemberId = @MemberId AND hd.Status = 'PAID';
    
    RETURN ISNULL(@Total, 0);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_XepHangHoiVien(@MemberId INT) 
RETURNS VARCHAR(20) 
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = dbo.fn_TongDoanhThuHoiVien(@MemberId);
    DECLARE @Hang VARCHAR(20) = 'Standard';
    
    IF @Total >= 20000000 SET @Hang = 'Diamond';
    ELSE IF @Total >= 10000000 SET @Hang = 'VIP Gold';
    ELSE IF @Total >= 5000000 SET @Hang = 'VIP Silver';
    
    RETURN @Hang;
END;
GO