:on error exit
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

DECLARE @UserId int = (SELECT UserId FROM dbo.NguoiDung WHERE Username = 'letan');
IF @UserId IS NULL THROW 51210, N'Thiếu tài khoản letan để test lockout.', 1;

EXEC dbo.sp_RecordSuccessfulLogin @UserId;
EXEC dbo.sp_RecordFailedLogin @UserId;
EXEC dbo.sp_RecordFailedLogin @UserId;
EXEC dbo.sp_RecordFailedLogin @UserId;
EXEC dbo.sp_RecordFailedLogin @UserId;
EXEC dbo.sp_RecordFailedLogin @UserId;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.NguoiDung
    WHERE UserId = @UserId
      AND FailedLoginCount = 5
      AND LockedUntil > SYSUTCDATETIME()
)
    THROW 51211, N'Lockout không được kích hoạt sau 5 lần đăng nhập sai.', 1;

EXEC dbo.sp_RecordSuccessfulLogin @UserId;

IF EXISTS
(
    SELECT 1
    FROM dbo.NguoiDung
    WHERE UserId = @UserId
      AND (FailedLoginCount <> 0 OR LockedUntil IS NOT NULL)
)
    THROW 51212, N'Trạng thái lockout không được reset sau đăng nhập thành công.', 1;

PRINT N'AUTH LOCKOUT TEST PASSED.';
GO
