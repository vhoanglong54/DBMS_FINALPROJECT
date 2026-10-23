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

/* PHẦN 1 — SQL ROLE (TV1 theo phiếu phân công).
    Database roles phục vụ minh họa phân quyền trực tiếp trên SQL Server.
    rl_GymApp là service role dự kiến cho ứng dụng web; chỉ có hiệu lực khi
    SQL principal kết nối thực sự được gán vào role này. Tài khoản người dùng cuối vẫn
    được xác thực ở NguoiDung và phân quyền bằng RoleCode trong cookie claims.
    Khai báo role ở đây; lệnh GRANT/DENY/REVOKE nằm tại PHẦN 5 bên dưới.
*/
IF DATABASE_PRINCIPAL_ID(N'rl_GymAdmin') IS NULL CREATE ROLE rl_GymAdmin AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_LeTan') IS NULL CREATE ROLE rl_LeTan AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_HuanLuyenVien') IS NULL CREATE ROLE rl_HuanLuyenVien AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_KeToan') IS NULL CREATE ROLE rl_KeToan AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rl_GymApp') IS NULL CREATE ROLE rl_GymApp AUTHORIZATION dbo;
GO

-- PHẦN 2 — VIEW: các cách đọc dữ liệu dùng lại, không lưu bản sao dữ liệu.
-- vw_HoiVienCoBan: chỉ lộ các cột hội viên cơ bản cho role được cấp SELECT.
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

-- vw_NhanVienTaiKhoan: ghép nhân viên -> tài khoản -> vai trò; nhân viên chưa có tài khoản vẫn hiện nhờ LEFT JOIN.
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

-- PHẦN 3 — STORED PROCEDURE xác thực/đổi mật khẩu (TV1).
-- sp_AuthenticateUser: lấy tài khoản, hash/salt và vai trò; ứng dụng mới đối chiếu mật khẩu.
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

-- sp_RecordFailedLogin: mỗi lần sai tăng bộ đếm; từ 5 lần sai khóa 15 phút.
-- TRANSACTION 1: đọc số lần sai và ghi số mới/LockedUntil như một đơn vị.
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

        -- UPDLOCK giữ quyền cập nhật khi đọc, tránh hai lần sai đồng thời cùng lấy một số cũ.
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

-- sp_RecordSuccessfulLogin: đăng nhập đúng thì xóa bộ đếm/khóa và ghi LastLoginAt.
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

-- sp_ChangePassword: lưu hash/salt mới do ứng dụng tạo, hạ MustChangePassword về 0.
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

