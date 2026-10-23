-- PHẦN 6B — TV3: 19 stored procedure phòng, lớp, lịch, đặt/hủy chỗ và check-in.
-- Các khối PhongTap/LopTap/LichLop/DatLop/CheckIn bên dưới là điểm vào nghiệp vụ của web.
USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
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
            IF EXISTS
            (
                SELECT 1 FROM dbo.LichLop
                WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
                  AND EndAt > dbo.fn_GioVN(SYSUTCDATETIME())
                  AND Capacity > @Capacity
            )
                THROW 52103, N'Không thể giảm sức chứa phòng dưới sức chứa của buổi lớp sắp tới.', 1;

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

    IF @IsActive = 0 AND EXISTS
    (
        SELECT 1 FROM dbo.LichLop
        WHERE RoomId = @RoomId AND Status <> 'CANCELLED'
          AND EndAt > dbo.fn_GioVN(SYSUTCDATETIME())
    )
        THROW 52104, N'Phòng còn buổi lớp sắp tới; hãy xử lý lịch trước khi ngừng phòng.', 1;

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

    IF @IsActive = 0 AND EXISTS
    (
        SELECT 1 FROM dbo.LichLop
        WHERE ClassId = @ClassId AND Status <> 'CANCELLED'
          AND EndAt > dbo.fn_GioVN(SYSUTCDATETIME())
    )
        THROW 52113, N'Loại lớp còn buổi sắp tới; hãy xử lý lịch trước khi ngừng lớp.', 1;

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
-- TRANSACTION TV3 — tạo buổi lớp; ràng buộc và trigger kiểm HLV, trùng lịch, sức chứa.
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

        IF @StartAt <= dbo.fn_GioVN(SYSUTCDATETIME())
            THROW 52124, N'Không thể tạo buổi lớp trong quá khứ.', 1;

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

        IF NULLIF(LTRIM(RTRIM(@Reason)), N'') IS NULL
            THROW 52132, N'Phải nhập lý do hủy buổi lớp.', 1;

        UPDATE dbo.LichLop
        SET Status = 'CANCELLED', UpdatedAt = SYSUTCDATETIME()
        WHERE SessionId = @SessionId AND Status = 'SCHEDULED'
          AND StartAt > dbo.fn_GioVN(SYSUTCDATETIME());

        IF @@ROWCOUNT = 0
            THROW 52131, N'Chỉ được hủy buổi lớp chưa bắt đầu và còn ở trạng thái đã lên lịch.', 1;

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
           StartAt, EndAt, Capacity, SeatsTaken AS ConfirmedCount, SeatsLeft, Status
    FROM dbo.fn_LichLopTheoKhoang(CONVERT(datetime2(0), @TuNgay),
         DATEADD(DAY, 1, CONVERT(datetime2(0), @DenNgay)), NULL, NULL, NULL)
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
-- TRANSACTION TV3 — giữ khóa hội viên rồi khóa buổi lớp trước khi xét điều kiện và đếm chỗ.
-- Còn chỗ thì CONFIRMED; hết chỗ thì WAITLISTED, không tạo booking trùng khi đặt lại.
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

        SET @NewBookingId = NULL;
        SET @ResultStatus = NULL;

        -- Giữ dòng hội viên đến COMMIT. Hủy gói cũng phải lấy khóa này,
        -- nên không thể đi qua khi một lượt đặt còn đang ghi.
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.HoiVien WITH (UPDLOCK, HOLDLOCK)
            WHERE MemberId = @MemberId AND IsActive = 1
        )
            THROW 52146, N'Hội viên không tồn tại hoặc đã ngừng hoạt động.', 1;

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

        IF @SessionStatus <> 'SCHEDULED' OR @StartAt <= dbo.fn_GioVN(SYSUTCDATETIME())
            THROW 52142, N'Buổi lớp không còn nhận đặt chỗ.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.DatLop
            WHERE MemberId = @MemberId AND SessionId = @SessionId AND Status <> 'CANCELLED'
        )
            THROW 52143, N'Hội viên đã đặt chỗ buổi lớp này rồi.', 1;

        DECLARE @HasActivePlan int, @PlanAllowsClasses int, @HasOverlap int;
        SELECT @HasActivePlan = HasActivePlan,
               @PlanAllowsClasses = PlanAllowsClasses,
               @HasOverlap = HasOverlap
        FROM dbo.fn_DieuKienDatLop(@MemberId, @SessionId);

        IF ISNULL(@HasActivePlan, 0) = 0
            THROW 52144, N'Hội viên không có gói tập còn hiệu lực vào ngày học.', 1;
        IF ISNULL(@PlanAllowsClasses, 0) = 0
            THROW 52145, N'Gói tập hiện tại không bao gồm quyền đặt lớp.', 1;
        IF @HasOverlap = 1
            THROW 52147, N'Hội viên đã có buổi lớp khác trùng giờ.', 1;

        DECLARE @ConfirmedCount int;
        SELECT @ConfirmedCount = COUNT(*)
        FROM dbo.DatLop
        WHERE SessionId = @SessionId AND Status IN ('CONFIRMED', 'ATTENDED', 'NO_SHOW');

        SET @ResultStatus = CASE WHEN @ConfirmedCount < @Capacity THEN 'CONFIRMED' ELSE 'WAITLISTED' END;

        -- UQ_DatLop_Member_Session giữ một dòng cho mỗi cặp hội viên/buổi.
        -- Đặt lại sau khi hủy phải mở lại dòng cũ, không INSERT dòng thứ hai.
        SELECT @NewBookingId = BookingId
        FROM dbo.DatLop WITH (UPDLOCK, HOLDLOCK)
        WHERE MemberId = @MemberId AND SessionId = @SessionId AND Status = 'CANCELLED';

        IF @NewBookingId IS NULL
        BEGIN
            INSERT dbo.DatLop(MemberId, SessionId, Status)
            VALUES (@MemberId, @SessionId, @ResultStatus);
            SET @NewBookingId = SCOPE_IDENTITY();
        END
        ELSE
            UPDATE dbo.DatLop
            SET Status = @ResultStatus, BookedAt = SYSUTCDATETIME(),
                CancelledAt = NULL, CancellationReason = NULL,
                UpdatedAt = SYSUTCDATETIME()
            WHERE BookingId = @NewBookingId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- TRANSACTION TV3 — hủy chỗ đúng hạn; nếu hủy CONFIRMED thì xét đôn người chờ đầu tiên.
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

        IF dbo.fn_CoTheHuyDatLop(@BookingId, SYSUTCDATETIME()) = 0
            THROW 52153, N'Đã quá thời hạn hủy chỗ hoặc buổi lớp không còn ở trạng thái phù hợp.', 1;

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
            FROM dbo.DatLop AS d WITH (UPDLOCK, ROWLOCK)
            CROSS APPLY dbo.fn_DieuKienDatLop(d.MemberId, d.SessionId) AS eligibility
            WHERE d.SessionId = @SessionId AND d.Status = 'WAITLISTED'
              AND eligibility.MemberActive = 1
              AND eligibility.HasActivePlan = 1
              AND eligibility.PlanAllowsClasses = 1
              AND eligibility.HasOverlap = 0
            ORDER BY d.BookedAt ASC, d.BookingId ASC;

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
           CONVERT(bit, CASE WHEN EXISTS
           (SELECT 1 FROM dbo.fn_GoiHieuLuc(MemberId, CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()))) WHERE ActiveCount > 0)
           THEN 1 ELSE 0 END) AS HasActivePlan
    FROM dbo.HoiVien
    WHERE IsActive = 1
      AND (MemberCode LIKE @Keyword + N'%' OR FullName LIKE N'%' + @Keyword + N'%' OR Phone LIKE @Keyword + N'%')
    ORDER BY FullName;
