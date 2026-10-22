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

IF OBJECT_ID(N'dbo.sp_StaffAccount_Create', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_StaffAccount_List', N'P') IS NULL
   OR OBJECT_ID(N'dbo.sp_StaffAccount_SuggestCode', N'P') IS NULL
    THROW 51108, N'Smoke test thất bại: thiếu procedure cấp tài khoản nhân viên.', 1;

DECLARE @AdminUserId int = (SELECT UserId FROM dbo.NguoiDung WHERE Username = 'admin');
CREATE TABLE #SuggestedEmployeeCode (EmployeeCode varchar(20));
INSERT #SuggestedEmployeeCode
EXEC dbo.sp_StaffAccount_SuggestCode @ActorUserId = @AdminUserId;

IF (SELECT COUNT(*) FROM #SuggestedEmployeeCode) <> 1
   OR EXISTS
   (
       SELECT 1 FROM #SuggestedEmployeeCode AS suggested
       INNER JOIN dbo.NhanVien AS existing ON existing.EmployeeCode = suggested.EmployeeCode
   )
    THROW 51111, N'Smoke test thất bại: mã nhân viên gợi ý bị trùng hoặc không có.', 1;

DECLARE @TestSuffix char(8) = LEFT(REPLACE(CONVERT(varchar(36), NEWID()), '-', ''), 8);
DECLARE @TestEmployeeCode varchar(20) = 'NV-T-' + UPPER(@TestSuffix);
DECLARE @TestUsername varchar(50) = 'smoke_' + LOWER(@TestSuffix);
DECLARE @TestHash varbinary(64) = CONVERT(varbinary(64), REPLICATE('0', 64), 2);
DECLARE @TestSalt varbinary(32) = CONVERT(varbinary(32), REPLICATE('0', 32), 2);

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.sp_StaffAccount_Create
        @ActorUserId = @AdminUserId,
        @EmployeeCode = @TestEmployeeCode,
        @FullName = N'Nhân viên kiểm thử',
        @Phone = '0900000099',
        @Email = NULL,
        @HireDate = '20261022',
        @EmployeeType = 'TRAINER',
        @Username = @TestUsername,
        @PasswordHash = @TestHash,
        @PasswordSalt = @TestSalt,
        @PasswordIterations = 100000;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.NguoiDung AS nd
        INNER JOIN dbo.NhanVien AS nv ON nv.UserId = nd.UserId
        INNER JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId
        WHERE nd.Username = @TestUsername AND nd.MustChangePassword = 1
          AND nv.EmployeeCode = @TestEmployeeCode AND vt.RoleCode = 'TRAINER'
    )
        THROW 51109, N'Smoke test thất bại: tài khoản mới thiếu nhân viên, vai trò hoặc cờ đổi mật khẩu.', 1;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = @TestUsername)
    THROW 51110, N'Smoke test thất bại: dữ liệu thử không được rollback.', 1;

DECLARE @DuplicateUsername varchar(50) = @TestUsername + '_dup';
BEGIN TRY
    EXEC dbo.sp_StaffAccount_Create
        @ActorUserId = @AdminUserId,
        @EmployeeCode = 'NV-ADMIN',
        @FullName = N'Nhân viên trùng mã',
        @Phone = '0900000099',
        @Email = NULL,
        @HireDate = '20261022',
        @EmployeeType = 'TRAINER',
        @Username = @DuplicateUsername,
        @PasswordHash = @TestHash,
        @PasswordSalt = @TestSalt,
        @PasswordIterations = 100000;

    THROW 51112, N'Smoke test thất bại: mã nhân viên trùng không bị chặn.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51046 THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = @DuplicateUsername)
    THROW 51113, N'Smoke test thất bại: tài khoản trùng mã vẫn được tạo.', 1;

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
