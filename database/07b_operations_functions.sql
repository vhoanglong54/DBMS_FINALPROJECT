USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/*
    Module: Vận hành lớp, đặt chỗ, check-in (TV3)
    Script: 07b - Function

    Quy ước thời gian (xem docs/TV3_OPERATIONS_CONTRACT.md):
      - Cột audit/sự kiện (BookedAt, CancelledAt, CheckedAt, CreatedAt...) lưu UTC.
      - LichLop.StartAt/EndAt là giờ treo tường tại Việt Nam (UTC+7, không có DST).
      - Mọi so sánh giữa hai loại phải đổi UTC -> giờ VN bằng dbo.fn_GioVN.

    Tập trạng thái chiếm chỗ của DatLop: CONFIRMED, ATTENDED, NO_SHOW.
    WAITLISTED và CANCELLED không chiếm chỗ.
*/

/* 1. Đổi UTC sang giờ Việt Nam (UTC+7). */
CREATE OR ALTER FUNCTION dbo.fn_GioVN(@UtcTime datetime2(0))
RETURNS datetime2(0)
WITH SCHEMABINDING
AS
BEGIN
    RETURN DATEADD(HOUR, 7, @UtcTime);
END;
GO

/* 2. Số chỗ còn trống của một buổi lớp; NULL nếu buổi không tồn tại; âm nếu dữ liệu bị vượt chỗ. */
CREATE OR ALTER FUNCTION dbo.fn_ChoTrongLop(@SessionId bigint)
RETURNS int
AS
BEGIN
    DECLARE @SeatsLeft int;

    SELECT @SeatsLeft = ll.Capacity - COUNT(dl.BookingId)
    FROM dbo.LichLop AS ll
    LEFT JOIN dbo.DatLop AS dl
        ON dl.SessionId = ll.SessionId
       AND dl.Status IN ('CONFIRMED', 'ATTENDED', 'NO_SHOW')
    WHERE ll.SessionId = @SessionId
    GROUP BY ll.Capacity;

    RETURN @SeatsLeft;
END;
GO

/*
    3. Tổng hợp các gói đang hiệu lực của hội viên tại một ngày (giờ VN).
       Luôn trả đúng một dòng; ActiveCount = 0 nghĩa là không có gói hiệu lực.
       Hiệu lực = DangKyGoi.Status = 'ACTIVE' và ngày nằm trong [StartDate, EndDate].
*/
CREATE OR ALTER FUNCTION dbo.fn_GoiHieuLuc(@MemberId int, @Day date)
RETURNS TABLE
AS
RETURN
(
    SELECT
        COUNT(dk.MembershipId) AS ActiveCount,
        MAX(CAST(gt.MaxCheckInsPerDay AS int)) AS MaxCheckInsPerDay,
        MAX(CAST(gt.AllowsClasses AS int)) AS AllowsClasses,
        MAX(dk.EndDate) AS LatestEndDate
    FROM dbo.DangKyGoi AS dk
    INNER JOIN dbo.GoiTap AS gt ON gt.PlanId = dk.PlanId
    WHERE dk.MemberId = @MemberId
      AND dk.Status = 'ACTIVE'
      AND @Day BETWEEN dk.StartDate AND dk.EndDate
);
GO

/*
    4. Điều kiện để hội viên giữ chỗ một buổi lớp. Là nguồn sự thật duy nhất cho
       sp_DatLop, cơ chế đẩy hàng chờ và trigger trg_DatLop_KiemTraDieuKien.
       Không trả dòng nào nếu buổi lớp không tồn tại.
*/
CREATE OR ALTER FUNCTION dbo.fn_DieuKienDatLop(@MemberId int, @SessionId bigint)
RETURNS TABLE
AS
RETURN
(
    SELECT
        CASE WHEN hv.MemberId IS NOT NULL AND hv.IsActive = 1 THEN 1 ELSE 0 END AS MemberActive,
        CASE WHEN g.ActiveCount > 0 THEN 1 ELSE 0 END AS HasActivePlan,
        ISNULL(g.AllowsClasses, 0) AS PlanAllowsClasses,
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM dbo.DatLop AS b
                INNER JOIN dbo.LichLop AS o ON o.SessionId = b.SessionId
                WHERE b.MemberId = @MemberId
                  AND b.SessionId <> ll.SessionId
                  AND b.Status IN ('CONFIRMED', 'ATTENDED', 'NO_SHOW')
                  AND o.Status <> 'CANCELLED'
                  AND o.StartAt < ll.EndAt
                  AND o.EndAt > ll.StartAt
            ) THEN 1
            ELSE 0
        END AS HasOverlap
    FROM dbo.LichLop AS ll
    LEFT JOIN dbo.HoiVien AS hv ON hv.MemberId = @MemberId
    CROSS APPLY dbo.fn_GoiHieuLuc(@MemberId, CONVERT(date, ll.StartAt)) AS g
    WHERE ll.SessionId = @SessionId
);
GO