END;
GO

/* ============================================================
   CheckIn
   ============================================================ */
-- TRANSACTION TV3 — ghi check-in và đổi booking sang ATTENDED cùng một lần xử lý.
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

        DECLARE @EmployeeType varchar(20);
        SELECT @EmployeeType = EmployeeType
        FROM dbo.NhanVien
        WHERE EmployeeId = @EmployeeId AND IsActive = 1;
        IF @EmployeeType NOT IN ('MANAGER', 'RECEPTIONIST', 'TRAINER') OR @EmployeeType IS NULL
            THROW 52164, N'Nhân viên không được phép ghi nhận check-in.', 1;
        IF @CheckInMethod <> 'FRONT_DESK'
            THROW 52165, N'Hiện tại chỉ hỗ trợ check-in trực tiếp tại quầy.', 1;

        -- Khóa một hội viên trước khi đếm lượt, để các lượt check-in đồng thời
        -- của cùng người phải kiểm tra hạn mức lần lượt.
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.HoiVien WITH (UPDLOCK, HOLDLOCK)
            WHERE MemberId = @MemberId AND IsActive = 1
        )
            THROW 52166, N'Hội viên không tồn tại hoặc đã ngừng hoạt động.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.fn_GoiHieuLuc(@MemberId, CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()))) WHERE ActiveCount > 0)
            THROW 52161, N'Hội viên không có gói tập còn hiệu lực để check-in.', 1;

        DECLARE @MaxPerDay tinyint;
        SELECT @MaxPerDay = MAX(g.MaxCheckInsPerDay)
        FROM dbo.DangKyGoi AS dk
        INNER JOIN dbo.GoiTap AS g ON g.PlanId = dk.PlanId
        WHERE dk.MemberId = @MemberId
          AND dk.Status = 'ACTIVE'
          AND CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME())) BETWEEN dk.StartDate AND dk.EndDate;

        -- CheckedAt lưu UTC, nên đổi nửa đêm giờ máy chủ sang UTC để đếm đúng "hôm nay".
        DECLARE @TodayVn date = CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()));
        DECLARE @TodayCount int = dbo.fn_SoLuotCheckInTrongNgay(@MemberId, @TodayVn);

        IF @MaxPerDay IS NOT NULL AND @TodayCount >= @MaxPerDay
            THROW 52162, N'Hội viên đã đạt số lượt check-in tối đa hôm nay theo gói tập.', 1;

        IF @SessionId IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1 FROM dbo.LichLop
                WHERE SessionId = @SessionId AND Status IN ('SCHEDULED', 'IN_PROGRESS')
                  AND dbo.fn_GioVN(SYSUTCDATETIME()) >= DATEADD(MINUTE, -30, StartAt)
                  AND dbo.fn_GioVN(SYSUTCDATETIME()) <= EndAt
                  AND (@EmployeeType <> 'TRAINER' OR TrainerId = @EmployeeId)
            )
                THROW 52167, N'Buổi lớp chưa đến giờ check-in, đã kết thúc hoặc không thuộc huấn luyện viên này.', 1;

            UPDATE dbo.DatLop
            SET Status = 'ATTENDED', UpdatedAt = SYSUTCDATETIME()
            WHERE MemberId = @MemberId AND SessionId = @SessionId AND Status = 'CONFIRMED';

            IF @@ROWCOUNT = 0
                THROW 52163, N'Hội viên chưa có lượt đặt chỗ CONFIRMED cho buổi lớp này.', 1;
        END;

        IF @SessionId IS NULL AND @EmployeeType = 'TRAINER'
            THROW 52168, N'Huấn luyện viên chỉ được check-in cho lớp mình phụ trách.', 1;

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
