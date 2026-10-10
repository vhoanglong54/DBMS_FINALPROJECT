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

DECLARE @Tables int = (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0);
DECLARE @Checks int = (SELECT COUNT(*) FROM sys.check_constraints WHERE is_ms_shipped=0 AND is_disabled=0 AND is_not_trusted=0);
DECLARE @Triggers int = (SELECT COUNT(*) FROM sys.triggers WHERE parent_class_desc='OBJECT_OR_COLUMN' AND is_disabled=0);
DECLARE @Views int = (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0);
DECLARE @Indexes int =
(
    SELECT COUNT(*) FROM sys.indexes i
    INNER JOIN sys.tables t ON t.object_id=i.object_id
    WHERE t.is_ms_shipped=0 AND i.name IS NOT NULL AND i.is_primary_key=0 AND i.is_disabled=0
);
DECLARE @Procedures int = (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0);
DECLARE @Functions int = (SELECT COUNT(*) FROM sys.objects WHERE is_ms_shipped=0 AND type IN ('FN','IF','TF'));
DECLARE @TransactionalProcedures int =
(
    SELECT COUNT(*) FROM sys.procedures p
    INNER JOIN sys.sql_modules m ON m.object_id=p.object_id
    WHERE m.definition LIKE '%BEGIN TRANSACTION%' AND m.definition LIKE '%BEGIN TRY%' AND m.definition LIKE '%BEGIN CATCH%'
);
DECLARE @Roles int =
(
    SELECT COUNT(*) FROM sys.database_principals
    WHERE type='R' AND name IN ('rl_GymAdmin','rl_LeTan','rl_HuanLuyenVien','rl_KeToan','rl_GymApp')
);

IF @Tables < 8 THROW 52401, N'Rubric: thiếu bảng.', 1;
IF @Checks < 5 THROW 52402, N'Rubric: thiếu CHECK constraint.', 1;
IF @Triggers < 5 THROW 52403, N'Rubric: thiếu trigger.', 1;
IF @Views < 5 THROW 52404, N'Rubric: thiếu view.', 1;
IF @Indexes < 5 THROW 52405, N'Rubric: thiếu non-PK index.', 1;
IF @Procedures < 5 THROW 52406, N'Rubric: thiếu stored procedure.', 1;
IF @Functions < 5 THROW 52407, N'Rubric: thiếu function.', 1;
IF @TransactionalProcedures < 5 THROW 52408, N'Rubric: cần ít nhất 5 procedure có transaction và TRY/CATCH.', 1;
IF @Roles < 4 THROW 52409, N'Rubric: thiếu database role.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.database_permissions dp
    INNER JOIN sys.database_principals pr ON pr.principal_id=dp.grantee_principal_id
    WHERE pr.name='rl_GymApp' AND dp.permission_name='EXECUTE' AND dp.state IN ('G','W')
)
    THROW 52410, N'Rubric: rl_GymApp chưa được GRANT EXECUTE.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.database_permissions dp
    INNER JOIN sys.database_principals pr ON pr.principal_id=dp.grantee_principal_id
    WHERE pr.name='rl_GymApp' AND dp.permission_name='SELECT' AND dp.state='D'
)
    THROW 52411, N'Rubric: rl_GymApp chưa bị DENY đọc bảng trực tiếp.', 1;

/* Bằng chứng rollback: thay đổi tạm giá gói rồi rollback, dữ liệu phải giữ nguyên. */
DECLARE @PlanId int = (SELECT TOP (1) PlanId FROM dbo.GoiTap ORDER BY PlanId);
DECLARE @OriginalPrice decimal(18,2) = (SELECT Price FROM dbo.GoiTap WHERE PlanId=@PlanId);
BEGIN TRANSACTION RubricRollback;
UPDATE dbo.GoiTap SET Price=Price+12345 WHERE PlanId=@PlanId;
ROLLBACK TRANSACTION RubricRollback;
IF (SELECT Price FROM dbo.GoiTap WHERE PlanId=@PlanId) <> @OriginalPrice
    THROW 52412, N'Rubric: kiểm thử ROLLBACK thất bại.', 1;

SELECT @Tables AS Tables, @Checks AS TrustedChecks, @Triggers AS EnabledTriggers,
       @Views AS Views, @Indexes AS NonPrimaryIndexes, @Procedures AS Procedures,
       @Functions AS Functions, @TransactionalProcedures AS TransactionalProcedures,
       @Roles AS DatabaseRoles, CAST(1 AS bit) AS RollbackVerified;

PRINT N'ALL RUBRIC DATABASE GATES PASSED.';
GO
