USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.trg_HoiVien_PreventDeleteActive 
ON dbo.HoiVien 
INSTEAD OF DELETE 
AS
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM deleted d 
        JOIN dbo.DangKyGoi dk ON d.MemberId = dk.MemberId 
        WHERE dk.Status = 'ACTIVE' AND dk.EndDate >= CONVERT(date, DATEADD(HOUR, 7, SYSUTCDATETIME()))
    )
    BEGIN
        THROW 53020, N'Không thể xóa hội viên đang có gói tập; hãy ngừng hoạt động hội viên.', 1;
    END
    DELETE FROM dbo.HoiVien WHERE MemberId IN (SELECT MemberId FROM deleted);
END;
GO
