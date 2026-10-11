USE [GymManagementDemo];
GO

SET NOCOUNT ON;
DECLARE @SessionId bigint =
(
    SELECT TOP (1) l.SessionId
    FROM dbo.LichLop AS l
    INNER JOIN dbo.PhongTap AS r ON r.RoomId = l.RoomId
    WHERE r.RoomCode = 'EVID-CONC-ROOM'
    ORDER BY l.SessionId DESC
);
DECLARE @StartedAt datetime2(3) = SYSUTCDATETIME();
DECLARE @BookingId bigint, @ResultStatus varchar(20);

EXEC dbo.sp_DatLop_DatCho
    @MemberId = 2,
    @SessionId = @SessionId,
    @NewBookingId = @BookingId OUTPUT,
    @ResultStatus = @ResultStatus OUTPUT;

DECLARE @FinishedAt datetime2(3) = SYSUTCDATETIME();
INSERT dbo.ReportConcurrencyEvidence
    (SessionName, StartedAt, FinishedAt, DurationMs, BookingId, ResultStatus)
VALUES
    ('B', @StartedAt, @FinishedAt, DATEDIFF(MILLISECOND, @StartedAt, @FinishedAt), @BookingId, @ResultStatus);
GO
