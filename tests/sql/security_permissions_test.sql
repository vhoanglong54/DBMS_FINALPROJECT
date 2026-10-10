:on error exit
USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF DATABASE_PRINCIPAL_ID(N'tv1_test_letan') IS NOT NULL
BEGIN
    IF IS_ROLEMEMBER(N'rl_LeTan', N'tv1_test_letan') = 1
        ALTER ROLE rl_LeTan DROP MEMBER tv1_test_letan;
    DROP USER tv1_test_letan;
END;
GO

CREATE USER tv1_test_letan WITHOUT LOGIN;
ALTER ROLE rl_LeTan ADD MEMBER tv1_test_letan;
GO

DECLARE @ReadSucceeded bit = 0;
DECLARE @WriteDenied bit = 0;

EXECUTE AS USER = 'tv1_test_letan';
BEGIN TRY
    DECLARE @MemberCount int = (SELECT COUNT(*) FROM dbo.vw_HoiVienCoBan);
    SET @ReadSucceeded = 1;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
REVERT;

EXECUTE AS USER = 'tv1_test_letan';
BEGIN TRY
    UPDATE dbo.HoiVien SET UpdatedAt = UpdatedAt WHERE MemberId = -1;
    REVERT;
END TRY
BEGIN CATCH
    DECLARE @PermissionError int = ERROR_NUMBER();
    REVERT;
    IF @PermissionError = 229 SET @WriteDenied = 1;
    ELSE THROW;
END CATCH;

IF @ReadSucceeded <> 1
    THROW 51200, N'Role Lễ tân không đọc được view được cấp quyền.', 1;

IF @WriteDenied <> 1
    THROW 51201, N'Role Lễ tân chưa bị chặn ghi trực tiếp bảng.', 1;

ALTER ROLE rl_LeTan DROP MEMBER tv1_test_letan;
DROP USER tv1_test_letan;

PRINT N'SECURITY PERMISSION TEST PASSED: read view allowed, direct DML denied.';
GO