-- PHẦN 4 — STORED PROCEDURE cấp/tra cứu tài khoản nhân viên (TV1).
-- TRANSACTION 2: chỉ ADMIN tạo NguoiDung, NhanVien, AuditLog cùng thành công hoặc cùng hủy.
CREATE OR ALTER PROCEDURE dbo.sp_StaffAccount_Create
    @ActorUserId int,
    @EmployeeCode varchar(20),
    @FullName nvarchar(120),
    @Phone varchar(15),
    @Email varchar(254) = NULL,
    @HireDate date,
    @EmployeeType varchar(20),
    @Username varchar(50),
    @PasswordHash varbinary(64),
    @PasswordSalt varbinary(32),
    @PasswordIterations int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.NguoiDung AS nd
            INNER JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId
            WHERE nd.UserId = @ActorUserId AND nd.IsActive = 1
              AND vt.RoleCode = 'ADMIN' AND vt.IsActive = 1
        )
            THROW 51040, N'Chỉ quản trị viên được cấp tài khoản nhân viên.', 1;

        IF DATALENGTH(@PasswordHash) < 32 OR DATALENGTH(@PasswordSalt) < 16
            THROW 51041, N'Hash hoặc salt mật khẩu không hợp lệ.', 1;
        IF @PasswordIterations NOT BETWEEN 100000 AND 1000000
            THROW 51042, N'Số vòng PBKDF2 không hợp lệ.', 1;

        DECLARE @RoleCode varchar(30) = CASE @EmployeeType
            WHEN 'MANAGER' THEN 'ADMIN'
            WHEN 'RECEPTIONIST' THEN 'RECEPTIONIST'
            WHEN 'TRAINER' THEN 'TRAINER'
            WHEN 'ACCOUNTANT' THEN 'ACCOUNTANT'
        END;
        DECLARE @RoleId smallint;
        SELECT @RoleId = RoleId FROM dbo.VaiTro
        WHERE RoleCode = @RoleCode AND IsActive = 1;
        IF @RoleId IS NULL
            THROW 51043, N'Vai trò nhân viên không hợp lệ hoặc đã ngừng hoạt động.', 1;

        DECLARE @NormalizedUsername varchar(50) = LOWER(LTRIM(RTRIM(@Username)));
        DECLARE @NormalizedEmployeeCode varchar(20) = UPPER(LTRIM(RTRIM(@EmployeeCode)));
        IF NULLIF(@NormalizedUsername, '') IS NULL
           OR NULLIF(@NormalizedEmployeeCode, '') IS NULL
           OR NULLIF(LTRIM(RTRIM(@FullName)), N'') IS NULL
            THROW 51044, N'Thiếu thông tin tài khoản hoặc nhân viên.', 1;

        IF EXISTS (SELECT 1 FROM dbo.NhanVien WHERE EmployeeCode = @NormalizedEmployeeCode)
            THROW 51046, N'Mã nhân viên đã được sử dụng.', 1;

        INSERT dbo.NguoiDung
            (RoleId, Username, PasswordHash, PasswordSalt, PasswordIterations, MustChangePassword)
        VALUES
            (@RoleId, @NormalizedUsername, @PasswordHash, @PasswordSalt, @PasswordIterations, 1);

        DECLARE @NewUserId int = CONVERT(int, SCOPE_IDENTITY());
        INSERT dbo.NhanVien
            (UserId, EmployeeCode, FullName, Phone, Email, HireDate, EmployeeType)
        VALUES
            (@NewUserId, @NormalizedEmployeeCode, LTRIM(RTRIM(@FullName)), @Phone,
             NULLIF(LTRIM(RTRIM(@Email)), ''), @HireDate, @EmployeeType);

        DECLARE @AuditValues nvarchar(max) =
            (SELECT @NormalizedUsername AS Username,
                    @NormalizedEmployeeCode AS EmployeeCode,
                    @EmployeeType AS EmployeeType
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        INSERT dbo.AuditLog (TableName, ActionType, EntityKey, NewValues, ChangedByUserId)
        VALUES (N'NguoiDung', 'INSERT', CONVERT(nvarchar(200), @NewUserId),
                @AuditValues, @ActorUserId);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- sp_StaffAccount_List: ADMIN xem danh sách qua vw_NhanVienTaiKhoan.
CREATE OR ALTER PROCEDURE dbo.sp_StaffAccount_List
    @ActorUserId int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.NguoiDung AS nd
        INNER JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId
        WHERE nd.UserId = @ActorUserId AND nd.IsActive = 1
          AND vt.RoleCode = 'ADMIN' AND vt.IsActive = 1
    )
        THROW 51040, N'Chỉ quản trị viên được xem tài khoản nhân viên.', 1;

    SELECT EmployeeCode, FullName, EmployeeType, Username, UserIsActive
    FROM dbo.vw_NhanVienTaiKhoan
    WHERE UserId IS NOT NULL
    ORDER BY EmployeeCode;
END;
GO

