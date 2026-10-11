USE [GymManagementDemo];
GO

SET NOCOUNT ON;
DECLARE @RoomId int = (SELECT RoomId FROM dbo.PhongTap WHERE RoomCode = 'EVID-CONC-ROOM');

DELETE d
FROM dbo.DatLop AS d
INNER JOIN dbo.LichLop AS l ON l.SessionId = d.SessionId
WHERE l.RoomId = @RoomId;

DELETE dbo.LichLop WHERE RoomId = @RoomId;
DROP TABLE IF EXISTS dbo.ReportConcurrencyEvidence;
GO
