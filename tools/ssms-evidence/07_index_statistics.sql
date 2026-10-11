USE [GymManagementDemo];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @RoomId int = (SELECT TOP (1) RoomId FROM dbo.PhongTap ORDER BY Capacity DESC);
DECLARE @ClassId int = (SELECT TOP (1) ClassId FROM dbo.LopTap ORDER BY ClassId);
DECLARE @TrainerId int = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'TRAINER');

;WITH n AS
(
    SELECT TOP (20000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects AS a CROSS JOIN sys.all_objects AS b
)
INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
SELECT @ClassId, @RoomId, @TrainerId,
       DATEADD(HOUR, i * 2, '2030-01-01'),
       DATEADD(HOUR, i * 2 + 1, '2030-01-01'),
       1, 'CANCELLED'
FROM n;

DROP INDEX IF EXISTS IX_LichLop_RoomId_StartAt_EndAt ON dbo.LichLop;

PRINT N'========== TRƯỚC INDEX ==========';
SET STATISTICS IO, TIME ON;
SELECT SessionId
FROM dbo.LichLop
WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
  AND StartAt < '2030-06-01' AND EndAt > '2030-05-01';
SET STATISTICS IO, TIME OFF;

CREATE NONCLUSTERED INDEX IX_LichLop_RoomId_StartAt_EndAt
    ON dbo.LichLop(RoomId, Status, StartAt, EndAt);

PRINT N'========== SAU INDEX ==========';
SET STATISTICS IO, TIME ON;
SELECT SessionId
FROM dbo.LichLop
WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
  AND StartAt < '2030-06-01' AND EndAt > '2030-05-01';
SET STATISTICS IO, TIME OFF;

ROLLBACK TRANSACTION;

SELECT
    [IndexDaDuocKhoiPhuc] = i.name,
    [Bang] = OBJECT_NAME(i.object_id),
    [Kieu] = i.type_desc,
    [KetQua] = N'Benchmark chạy trong transaction và đã rollback dữ liệu thử'
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'dbo.LichLop')
  AND i.name = N'IX_LichLop_RoomId_StartAt_EndAt';
GO