-- sp_StaffAccount_SuggestCode: gợi ý mã chưa dùng; mã chỉ được giữ chỗ khi tạo thành công.
CREATE OR ALTER PROCEDURE dbo.sp_StaffAccount_SuggestCode
    @ActorUserId int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.NguoiDung AS nd
        INNER JOIN dbo.VaiTro AS vt ON vt.RoleId = nd.RoleId
        WHERE nd.UserId = @ActorUserId AND nd.IsActive = 1
          AND vt.RoleCode = 'ADMIN' AND vt.IsActive = 1
    )
        THROW 51040, N'Chỉ quản trị viên được xem mã nhân viên kế tiếp.', 1;

    DECLARE @NextNumber bigint =
    (
        SELECT ISNULL(MAX(TRY_CONVERT(bigint, SUBSTRING(EmployeeCode, 4, 17))), 0) + 1
        FROM dbo.NhanVien
        WHERE EmployeeCode LIKE 'NV-%'
          AND SUBSTRING(EmployeeCode, 4, 17) <> ''
          AND SUBSTRING(EmployeeCode, 4, 17) NOT LIKE '%[^0-9]%'
    );

    IF @NextNumber > 99999999999999999
        THROW 51045, N'Đã hết dải mã nhân viên tự động.', 1;

    SELECT 'NV-' + CASE WHEN @NextNumber <= 9999
        THEN RIGHT('0000' + CONVERT(varchar(17), @NextNumber), 4)
        ELSE CONVERT(varchar(17), @NextNumber)
    END AS EmployeeCode;
END;
GO

-- PHẦN 5 — PHÂN QUYỀN SQL ROLE: GRANT = cấp, DENY = từ chối, REVOKE = gỡ quyền đã cấp/từ chối.
-- Đây là quyền của SQL principal; cookie role của nhân viên web là lớp phân quyền khác.
-- rl_GymAdmin: toàn quyền trong database project.
GRANT CONTROL ON DATABASE::[$(DatabaseName)] TO rl_GymAdmin;

-- GRANT SELECT: lễ tân đọc dữ liệu hội viên, gói, thu tiền và vận hành được liệt kê dưới đây.
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

-- GRANT SELECT: HLV chỉ đọc các vùng hội viên/lớp/check-in cần cho công việc.
GRANT SELECT ON dbo.vw_HoiVienCoBan TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.PhongTap TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.LopTap TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.LichLop TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.DatLop TO rl_HuanLuyenVien;
GRANT SELECT ON dbo.CheckIn TO rl_HuanLuyenVien;

-- GRANT SELECT: kế toán đọc hội viên/gói/hóa đơn/thanh toán.
GRANT SELECT ON dbo.vw_HoiVienCoBan TO rl_KeToan;
GRANT SELECT ON dbo.GoiTap TO rl_KeToan;
GRANT SELECT ON dbo.DangKyGoi TO rl_KeToan;
GRANT SELECT ON dbo.HoaDon TO rl_KeToan;
GRANT SELECT ON dbo.CTHoaDon TO rl_KeToan;
GRANT SELECT ON dbo.ThanhToan TO rl_KeToan;

-- DENY: ba role nghiệp vụ không ghi trực tiếp bảng dbo và không đọc bảng nhạy cảm.
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_LeTan;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_HuanLuyenVien;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_KeToan;
DENY SELECT ON dbo.NguoiDung TO rl_LeTan, rl_HuanLuyenVien, rl_KeToan;
DENY SELECT ON dbo.AuditLog TO rl_LeTan, rl_HuanLuyenVien, rl_KeToan;

-- GRANT EXECUTE: service role rl_GymApp chỉ được gọi các entry point xác thực/nhân sự này.
GRANT EXECUTE ON dbo.sp_AuthenticateUser TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_RecordFailedLogin TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_RecordSuccessfulLogin TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_ChangePassword TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_StaffAccount_Create TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_StaffAccount_List TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_StaffAccount_SuggestCode TO rl_GymApp;
-- DENY bảng trực tiếp cho rl_GymApp; quyền chạy procedure ở trên vẫn theo GRANT EXECUTE.
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rl_GymApp;

-- REVOKE: gỡ quyền SELECT cấp trực tiếp trước đó của HLV trên hai bảng tài chính.
-- REVOKE không tương đương DENY và không tự chặn quyền HLV có thể nhận từ role khác.
REVOKE SELECT ON dbo.HoaDon FROM rl_HuanLuyenVien;
REVOKE SELECT ON dbo.ThanhToan FROM rl_HuanLuyenVien;
GO

/* PHẦN 6 — SQL LOGIN DEMO TÙY CHỌN (khác tài khoản đăng nhập web).
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
