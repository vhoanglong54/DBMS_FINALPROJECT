USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DatabaseName sysname = N'$(DatabaseName)';

IF NULLIF(@DatabaseName, N'') IS NULL
    THROW 51000, N'DatabaseName không được để trống.', 1;

IF @DatabaseName LIKE N'%[^A-Za-z0-9_]%'
    THROW 51000, N'DatabaseName chỉ được chứa chữ cái, chữ số và dấu gạch dưới.', 1;

IF DB_ID(@DatabaseName) IS NULL
BEGIN
    DECLARE @CreateSql nvarchar(max) = N'CREATE DATABASE ' + QUOTENAME(@DatabaseName) + N';';
    EXEC sys.sp_executesql @CreateSql;
    PRINT N'Đã tạo database ' + QUOTENAME(@DatabaseName) + N'.';
END
ELSE
BEGIN
    PRINT N'Database ' + QUOTENAME(@DatabaseName) + N' đã tồn tại; không tạo lại.';
END;
GO

USE [$(DatabaseName)];
GO

ALTER DATABASE CURRENT SET RECOVERY SIMPLE;
ALTER DATABASE CURRENT SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO

PRINT N'Database sẵn sàng: $(DatabaseName).';
GO
