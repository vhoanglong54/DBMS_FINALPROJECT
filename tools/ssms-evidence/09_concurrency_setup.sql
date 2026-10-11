USE [GymManagementDemo];
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.ReportConcurrencyEvidence', N'U') IS NOT NULL
    DROP TABLE dbo.ReportConcurrencyEvidence;

CREATE TABLE dbo.ReportConcurrencyEvidence
(
    SessionName varchar(10) NOT NULL,
    StartedAt datetime2(3) NOT NULL,
    FinishedAt datetime2(3) NOT NULL,
    DurationMs int NOT NULL,
    BookingId bigint NOT NULL,
    ResultStatus varchar(20) NOT NULL
);

DECLARE @RoomId int, @ClassId int, @TrainerId int, @SessionId bigint;
SELECT TOP (1) @TrainerId = EmployeeId
FROM dbo.NhanVien
WHERE EmployeeType = 'TRAINER' AND IsActive = 1;

SELECT @RoomId = RoomId FROM dbo.PhongTap WHERE RoomCode = 'EVID-CONC-ROOM';
IF @RoomId IS NOT NULL
BEGIN
    DELETE d
    FROM dbo.DatLop AS d
    INNER JOIN dbo.LichLop AS l ON l.SessionId = d.SessionId
    WHERE l.RoomId = @RoomId;
    DELETE dbo.LichLop WHERE RoomId = @RoomId;
END;

EXEC dbo.sp_PhongTap_Upsert
    @RoomCode = 'EVID-CONC-ROOM',
    @RoomName = N'Phòng kiểm thử cạnh tranh',
    @Capacity = 5,
    @NewRoomId = @RoomId OUTPUT;

EXEC dbo.sp_LopTap_Upsert
    @ClassCode = 'EVID-CONC-CLASS',
    @ClassName = N'Lớp kiểm thử cạnh tranh',
    @DefaultDurationMinutes = 60,
    @NewClassId = @ClassId OUTPUT;

EXEC dbo.sp_LichLop_TaoLich
    @ClassId = @ClassId,
    @RoomId = @RoomId,
    @TrainerId = @TrainerId,
    @StartAt = '2026-12-20T18:00:00',
    @EndAt = '2026-12-20T19:00:00',
    @Capacity = 1,
    @NewSessionId = @SessionId OUTPUT;

SELECT @SessionId AS SessionId, 1 AS Capacity, N'Sẵn sàng chạy hai phiên' AS TrangThai;
GO