/* 5. Số lượt check-in của hội viên trong một ngày theo giờ VN (dùng range để tận dụng index). */
CREATE OR ALTER FUNCTION dbo.fn_SoLuotCheckInTrongNgay(@MemberId int, @Day date)
RETURNS int
AS
BEGIN
    DECLARE @DayStartVn datetime2(0) = CAST(@Day AS datetime2(0));
    DECLARE @Total int;

    SELECT @Total = COUNT(*)
    FROM dbo.CheckIn AS ci
    WHERE ci.MemberId = @MemberId
      AND ci.CheckedAt >= DATEADD(HOUR, -7, @DayStartVn)
      AND ci.CheckedAt < DATEADD(HOUR, 17, @DayStartVn);

    RETURN @Total;
END;
GO

/*
    6. Chính sách hủy chỗ: hàng chờ hủy được đến lúc lớp bắt đầu; chỗ đã xác nhận
       chỉ được hủy khi còn ít nhất 2 giờ trước giờ bắt đầu (giờ VN).
       Trả 1 nếu được phép hủy, ngược lại 0.
*/
CREATE OR ALTER FUNCTION dbo.fn_CoTheHuyDatLop(@BookingId bigint, @NowUtc datetime2(0))
RETURNS bit
AS
BEGIN
    DECLARE @CanCancel bit = 0;
    DECLARE @NowVn datetime2(0) = DATEADD(HOUR, 7, @NowUtc);

    SELECT @CanCancel =
        CASE
            WHEN ll.Status <> 'SCHEDULED' THEN 0
            WHEN dl.Status = 'WAITLISTED' AND @NowVn < ll.StartAt THEN 1
            WHEN dl.Status = 'CONFIRMED' AND @NowVn <= DATEADD(HOUR, -2, ll.StartAt) THEN 1
            ELSE 0
        END
    FROM dbo.DatLop AS dl
    INNER JOIN dbo.LichLop AS ll ON ll.SessionId = dl.SessionId
    WHERE dl.BookingId = @BookingId;

    RETURN @CanCancel;
END;
GO

/*
    7. Lịch lớp theo khoảng thời gian kèm số chỗ đã giữ/còn lại/hàng chờ.
       @From/@To giờ VN, khoảng nửa mở [@From, @To). Tham số NULL = không lọc.
*/
CREATE OR ALTER FUNCTION dbo.fn_LichLopTheoKhoang
(
    @From datetime2(0),
    @To datetime2(0),
    @TrainerId int,
    @RoomId int,
    @ClassId int
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        ll.SessionId,
        ll.ClassId,
        lt.ClassCode,
        lt.ClassName,
        ll.RoomId,
        pt.RoomName,
        ll.TrainerId,
        nv.FullName AS TrainerName,
        ll.StartAt,
        ll.EndAt,
        ll.Capacity,
        ll.Status,
        ll.Note,
        ISNULL(bk.SeatsTaken, 0) AS SeatsTaken,
        ll.Capacity - ISNULL(bk.SeatsTaken, 0) AS SeatsLeft,
        ISNULL(bk.WaitlistCount, 0) AS WaitlistCount,
        ll.RowVersion
    FROM dbo.LichLop AS ll
    INNER JOIN dbo.LopTap AS lt ON lt.ClassId = ll.ClassId
    INNER JOIN dbo.PhongTap AS pt ON pt.RoomId = ll.RoomId
    INNER JOIN dbo.NhanVien AS nv ON nv.EmployeeId = ll.TrainerId
    OUTER APPLY
    (
        SELECT
            SUM(CASE WHEN dl.Status IN ('CONFIRMED', 'ATTENDED', 'NO_SHOW') THEN 1 ELSE 0 END) AS SeatsTaken,
            SUM(CASE WHEN dl.Status = 'WAITLISTED' THEN 1 ELSE 0 END) AS WaitlistCount
        FROM dbo.DatLop AS dl
        WHERE dl.SessionId = ll.SessionId
    ) AS bk
    WHERE ll.StartAt >= @From
      AND ll.StartAt < @To
      AND (@TrainerId IS NULL OR ll.TrainerId = @TrainerId)
      AND (@RoomId IS NULL OR ll.RoomId = @RoomId)
      AND (@ClassId IS NULL OR ll.ClassId = @ClassId)
);
GO

PRINT N'07b: đã tạo 7 function vận hành lớp.';
GO
