/*
    Benchmark index module Class Operations.
    Chạy từng khối, lưu kết quả tab Messages (STATISTICS IO/TIME) và Actual
    Execution Plan vào docs/evidence/indexes/.
*/

USE [GymManagementDB];
GO

-- Khối 0: sinh dữ liệu đủ lớn để thấy khác biệt (chỉ chạy trên DB demo, không chạy trên DB thật)
SET NOCOUNT ON;

DECLARE @RoomId int = (SELECT TOP (1) RoomId FROM dbo.PhongTap);
DECLARE @ClassId int = (SELECT TOP (1) ClassId FROM dbo.LopTap);
DECLARE @TrainerId int = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'TRAINER');

;WITH n AS (SELECT TOP (20000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
SELECT @ClassId, @RoomId, @TrainerId,
       DATEADD(HOUR, i * 2, '2030-01-01'), DATEADD(HOUR, i * 2 + 1, '2030-01-01'), 10, 'CANCELLED'
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
:r ..\..\database\05b_operations_indexes.sql
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
