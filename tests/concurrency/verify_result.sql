USE [$(DatabaseName)];
GO

DECLARE @DemoSessionId bigint = 0; -- <-- điền SessionId đã dùng

SELECT d.BookingId, m.MemberCode, d.Status, d.BookedAt
FROM dbo.DatLop AS d
INNER JOIN dbo.HoiVien AS m ON m.MemberId = d.MemberId
WHERE d.SessionId = @DemoSessionId
ORDER BY d.BookedAt, d.BookingId;

-- Đúng: 1 dòng CONFIRMED (HV0001) + 1 dòng WAITLISTED (HV0002).
SELECT dbo.fn_ChoTrongLop(@DemoSessionId) AS SoChoConLai; -- kỳ vọng 0
GO
