USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
    PK/FK/UNIQUE/CHECK nền của PhongTap, LopTap, LichLop, DatLop, CheckIn đã có
    trong 01_schema.sql (TV1). File này chỉ thêm ràng buộc nghiệp vụ bổ sung.
*/

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LichLop_MaxDuration')
    ALTER TABLE dbo.LichLop WITH CHECK
    ADD CONSTRAINT CK_LichLop_MaxDuration
        CHECK (DATEDIFF(MINUTE, StartAt, EndAt) BETWEEN 15 AND 480);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CheckIn_NotFuture')
    ALTER TABLE dbo.CheckIn WITH CHECK
    ADD CONSTRAINT CK_CheckIn_NotFuture
        CHECK (CheckedAt <= DATEADD(MINUTE, 5, SYSUTCDATETIME()));
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DatLop_BookedAt_NotFuture')
    ALTER TABLE dbo.DatLop WITH CHECK
    ADD CONSTRAINT CK_DatLop_BookedAt_NotFuture
        CHECK (BookedAt <= DATEADD(MINUTE, 5, SYSUTCDATETIME()));
GO

PRINT N'Đã thêm constraint nghiệp vụ bổ sung cho module Class Operations.';
GO
