USE [GymManagementDemo];
GO

SET NOCOUNT ON;

SELECT
    [Phien] = SessionName,
    [BatDauUTC] = StartedAt,
    [KetThucUTC] = FinishedAt,
    [ThoiGianMs] = DurationMs,
    BookingId,
    [TrangThai] = ResultStatus
FROM dbo.ReportConcurrencyEvidence
ORDER BY SessionName;

SELECT
    m.MemberCode,
    [TrangThaiDatCho] = d.Status,
    [SucChua] = l.Capacity,
    [SoChoDaXacNhan] = SUM(CASE WHEN d.Status = 'CONFIRMED' THEN 1 ELSE 0 END) OVER (),
    [KetQua] = CASE
        WHEN SUM(CASE WHEN d.Status = 'CONFIRMED' THEN 1 ELSE 0 END) OVER () <= l.Capacity
             AND COUNT(*) OVER () = 2
        THEN N'PASS - không vượt sức chứa'
        ELSE N'FAIL'
    END
FROM dbo.LichLop AS l
INNER JOIN dbo.PhongTap AS r ON r.RoomId = l.RoomId
INNER JOIN dbo.DatLop AS d ON d.SessionId = l.SessionId
INNER JOIN dbo.HoiVien AS m ON m.MemberId = d.MemberId
WHERE r.RoomCode = 'EVID-CONC-ROOM'
ORDER BY d.BookedAt, d.BookingId;
GO
