USE [$(DatabaseName)];
GO

/* ============================================================
   PhongTap
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_PhongTap_Upsert
    @RoomId     int = NULL,
    @RoomCode   varchar(20),
    @RoomName   nvarchar(100),
    @Capacity   smallint,
    @Location   nvarchar(200) = NULL,
    @NewRoomId  int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @RoomId IS NULL
        BEGIN
            INSERT dbo.PhongTap(RoomCode, RoomName, Capacity, Location)
            VALUES (@RoomCode, @RoomName, @Capacity, @Location);

            SET @NewRoomId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.PhongTap
            SET RoomCode = @RoomCode,
                RoomName = @RoomName,
                Capacity = @Capacity,
                Location = @Location,
                UpdatedAt = SYSUTCDATETIME()
            WHERE RoomId = @RoomId;

            IF @@ROWCOUNT = 0
                THROW 52101, N'Không tìm thấy phòng tập để cập nhật.', 1;

            SET @NewRoomId = @RoomId;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_PhongTap_SetActive
    @RoomId     int,
    @IsActive   bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE dbo.PhongTap
    SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME()
    WHERE RoomId = @RoomId;

    IF @@ROWCOUNT = 0
        THROW 52102, N'Không tìm thấy phòng tập.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_PhongTap_DanhSach
    @IncludeInactive bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT RoomId, RoomCode, RoomName, Capacity, Location, IsActive
    FROM dbo.PhongTap
    WHERE IsActive = 1 OR @IncludeInactive = 1
    ORDER BY RoomName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_PhongTap_ChiTiet
    @RoomId int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT RoomId, RoomCode, RoomName, Capacity, Location, IsActive
    FROM dbo.PhongTap
    WHERE RoomId = @RoomId;
END;
GO

/* ============================================================
   LopTap
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_LopTap_Upsert
    @ClassId                int = NULL,
    @ClassCode              varchar(20),
    @ClassName              nvarchar(120),
    @Description            nvarchar(500) = NULL,
    @DefaultDurationMinutes smallint,
    @DifficultyLevel        varchar(20) = 'ALL_LEVELS',
    @NewClassId             int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @ClassId IS NULL
        BEGIN
            INSERT dbo.LopTap(ClassCode, ClassName, Description, DefaultDurationMinutes, DifficultyLevel)
            VALUES (@ClassCode, @ClassName, @Description, @DefaultDurationMinutes, @DifficultyLevel);

            SET @NewClassId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.LopTap
            SET ClassCode = @ClassCode,
                ClassName = @ClassName,
                Description = @Description,
                DefaultDurationMinutes = @DefaultDurationMinutes,
                DifficultyLevel = @DifficultyLevel,
                UpdatedAt = SYSUTCDATETIME()
            WHERE ClassId = @ClassId;

            IF @@ROWCOUNT = 0
                THROW 52111, N'Không tìm thấy loại lớp để cập nhật.', 1;

            SET @NewClassId = @ClassId;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LopTap_SetActive
    @ClassId    int,
    @IsActive   bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE dbo.LopTap
    SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME()
    WHERE ClassId = @ClassId;

    IF @@ROWCOUNT = 0
        THROW 52112, N'Không tìm thấy loại lớp.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LopTap_DanhSach
    @IncludeInactive bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ClassId, ClassCode, ClassName, Description, DefaultDurationMinutes, DifficultyLevel, IsActive
    FROM dbo.LopTap
    WHERE IsActive = 1 OR @IncludeInactive = 1
    ORDER BY ClassName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LopTap_ChiTiet
    @ClassId int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ClassId, ClassCode, ClassName, Description, DefaultDurationMinutes, DifficultyLevel, IsActive
    FROM dbo.LopTap
    WHERE ClassId = @ClassId;
END;
GO

/* ============================================================
   LichLop
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_LichLop_TaoLich
    @ClassId    int,
    @RoomId     int,
    @TrainerId  int,
    @StartAt    datetime2(0),
    @EndAt      datetime2(0),
    @Capacity   smallint = NULL,
    @Note       nvarchar(500) = NULL,
    @NewSessionId bigint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.LopTap WHERE ClassId = @ClassId AND IsActive = 1)
            THROW 52121, N'Loại lớp không tồn tại hoặc đã ngừng hoạt động.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.PhongTap WHERE RoomId = @RoomId AND IsActive = 1)
            THROW 52122, N'Phòng tập không tồn tại hoặc đang ngừng sử dụng.', 1;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.NhanVien
            WHERE EmployeeId = @TrainerId AND EmployeeType = 'TRAINER' AND IsActive = 1
        )
            THROW 52123, N'Huấn luyện viên không hợp lệ hoặc không hoạt động.', 1;

        IF @Capacity IS NULL
            SELECT @Capacity = Capacity FROM dbo.PhongTap WHERE RoomId = @RoomId;

        BEGIN TRANSACTION;

        INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Note)
        VALUES (@ClassId, @RoomId, @TrainerId, @StartAt, @EndAt, @Capacity, @Note);

        SET @NewSessionId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LichLop_HuyLich
    @SessionId  bigint,
    @Reason     nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.LichLop
        SET Status = 'CANCELLED', UpdatedAt = SYSUTCDATETIME()
        WHERE SessionId = @SessionId AND Status NOT IN ('CANCELLED', 'COMPLETED');

        IF @@ROWCOUNT = 0
            THROW 52131, N'Buổi lớp không tồn tại hoặc đã kết thúc/hủy trước đó.', 1;

        UPDATE dbo.DatLop
        SET Status = 'CANCELLED',
            CancelledAt = SYSUTCDATETIME(),
            CancellationReason = @Reason,
            UpdatedAt = SYSUTCDATETIME()
        WHERE SessionId = @SessionId AND Status IN ('CONFIRMED', 'WAITLISTED');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LichLop_DanhSach
    @TuNgay  date,
    @DenNgay date
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SessionId, ClassId, ClassName, RoomId, RoomName, TrainerId, TrainerName,
           StartAt, EndAt, Capacity, ConfirmedCount, SeatsLeft, Status
    FROM dbo.fn_LichLop_TheoTuan(@TuNgay, @DenNgay)
    ORDER BY StartAt;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LichLop_ChiTiet
    @SessionId bigint
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SessionId, ClassId, ClassName, RoomId, RoomName, TrainerId, TrainerName,
           StartAt, EndAt, Capacity, ConfirmedCount, SeatsLeft, Status
    FROM dbo.vw_LichLop_ConCho
    WHERE SessionId = @SessionId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_NhanVien_DanhSachHLV
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EmployeeId, FullName
    FROM dbo.NhanVien
    WHERE EmployeeType = 'TRAINER' AND IsActive = 1
    ORDER BY FullName;
END;
GO

/* ============================================================
   DatLop - trọng tâm concurrency
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_DatLop_DatCho
    @MemberId       int,
    @SessionId      bigint,
    @NewBookingId   bigint = NULL OUTPUT,
    @ResultStatus   varchar(20) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Capacity smallint, @StartAt datetime2(0), @SessionStatus varchar(20);

        /*
            Database bật READ_COMMITTED_SNAPSHOT nên đọc thường không tự chặn nhau.
            UPDLOCK + HOLDLOCK trên dòng LichLop buộc các giao dịch đặt chỗ cùng một
            buổi phải xếp hàng trước khi đếm chỗ.
        */
        SELECT @Capacity = Capacity, @StartAt = StartAt, @SessionStatus = Status
        FROM dbo.LichLop WITH (UPDLOCK, HOLDLOCK, ROWLOCK)
        WHERE SessionId = @SessionId;

        IF @Capacity IS NULL
            THROW 52141, N'Buổi lớp không tồn tại.', 1;

        IF @SessionStatus IN ('CANCELLED', 'COMPLETED') OR @StartAt <= SYSUTCDATETIME()
            THROW 52142, N'Buổi lớp không còn nhận đặt chỗ.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.DatLop
            WHERE MemberId = @MemberId AND SessionId = @SessionId AND Status <> 'CANCELLED'
        )
            THROW 52143, N'Hội viên đã đặt chỗ buổi lớp này rồi.', 1;

        IF dbo.fn_HoiVien_CoGoiHieuLuc(@MemberId, CAST(GETDATE() AS date)) = 0
            THROW 52144, N'Hội viên không có gói tập còn hiệu lực.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.DangKyGoi AS dk
            INNER JOIN dbo.GoiTap AS g ON g.PlanId = dk.PlanId
            WHERE dk.MemberId = @MemberId
              AND dk.Status = 'ACTIVE'
              AND g.AllowsClasses = 1
              AND CAST(GETDATE() AS date) BETWEEN dk.StartDate AND dk.EndDate
        )
            THROW 52145, N'Gói tập hiện tại không bao gồm quyền đặt lớp.', 1;

        DECLARE @ConfirmedCount int;
        SELECT @ConfirmedCount = COUNT(*)
        FROM dbo.DatLop
        WHERE SessionId = @SessionId AND Status = 'CONFIRMED';

        SET @ResultStatus = CASE WHEN @ConfirmedCount < @Capacity THEN 'CONFIRMED' ELSE 'WAITLISTED' END;

        INSERT dbo.DatLop(MemberId, SessionId, Status)
        VALUES (@MemberId, @SessionId, @ResultStatus);

        SET @NewBookingId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DatLop_HuyCho
    @BookingId  bigint,
    @Reason     nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SessionId bigint, @PreviousStatus varchar(20);

        SELECT @SessionId = SessionId, @PreviousStatus = Status
        FROM dbo.DatLop WITH (UPDLOCK, ROWLOCK)
        WHERE BookingId = @BookingId;

        IF @SessionId IS NULL
            THROW 52151, N'Không tìm thấy lượt đặt chỗ.', 1;

        IF @PreviousStatus = 'CANCELLED'
            THROW 52152, N'Lượt đặt chỗ đã được hủy trước đó.', 1;

        UPDATE dbo.DatLop
        SET Status = 'CANCELLED',
            CancelledAt = SYSUTCDATETIME(),
            CancellationReason = @Reason,
            UpdatedAt = SYSUTCDATETIME()
        WHERE BookingId = @BookingId;

        IF @PreviousStatus = 'CONFIRMED'
        BEGIN
            DECLARE @PromoteBookingId bigint;

            SELECT TOP (1) @PromoteBookingId = BookingId
            FROM dbo.DatLop WITH (UPDLOCK, ROWLOCK)
            WHERE SessionId = @SessionId AND Status = 'WAITLISTED'
            ORDER BY BookedAt ASC, BookingId ASC;

            IF @PromoteBookingId IS NOT NULL
                UPDATE dbo.DatLop
                SET Status = 'CONFIRMED', UpdatedAt = SYSUTCDATETIME()
                WHERE BookingId = @PromoteBookingId;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DatLop_DanhSachTheoBuoi
    @SessionId bigint
