USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_TongDoanhThuHoiVien(@MemberId INT) 
RETURNS DECIMAL(18,2) 
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;
    -- Tính tiền thực nhận, kể cả hóa đơn mới thanh toán một phần.
    SELECT @Total = SUM(tt.Amount)
    FROM dbo.ThanhToan AS tt
    JOIN dbo.HoaDon AS hd ON hd.InvoiceId = tt.InvoiceId
    JOIN dbo.DangKyGoi AS dk ON dk.MembershipId = hd.MembershipId
    WHERE dk.MemberId = @MemberId
      AND tt.Status = 'COMPLETED' AND hd.Status <> 'CANCELLED';
    
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
