/*
    Benchmark index module Class Operations.
    Chạy từng khối, lưu kết quả tab Messages (STATISTICS IO/TIME) và Actual
    Execution Plan vào docs/evidence/indexes/.
*/

USE [$(DatabaseName)];
GO

-- Khối 0: sinh dữ liệu đủ lớn để thấy khác biệt (chỉ chạy trên DB demo, không chạy trên DB thật)
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

DECLARE @RoomId int, @RoomCapacity smallint;
SELECT TOP (1) @RoomId=RoomId,@RoomCapacity=Capacity FROM dbo.PhongTap ORDER BY Capacity DESC;
DECLARE @ClassId int = (SELECT TOP (1) ClassId FROM dbo.LopTap);
DECLARE @TrainerId int = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'TRAINER');

;WITH n AS (SELECT TOP (20000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
SELECT @ClassId, @RoomId, @TrainerId,
       DATEADD(HOUR, i * 2, '2030-01-01'), DATEADD(HOUR, i * 2 + 1, '2030-01-01'), @RoomCapacity, 'CANCELLED'
FROM n;
GO

-- Khối 1: TRƯỚC index - đếm chỗ đã đặt theo buổi (workload của trigger/procedure đặt chỗ)
DROP INDEX IF EXISTS IX_DatLop_SessionId_Status ON dbo.DatLop;
DROP INDEX IF EXISTS IX_LichLop_RoomId_StartAt_EndAt ON dbo.LichLop;
GO

SET STATISTICS IO, TIME ON;

DECLARE @RoomId int = (SELECT TOP (1) RoomId FROM dbo.PhongTap);

SELECT COUNT(*) FROM dbo.DatLop WHERE SessionId = 1 AND Status = 'CONFIRMED';

SELECT SessionId FROM dbo.LichLop
WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
  AND StartAt < '2030-06-01' AND EndAt > '2030-05-01';

SET STATISTICS IO, TIME OFF;
GO

-- Khối 2: tạo lại index rồi chạy đúng 2 truy vấn trên một lần nữa
CREATE NONCLUSTERED INDEX IX_DatLop_SessionId_Status
    ON dbo.DatLop(SessionId, Status) INCLUDE (MemberId, BookedAt);
CREATE NONCLUSTERED INDEX IX_LichLop_RoomId_StartAt_EndAt
    ON dbo.LichLop(RoomId, StartAt, EndAt) INCLUDE (Status);
GO

SET STATISTICS IO, TIME ON;

DECLARE @RoomId int = (SELECT TOP (1) RoomId FROM dbo.PhongTap);

SELECT COUNT(*) FROM dbo.DatLop WHERE SessionId = 1 AND Status = 'CONFIRMED';

SELECT SessionId FROM dbo.LichLop
WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
  AND StartAt < '2030-06-01' AND EndAt > '2030-05-01';

SET STATISTICS IO, TIME OFF;
GO

-- Khối 3: dọn dữ liệu benchmark
DELETE dbo.LichLop WHERE StartAt >= '2030-01-01' AND Status = 'CANCELLED';
GO
