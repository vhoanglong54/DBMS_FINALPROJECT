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

DECLARE @UserTableCount int =
(
    SELECT COUNT(*)
    FROM sys.tables
    WHERE is_ms_shipped = 0
);

IF @UserTableCount < 15
    THROW 51100, N'Smoke test thất bại: phải có ít nhất 15 bảng nghiệp vụ.', 1;

IF (SELECT COUNT(*) FROM dbo.VaiTro WHERE RoleCode IN ('ADMIN', 'RECEPTIONIST', 'TRAINER', 'ACCOUNTANT')) <> 4
    THROW 51101, N'Smoke test thất bại: thiếu role ứng dụng.', 1;

IF (SELECT COUNT(*) FROM dbo.NguoiDung WHERE Username IN ('admin', 'letan', 'trainer', 'ketoan')) <> 4
    THROW 51102, N'Smoke test thất bại: thiếu tài khoản demo.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE is_ms_shipped = 0 AND (is_disabled = 1 OR is_not_trusted = 1)
)
    THROW 51103, N'Smoke test thất bại: có foreign key bị disable hoặc không trusted.', 1;

IF (SELECT COUNT(*) FROM sys.check_constraints WHERE is_ms_shipped = 0) < 5
    THROW 51104, N'Smoke test thất bại: thiếu CHECK constraints.', 1;

IF
(
    SELECT COUNT(*)
    FROM sys.database_principals
    WHERE type = 'R' AND name IN ('rl_GymAdmin', 'rl_LeTan', 'rl_HuanLuyenVien', 'rl_KeToan', 'rl_GymApp')
) <> 5
    THROW 51105, N'Smoke test thất bại: thiếu database role.', 1;

CREATE TABLE #AuthenticationResult
(
    UserId int,
    Username varchar(50),
    PasswordHash varbinary(64),
    PasswordSalt varbinary(32),
    PasswordIterations int,
    MustChangePassword bit,
    FailedLoginCount tinyint,
    LockedUntil datetime2(0),
    RoleCode varchar(30),
    RoleName nvarchar(100),
    EmployeeId int,
    DisplayName nvarchar(120)
);

INSERT #AuthenticationResult
EXEC dbo.sp_AuthenticateUser @Username = 'admin';

IF (SELECT COUNT(*) FROM #AuthenticationResult WHERE RoleCode = 'ADMIN' AND DATALENGTH(PasswordHash) = 32) <> 1
    THROW 51106, N'Smoke test thất bại: procedure xác thực không trả đúng tài khoản admin.', 1;

BEGIN TRANSACTION;
BEGIN TRY
    INSERT dbo.GoiTap(PlanCode, PlanName, DurationDays, Price, MaxCheckInsPerDay, AllowsClasses)
    VALUES ('INVALID-PLAN', N'Dữ liệu sai', 0, -1, 0, 0);

    ROLLBACK TRANSACTION;
    THROW 51107, N'Smoke test thất bại: CHECK constraint không chặn gói tập sai.', 1;
END TRY
BEGIN CATCH
    DECLARE @ConstraintError int = ERROR_NUMBER();
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF @ConstraintError <> 547 THROW;
END CATCH;

SELECT
    @UserTableCount AS UserTableCount,
    (SELECT COUNT(*) FROM sys.check_constraints WHERE is_ms_shipped = 0) AS CheckConstraintCount,
    (SELECT COUNT(*) FROM sys.foreign_keys WHERE is_ms_shipped = 0) AS ForeignKeyCount,
    (SELECT COUNT(*) FROM dbo.NguoiDung) AS DemoUserCount,
    (SELECT COUNT(*) FROM dbo.HoiVien) AS DemoMemberCount;

PRINT N'ALL TV1 DATABASE SMOKE TESTS PASSED.';
GO
