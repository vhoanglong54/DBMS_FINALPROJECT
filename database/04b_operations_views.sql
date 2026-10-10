USE [$(DatabaseName)];
GO

/*
    Quy ước: StartAt/EndAt của LichLop là giờ địa phương do nhân viên nhập
    (một cơ sở, không quy đổi múi giờ). Chỉ cột audit mới theo UTC.
*/

CREATE OR ALTER VIEW dbo.vw_LichLop_ConCho
AS
    SELECT
        l.SessionId,
        lt.ClassId,
        lt.ClassName,
        r.RoomId,
        r.RoomName,
        nv.EmployeeId AS TrainerId,
        nv.FullName AS TrainerName,
        l.StartAt,
        l.EndAt,
        l.Capacity,
        ISNULL(b.ConfirmedCount, 0) AS ConfirmedCount,
        l.Capacity - ISNULL(b.ConfirmedCount, 0) AS SeatsLeft,
        l.Status
    FROM dbo.LichLop AS l
    INNER JOIN dbo.LopTap AS lt ON lt.ClassId = l.ClassId
    INNER JOIN dbo.PhongTap AS r ON r.RoomId = l.RoomId
    INNER JOIN dbo.NhanVien AS nv ON nv.EmployeeId = l.TrainerId
    OUTER APPLY
    (
        SELECT COUNT(*) AS ConfirmedCount
        FROM dbo.DatLop AS d
        WHERE d.SessionId = l.SessionId AND d.Status = 'CONFIRMED'
    ) AS b;
GO

CREATE OR ALTER VIEW dbo.vw_LichLop_HomNay
AS
    SELECT *
    FROM dbo.vw_LichLop_ConCho
    WHERE CAST(StartAt AS date) = CAST(GETDATE() AS date);
GO

CREATE OR ALTER VIEW dbo.vw_CongSuatLop
AS
    SELECT
        lt.ClassId,
        lt.ClassName,
        COUNT(DISTINCT l.SessionId) AS TotalSessions,
        SUM(l.Capacity) AS TotalCapacity,
        SUM(ISNULL(b.ConfirmedCount, 0)) AS TotalBooked,
        CAST(ROUND(100.0 * SUM(ISNULL(b.ConfirmedCount, 0)) / NULLIF(SUM(l.Capacity), 0), 1) AS decimal(5,1)) AS UtilizationPercent
    FROM dbo.LopTap AS lt
    INNER JOIN dbo.LichLop AS l ON l.ClassId = lt.ClassId AND l.Status <> 'CANCELLED'
    OUTER APPLY
    (
        SELECT COUNT(*) AS ConfirmedCount
        FROM dbo.DatLop AS d
        WHERE d.SessionId = l.SessionId AND d.Status = 'CONFIRMED'
    ) AS b
    GROUP BY lt.ClassId, lt.ClassName;
GO

CREATE OR ALTER VIEW dbo.vw_LichSuCheckIn
AS
    SELECT
        c.CheckInId,
        m.MemberId,
        m.MemberCode,
        m.FullName AS MemberName,
        e.FullName AS RecordedByEmployee,
        lt.ClassName,
        l.SessionId,
        l.StartAt AS SessionStartAt,
        c.CheckedAt,
        c.CheckInMethod
    FROM dbo.CheckIn AS c
    INNER JOIN dbo.HoiVien AS m ON m.MemberId = c.MemberId
    INNER JOIN dbo.NhanVien AS e ON e.EmployeeId = c.EmployeeId
    LEFT JOIN dbo.LichLop AS l ON l.SessionId = c.SessionId
    LEFT JOIN dbo.LopTap AS lt ON lt.ClassId = l.ClassId;
GO

PRINT N'Đã tạo 4 view cho module Class Operations.';
GO
