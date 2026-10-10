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

/*
    Database roles phục vụ minh họa phân quyền trực tiếp trên SQL Server.
    rl_GymApp là service role của ứng dụng web; tài khoản người dùng cuối vẫn
    được xác thực ở NguoiDung và phân quyền bằng RoleCode trong cookie claims.
*/
IF DATABASE_PRINCIPAL_ID(N'rl_GymAdmin') IS NULL CREATE ROLE rl_GymAdmin AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_LeTan') IS NULL CREATE ROLE rl_LeTan AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_HuanLuyenVien') IS NULL CREATE ROLE rl_HuanLuyenVien AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_KeToan') IS NULL CREATE ROLE rl_KeToan AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_GymApp') IS NULL CREATE ROLE rl_GymApp AUTHORIZATION dbo;
GO

CREATE OR ALTER VIEW dbo.vw_HoiVienCoBan
AS
    SELECT
        MemberId,
        MemberCode,
        FullName,
        DateOfBirth,
        Gender,
        Phone,
        Email,
        JoinedAt,
        IsActive
    FROM dbo.HoiVien;
GO

CREATE OR ALTER VIEW dbo.vw_NhanVienTaiKhoan
AS
    SELECT
        nv.EmployeeId,
        nv.EmployeeCode,
        nv.FullName,
        nv.EmployeeType,
        nv.IsActive AS EmployeeIsActive,
        nd.UserId,
        nd.Username,
        vt.RoleCode,
        vt.RoleName,
        nd.IsActive AS UserIsActive,
        nd.MustChangePassword,
        nd.FailedLoginCount,
        nd.LockedUntil,
        nd.LastLoginAt
    FROM dbo.NhanVien AS nv
    LEFT JOIN dbo.NguoiDung AS nd ON nd.UserId = nv.UserId
    LEFT JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AuthenticateUser
    @Username varchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NormalizedUsername varchar(50) = LOWER(LTRIM(RTRIM(@Username)));

    SELECT TOP (1)
        nd.UserId,
        nd.Username,
        nd.PasswordHash,
        nd.PasswordSalt,
        nd.PasswordIterations,
        nd.MustChangePassword,
        nd.FailedLoginCount,
        nd.LockedUntil,
        vt.RoleCode,
        vt.RoleName,
        nv.EmployeeId,
        COALESCE(nv.FullName, nd.Username) AS DisplayName
    FROM dbo.NguoiDung AS nd
    INNER JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId AND vt.IsActive = 1
    LEFT JOIN dbo.NhanVien AS nv ON nv.UserId = nd.UserId AND nv.IsActive = 1
    WHERE LOWER(nd.Username) = @NormalizedUsername
      AND nd.IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RecordFailedLogin
    @UserId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Now datetime2(0) = SYSUTCDATETIME();
        DECLARE @CurrentFailures int;

        SELECT @CurrentFailures =
            CASE
                WHEN LockedUntil IS NOT NULL AND LockedUntil <= @Now THEN 0
                ELSE FailedLoginCount
            END
        FROM dbo.NguoiDung WITH (UPDLOCK, ROWLOCK)
        WHERE UserId = @UserId AND IsActive = 1;

        IF @CurrentFailures IS NOT NULL
        BEGIN
            SET @CurrentFailures += 1;

            UPDATE dbo.NguoiDung
            SET FailedLoginCount = @CurrentFailures,
                LockedUntil = CASE
                    WHEN @CurrentFailures >= 5 THEN DATEADD(MINUTE, 15, @Now)
                    ELSE LockedUntil
                END,
                UpdatedAt = @Now
            WHERE UserId = @UserId;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RecordSuccessfulLogin
    @UserId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now datetime2(0) = SYSUTCDATETIME();

    UPDATE dbo.NguoiDung
    SET FailedLoginCount = 0,
        LockedUntil = NULL,
        LastLoginAt = @Now,
        UpdatedAt = @Now
    WHERE UserId = @UserId AND IsActive = 1;

    IF @@ROWCOUNT = 0
        THROW 51030, N'Tài khoản không tồn tại hoặc đã bị khóa quản trị.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ChangePassword
    @UserId int,
    @PasswordHash varbinary(64),
    @PasswordSalt varbinary(32),
    @PasswordIterations int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF DATALENGTH(@PasswordHash) < 32 OR DATALENGTH(@PasswordSalt) < 16
        THROW 51031, N'Hash hoặc salt mật khẩu không hợp lệ.', 1;

    IF @PasswordIterations NOT BETWEEN 100000 AND 1000000
        THROW 51032, N'Số vòng PBKDF2 không hợp lệ.', 1;

    UPDATE dbo.NguoiDung
    SET PasswordHash = @PasswordHash,
        PasswordSalt = @PasswordSalt,
        PasswordIterations = @PasswordIterations,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL,
        UpdatedAt = SYSUTCDATETIME()
    WHERE UserId = @UserId AND IsActive = 1;

    IF @@ROWCOUNT = 0
        THROW 51033, N'Tài khoản không tồn tại hoặc không hoạt động.', 1;
END;
GO

/* Admin có toàn quyền trong database project. */
GRANT CONTROL ON DATABASE::[$(DatabaseName)] TO rl_GymAdmin;

