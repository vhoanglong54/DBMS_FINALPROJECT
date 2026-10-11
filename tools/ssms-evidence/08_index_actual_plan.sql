USE [GymManagementDemo];
GO

DECLARE @RoomId int = (SELECT TOP (1) RoomId FROM dbo.PhongTap ORDER BY Capacity DESC);

SELECT SessionId, RoomId, StartAt, EndAt, Status
FROM dbo.LichLop
WHERE RoomId = @RoomId
  AND Status <> 'CANCELLED'
  AND StartAt < '2030-06-01'
  AND EndAt > '2030-05-01';
GO
