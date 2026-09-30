USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER TRIGGER dbo.trg_LichLop_ValidateTrainerRole
ON dbo.LichLop
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        LEFT JOIN dbo.NhanVien AS nv
            ON nv.EmployeeId = i.TrainerId
            AND nv.EmployeeType = 'TRAINER'
            AND nv.IsActive = 1
        WHERE nv.EmployeeId IS NULL
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52001, N'TrainerId phải là nhân viên đang hoạt động với EmployeeType = TRAINER.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_LichLop_NoOverlap
ON dbo.LichLop
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted WHERE Status <> 'CANCELLED')
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.LichLop AS existing
            ON existing.SessionId <> i.SessionId
            AND existing.Status <> 'CANCELLED'
            AND (existing.RoomId = i.RoomId OR existing.TrainerId = i.TrainerId)
            AND i.StartAt < existing.EndAt
            AND i.EndAt > existing.StartAt
        WHERE i.Status <> 'CANCELLED'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52002, N'Trùng lịch: phòng hoặc huấn luyện viên đã có buổi khác cùng khung giờ.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_LichLop_CapacityWithinRoom
ON dbo.LichLop
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.PhongTap AS r ON r.RoomId = i.RoomId
        WHERE i.Capacity > r.Capacity
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52003, N'Sức chứa buổi lớp vượt quá sức chứa của phòng.', 1;
    END;
END;
GO

/*
    Chặn đầy chỗ. Khóa dòng LichLop bằng UPDLOCK, HOLDLOCK trước khi đếm để
    hai giao dịch insert cùng một buổi phải xếp hàng, không thể cùng đọc "còn
    chỗ". Luồng chính đi qua sp_DatLop_DatCho; trigger này là lớp bảo vệ cuối
    cho trường hợp insert thẳng vào bảng.
*/
CREATE OR ALTER TRIGGER dbo.trg_DatLop_EnforceSessionCapacity
ON dbo.DatLop
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted WHERE Status = 'CONFIRMED')
        RETURN;

    DECLARE @AffectedSessions TABLE (SessionId bigint PRIMARY KEY);
    INSERT @AffectedSessions(SessionId)
    SELECT DISTINCT SessionId FROM inserted WHERE Status = 'CONFIRMED';

    DECLARE @LockedCapacity TABLE (SessionId bigint PRIMARY KEY, Capacity smallint NOT NULL);
    INSERT @LockedCapacity(SessionId, Capacity)
    SELECT l.SessionId, l.Capacity
    FROM dbo.LichLop AS l WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
    INNER JOIN @AffectedSessions AS a ON a.SessionId = l.SessionId;

    DECLARE @Overbooked TABLE (SessionId bigint, Capacity smallint, ConfirmedCount int);
    INSERT @Overbooked(SessionId, Capacity, ConfirmedCount)
    SELECT lc.SessionId, lc.Capacity, COUNT(*)
    FROM @LockedCapacity AS lc
    INNER JOIN dbo.DatLop AS d ON d.SessionId = lc.SessionId AND d.Status = 'CONFIRMED'
    GROUP BY lc.SessionId, lc.Capacity
    HAVING COUNT(*) > lc.Capacity;

    IF EXISTS (SELECT 1 FROM @Overbooked)
    BEGIN
        DECLARE @Message nvarchar(400) =
            N'Buổi lớp đã đầy chỗ: ' +
            (
                SELECT STRING_AGG(CONCAT(N'Session ', SessionId, N' (', ConfirmedCount, N'/', Capacity, N')'), N'; ')
                FROM @Overbooked
            );
        ROLLBACK TRANSACTION;
        THROW 52004, @Message, 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_DatLop_PreventInvalidSessionBooking
ON dbo.DatLop
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted WHERE Status IN ('CONFIRMED', 'WAITLISTED'))
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.LichLop AS l ON l.SessionId = i.SessionId
        WHERE i.Status IN ('CONFIRMED', 'WAITLISTED')
          AND (l.Status IN ('CANCELLED', 'COMPLETED') OR l.StartAt <= SYSUTCDATETIME())
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52005, N'Không thể đặt chỗ: buổi lớp đã hủy, đã kết thúc hoặc đã bắt đầu.', 1;
    END;
END;
GO

PRINT N'Đã tạo 5 trigger cho module Class Operations.';
GO
