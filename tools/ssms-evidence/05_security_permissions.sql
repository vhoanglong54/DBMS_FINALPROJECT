USE [GymManagementDemo];
GO

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

IF DATABASE_PRINCIPAL_ID(N'report_test_letan') IS NOT NULL
BEGIN
    IF IS_ROLEMEMBER(N'rl_LeTan', N'report_test_letan') = 1
        ALTER ROLE rl_LeTan DROP MEMBER report_test_letan;
    DROP USER report_test_letan;
END;

CREATE USER report_test_letan WITHOUT LOGIN;
ALTER ROLE rl_LeTan ADD MEMBER report_test_letan;

DECLARE @ViewReadAllowed bit = 0,
        @DirectUpdateDenied bit = 0,
        @PermissionError int = NULL,
        @VisibleMembers int = 0;

EXECUTE AS USER = 'report_test_letan';
BEGIN TRY
    SELECT @VisibleMembers = COUNT(*) FROM dbo.vw_HoiVienCoBan;
    SET @ViewReadAllowed = 1;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
REVERT;

EXECUTE AS USER = 'report_test_letan';
BEGIN TRY
    UPDATE dbo.HoiVien SET UpdatedAt = UpdatedAt WHERE MemberId = -1;
    REVERT;
END TRY
BEGIN CATCH
    SET @PermissionError = ERROR_NUMBER();
    REVERT;
    IF @PermissionError = 229 SET @DirectUpdateDenied = 1;
    ELSE THROW;
END CATCH;

ALTER ROLE rl_LeTan DROP MEMBER report_test_letan;
DROP USER report_test_letan;

SELECT
    [VaiTro] = N'rl_LeTan',
    [DocViewDuocCapQuyen] = IIF(@ViewReadAllowed = 1, N'PASS', N'FAIL'),
    [SoHoiVienNhinThay] = @VisibleMembers,
    [SuaTrucTiepBangBiChan] = IIF(@DirectUpdateDenied = 1, N'PASS', N'FAIL'),
    [MaLoiDENY] = @PermissionError,
    [KetQua] = IIF(@ViewReadAllowed = 1 AND @DirectUpdateDenied = 1, N'PASS', N'FAIL');

SELECT
    [DatabaseRole] = dp.name,
    [ThanhVien] = COALESCE(STRING_AGG(mp.name, N', '), N'(không có user cố định)')
FROM sys.database_principals AS dp
LEFT JOIN sys.database_role_members AS drm ON drm.role_principal_id = dp.principal_id
LEFT JOIN sys.database_principals AS mp ON mp.principal_id = drm.member_principal_id
WHERE dp.type = 'R' AND dp.name LIKE N'rl[_]%'
GROUP BY dp.name
ORDER BY dp.name;
GO