AS
BEGIN
    SET NOCOUNT ON;

    SELECT d.BookingId, d.MemberId, m.MemberCode, m.FullName AS MemberName,
           d.Status, d.BookedAt, d.CancelledAt, d.CancellationReason
    FROM dbo.DatLop AS d
    INNER JOIN dbo.HoiVien AS m ON m.MemberId = d.MemberId
    WHERE d.SessionId = @SessionId
    ORDER BY d.BookedAt, d.BookingId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HoiVien_TimKiemNhanh
    @Keyword nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (20) MemberId, MemberCode, FullName, Phone,
           dbo.fn_HoiVien_CoGoiHieuLuc(MemberId, CAST(GETDATE() AS date)) AS HasActivePlan
    FROM dbo.HoiVien
    WHERE IsActive = 1
      AND (MemberCode LIKE @Keyword + N'%' OR FullName LIKE N'%' + @Keyword + N'%' OR Phone LIKE @Keyword + N'%')
    ORDER BY FullName;
END;
GO

/* ============================================================
   CheckIn
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_CheckIn_GhiNhan
    @MemberId       int,
    @EmployeeId     int,
    @SessionId      bigint = NULL,
    @CheckInMethod  varchar(20) = 'FRONT_DESK',
    @NewCheckInId   bigint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF dbo.fn_HoiVien_CoGoiHieuLuc(@MemberId, CAST(GETDATE() AS date)) = 0
            THROW 52161, N'Hội viên không có gói tập còn hiệu lực để check-in.', 1;

        DECLARE @MaxPerDay tinyint;
        SELECT @MaxPerDay = MAX(g.MaxCheckInsPerDay)
        FROM dbo.DangKyGoi AS dk
        INNER JOIN dbo.GoiTap AS g ON g.PlanId = dk.PlanId
        WHERE dk.MemberId = @MemberId
          AND dk.Status = 'ACTIVE'
          AND CAST(GETDATE() AS date) BETWEEN dk.StartDate AND dk.EndDate;

        -- CheckedAt lưu UTC, nên đổi nửa đêm giờ máy chủ sang UTC để đếm đúng "hôm nay".
        DECLARE @DayStartUtc datetime2(0) =
            DATEADD(SECOND, DATEDIFF(SECOND, GETDATE(), SYSUTCDATETIME()),
                    CAST(CAST(GETDATE() AS date) AS datetime2(0)));

        DECLARE @TodayCount int;
        SELECT @TodayCount = COUNT(*)
        FROM dbo.CheckIn
        WHERE MemberId = @MemberId AND CheckedAt >= @DayStartUtc;

        IF @MaxPerDay IS NOT NULL AND @TodayCount >= @MaxPerDay
            THROW 52162, N'Hội viên đã đạt số lượt check-in tối đa hôm nay theo gói tập.', 1;

        IF @SessionId IS NOT NULL
        BEGIN
            UPDATE dbo.DatLop
            SET Status = 'ATTENDED', UpdatedAt = SYSUTCDATETIME()
            WHERE MemberId = @MemberId AND SessionId = @SessionId AND Status = 'CONFIRMED';

            IF @@ROWCOUNT = 0
                THROW 52163, N'Hội viên chưa có lượt đặt chỗ CONFIRMED cho buổi lớp này.', 1;
        END;

        INSERT dbo.CheckIn(MemberId, EmployeeId, SessionId, CheckInMethod)
        VALUES (@MemberId, @EmployeeId, @SessionId, @CheckInMethod);

        SET @NewCheckInId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CheckIn_LichSu
    @MemberId int = NULL,
    @Top      int = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top) CheckInId, MemberId, MemberCode, MemberName, RecordedByEmployee,
           ClassName, SessionId, SessionStartAt, CheckedAt, CheckInMethod
    FROM dbo.vw_LichSuCheckIn
    WHERE @MemberId IS NULL OR MemberId = @MemberId
    ORDER BY CheckedAt DESC;
END;
GO

PRINT N'Đã tạo 19 stored procedure cho module Class Operations.';
GO
