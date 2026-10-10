/* GYM-09: parameterized read procedures; app service role never reads base tables. */
USE [$(DatabaseName)];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TV4_TimKiemHoiVien
    @Query nvarchar(120) = NULL,
    @Status varchar(20) = NULL,
    @Page int = 1,
    @PageSize int = 20,
    @TotalCount int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 SET @PageSize = 20;
    IF @PageSize > 100 SET @PageSize = 100;
    SET @Query = NULLIF(LTRIM(RTRIM(@Query)), N'');
    SET @Status = NULLIF(LTRIM(RTRIM(@Status)), '');

    DECLARE @Pattern nvarchar(252) = NULL;
    IF @Query IS NOT NULL
        SET @Pattern = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@Query, N'~', N'~~'), N'%', N'~%'), N'_', N'~_'), N'[', N'~[') + N'%';

    SELECT @TotalCount = COUNT(1)
    FROM dbo.vw_TV4_HoiVienTraCuu AS hv
    WHERE (@Pattern IS NULL OR hv.MemberName LIKE @Pattern ESCAPE N'~'
        OR hv.MemberCode LIKE @Pattern ESCAPE N'~'
        OR hv.Phone LIKE @Pattern ESCAPE N'~')
      AND (@Status IS NULL OR hv.MembershipStatus = @Status);

    SELECT MemberId, MemberCode, MemberName, Phone, Email, MembershipStatus, StartDate, EndDate
    FROM dbo.vw_TV4_HoiVienTraCuu AS hv
    WHERE (@Pattern IS NULL OR hv.MemberName LIKE @Pattern ESCAPE N'~'
        OR hv.MemberCode LIKE @Pattern ESCAPE N'~'
        OR hv.Phone LIKE @Pattern ESCAPE N'~')
      AND (@Status IS NULL OR hv.MembershipStatus = @Status)
    ORDER BY hv.MemberName, hv.MemberId
    OFFSET (CONVERT(bigint, @Page) - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TV4_DashboardHoiVien
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        SUM(CASE WHEN MembershipStatus = 'ACTIVE' THEN 1 ELSE 0 END) AS ActiveMembers,
        SUM(CASE WHEN MembershipStatus = 'EXPIRED' THEN 1 ELSE 0 END) AS ExpiredMembers
    FROM dbo.vw_TV4_HoiVienTraCuu;

    SELECT TOP (8) MaHV AS MemberId, HoTen AS MemberName, SoDienThoai AS Phone,
           TenGoi AS PlanName, NgayKetThuc AS EndDate, SoNgayConLai AS DaysRemaining
    FROM dbo.vw_HoiVienSapHetHan
    ORDER BY NgayKetThuc, MaHV;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TV4_BaoCaoDoanhThu
    @FromDate date,
    @ToDate date
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NULL OR @ToDate IS NULL OR @FromDate > @ToDate
        THROW 51190, N'Khoảng ngày báo cáo không hợp lệ.', 1;
    SELECT RevenueDate, Revenue, PaymentCount
    FROM dbo.vw_TV4_DoanhThuTheoNgay
    WHERE RevenueDate >= @FromDate AND RevenueDate <= @ToDate
    ORDER BY RevenueDate;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TV4_BaoCaoCongSuatLop
    @FromDate date,
    @ToDate date
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NULL OR @ToDate IS NULL OR @FromDate > @ToDate
        THROW 51191, N'Khoảng ngày báo cáo không hợp lệ.', 1;
    SELECT schedule.SessionId, schedule.ClassName, schedule.RoomName, schedule.TrainerName,
           schedule.StartAt, schedule.EndAt, schedule.Capacity,
           schedule.SeatsTaken AS Booked,
           dbo.fn_ChoTrongLop(schedule.SessionId) AS Available,
           schedule.Status
    FROM dbo.fn_LichLopTheoKhoang(
        CONVERT(datetime2(0), @FromDate),
        DATEADD(DAY, 1, CONVERT(datetime2(0), @ToDate)),
        NULL, NULL, NULL) AS schedule
    ORDER BY schedule.StartAt DESC, schedule.ClassName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TV4_BaoCaoDiemDanh
    @FromDate date,
    @ToDate date
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NULL OR @ToDate IS NULL OR @FromDate > @ToDate
        THROW 51192, N'Khoảng ngày báo cáo không hợp lệ.', 1;
    SELECT CheckInId, MemberId, MemberCode, MemberName, RecordedByEmployee,
           ClassName, SessionId, SessionStartAt, DATEADD(HOUR, 7, CheckedAt) AS CheckedAt, CheckInMethod
    FROM dbo.vw_LichSuCheckIn
    WHERE CheckedAt >= DATEADD(HOUR, -7, CONVERT(datetime2(0), @FromDate))
      AND CheckedAt < DATEADD(HOUR, -7, DATEADD(DAY, 1, CONVERT(datetime2(0), @ToDate)))
    ORDER BY CheckedAt DESC, CheckInId DESC;
END;
GO

PRINT N'GYM-09: đã tạo thủ tục dashboard và báo cáo phân trang.';
GO