/* Các role nghiệp vụ chỉ đọc đúng vùng dữ liệu và không ghi trực tiếp bảng. */
GRANT SELECT ON dbo.vw_HoiVienCoBan TO rl_LeTan;
GRANT SELECT ON dbo.GoiTap TO rl_LeTan;
GRANT SELECT ON dbo.DangKyGoi TO rl_LeTan;
GRANT SELECT ON dbo.HoaDon TO rl_LeTan;
GRANT SELECT ON dbo.CTHoaDon TO rl_LeTan;
GRANT SELECT ON dbo.ThanhToan TO rl_LeTan;
GRANT SELECT ON dbo.PhongTap TO rl_LeTan;
GRANT SELECT ON dbo.LopTap TO rl_LeTan;
GRANT SELECT ON dbo.LichLop TO rl_LeTan;
GRANT SELECT ON dbo.DatLop TO rl_LeTan;
GRANT SELECT ON dbo.CheckIn TO rl_LeTan;

GRANT SELECT ON dbo.vw_HoiVienCoBan TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.PhongTap TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.LopTap TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.LichLop TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.DatLop TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.CheckIn TO rl_HuanLuyenVien;

GRANT SELECT ON dbo.vw_HoiVienCoBan TO rl_KeToan;
GRANT SELECT ON dbo.GoiTap TO rl_KeToan;
GRANT SELECT ON dbo.DangKyGoi TO rl_KeToan;
GRANT SELECT ON dbo.HoaDon TO rl_KeToan;
GRANT SELECT ON dbo.CTHoaDon TO rl_KeToan;
GRANT SELECT ON dbo.ThanhToan TO rl_KeToan;

DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_LeTan;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_HuanLuyenVien;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_KeToan;
DENY SELECT ON dbo.NguoiDung TO rl_LeTan, rl_HuanLuyenVien, rl_KeToan;
DENY SELECT ON dbo.AuditLog TO rl_LeTan, rl_HuanLuyenVien, rl_KeToan;

GRANT EXECUTE ON dbo.sp_AuthenticateUser TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_RecordFailedLogin TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_RecordSuccessfulLogin TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_ChangePassword TO rl_GymApp;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_GymApp;

/* REVOKE minh họa: bảo đảm Trainer không giữ quyền đọc dữ liệu tài chính nếu từng được cấp trước đó. */
REVOKE SELECT ON dbo.HoaDon FROM rl_HuanLuyenVien;
REVOKE SELECT ON dbo.ThanhToan FROM rl_HuanLuyenVien;
GO

/*
    Tùy chọn tạo 4 SQL Login demo. Mặc định tắt để không commit mật khẩu.
    Chỉ bật bằng sqlcmd -v CreateDemoLogins=1 và truyền đủ 4 password khác placeholder.
*/
IF '$(CreateDemoLogins)' = '1'
BEGIN
    IF '$(AdminPassword)' LIKE 'CHANGE_ME%'
       OR '$(ReceptionPassword)' LIKE 'CHANGE_ME%'
       OR '$(TrainerPassword)' LIKE 'CHANGE_ME%'
       OR '$(AccountantPassword)' LIKE 'CHANGE_ME%'
        THROW 51034, N'Phải truyền password mạnh qua SQLCMD variables; không dùng placeholder.', 1;

    DECLARE @LoginDefinitions TABLE
    (
        LoginName sysname NOT NULL,
        LoginPassword nvarchar(128) NOT NULL,
        DatabaseRole sysname NOT NULL
    );

    INSERT @LoginDefinitions(LoginName, LoginPassword, DatabaseRole)
    VALUES
        (N'$(AdminLogin)', N'$(AdminPassword)', N'rl_GymAdmin'),
        (N'$(ReceptionLogin)', N'$(ReceptionPassword)', N'rl_LeTan'),
        (N'$(TrainerLogin)', N'$(TrainerPassword)', N'rl_HuanLuyenVien'),
        (N'$(AccountantLogin)', N'$(AccountantPassword)', N'rl_KeToan');

    DECLARE @LoginName sysname;
    DECLARE @LoginPassword nvarchar(128);
    DECLARE @DatabaseRole sysname;
    DECLARE @Sql nvarchar(max);

    DECLARE login_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT LoginName, LoginPassword, DatabaseRole FROM @LoginDefinitions;

    OPEN login_cursor;
    FETCH NEXT FROM login_cursor INTO @LoginName, @LoginPassword, @DatabaseRole;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF SUSER_ID(@LoginName) IS NULL
        BEGIN
            SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@LoginName)
                + N' WITH PASSWORD = ' + QUOTENAME(@LoginPassword, '''')
                + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
            EXEC master.sys.sp_executesql @Sql;
        END;

        IF DATABASE_PRINCIPAL_ID(@LoginName) IS NULL
        BEGIN
            SET @Sql = N'CREATE USER ' + QUOTENAME(@LoginName)
                + N' FOR LOGIN ' + QUOTENAME(@LoginName) + N';';
            EXEC sys.sp_executesql @Sql;
        END;

        SET @Sql = N'ALTER ROLE ' + QUOTENAME(@DatabaseRole)
            + N' ADD MEMBER ' + QUOTENAME(@LoginName) + N';';
        EXEC sys.sp_executesql @Sql;

        FETCH NEXT FROM login_cursor INTO @LoginName, @LoginPassword, @DatabaseRole;
    END;

    CLOSE login_cursor;
    DEALLOCATE login_cursor;
END;
GO

PRINT N'Đã cấu hình roles, views bảo mật và procedures xác thực.';
GO
