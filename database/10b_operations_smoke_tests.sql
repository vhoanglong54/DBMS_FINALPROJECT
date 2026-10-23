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

IF (SELECT COUNT(*) FROM sys.triggers WHERE name IN
    ('trg_LichLop_ValidateTrainerRole', 'trg_LichLop_NoOverlap', 'trg_LichLop_CapacityWithinRoom',
     'trg_DatLop_EnforceSessionCapacity', 'trg_DatLop_PreventInvalidSessionBooking')) <> 5
    THROW 52201, N'Smoke test thất bại: thiếu trigger module Class Operations.', 1;

IF (SELECT COUNT(*) FROM sys.views WHERE name IN
    ('vw_LichLop_ConCho', 'vw_LichLop_HomNay', 'vw_CongSuatLop', 'vw_LichSuCheckIn')) <> 4
    THROW 52202, N'Smoke test thất bại: thiếu view module Class Operations.', 1;

IF (SELECT COUNT(*) FROM sys.indexes WHERE name IN
    ('IX_DatLop_SessionId_Status', 'IX_LichLop_RoomId_StartAt_EndAt', 'IX_LichLop_TrainerId_StartAt_EndAt',
     'IX_LichLop_StartAt_Status', 'IX_CheckIn_MemberId_CheckedAt')) <> 5
    THROW 52203, N'Smoke test thất bại: thiếu index module Class Operations.', 1;

IF (SELECT COUNT(*) FROM sys.objects WHERE type = 'P' AND name IN
    ('sp_PhongTap_Upsert', 'sp_PhongTap_SetActive', 'sp_PhongTap_DanhSach', 'sp_PhongTap_ChiTiet',
     'sp_LopTap_Upsert', 'sp_LopTap_SetActive', 'sp_LopTap_DanhSach', 'sp_LopTap_ChiTiet',
     'sp_LichLop_TaoLich', 'sp_LichLop_HuyLich', 'sp_LichLop_DanhSach', 'sp_LichLop_ChiTiet', 'sp_NhanVien_DanhSachHLV',
     'sp_DatLop_DatCho', 'sp_DatLop_HuyCho', 'sp_DatLop_DanhSachTheoBuoi', 'sp_HoiVien_TimKiemNhanh',
     'sp_CheckIn_GhiNhan', 'sp_CheckIn_LichSu')) <> 19
    THROW 52204, N'Smoke test thất bại: thiếu stored procedure module Class Operations.', 1;

IF (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND name IN
    ('fn_ChoTrongLop', 'fn_GoiHieuLuc', 'fn_LichLopTheoKhoang')) <> 3
    THROW 52205, N'Smoke test thất bại: thiếu function module Class Operations.', 1;

/*
    Phần test chức năng chạy trong một transaction và luôn kết thúc bằng rollback
    (do trigger chống trùng lịch ở cuối, hoặc do CATCH nếu có lỗi) nên không để lại
    dữ liệu ZZ-TEST-*.
*/
BEGIN TRANSACTION SmokeTv3;
BEGIN TRY

    DECLARE @RoomId int, @ClassId int, @TrainerId int, @SessionId bigint;
    DECLARE @Member1 int, @Member2 int, @Plan int, @SellerId int;
    DECLARE @Booking1 bigint, @Booking2 bigint, @Status1 varchar(20), @Status2 varchar(20);
    DECLARE @TestStart datetime2(0) = DATEADD(HOUR, 18, CONVERT(datetime2(0), DATEADD(DAY, 7, CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME())))));
    DECLARE @TestEnd datetime2(0) = DATEADD(HOUR, 1, @TestStart);

    EXEC dbo.sp_PhongTap_Upsert
        @RoomCode = 'ZZ-TEST-ROOM', @RoomName = N'Phòng test smoke', @Capacity = 10,
        @NewRoomId = @RoomId OUTPUT;

    EXEC dbo.sp_LopTap_Upsert
        @ClassCode = 'ZZ-TEST-CLASS', @ClassName = N'Lớp test smoke', @DefaultDurationMinutes = 60,
        @NewClassId = @ClassId OUTPUT;

    SELECT TOP (1) @TrainerId = EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'TRAINER' AND IsActive = 1;
    IF @TrainerId IS NULL
        THROW 52206, N'Smoke test thất bại: không có huấn luyện viên demo để test.', 1;

    EXEC dbo.sp_LichLop_TaoLich
        @ClassId = @ClassId, @RoomId = @RoomId, @TrainerId = @TrainerId,
        @StartAt = @TestStart, @EndAt = @TestEnd, @Capacity = 1,
        @NewSessionId = @SessionId OUTPUT;

    SELECT TOP (1) @Plan = PlanId FROM dbo.GoiTap WHERE AllowsClasses = 1 AND IsActive = 1;
    IF @Plan IS NULL
        THROW 52207, N'Smoke test thất bại: không có gói tập AllowsClasses = 1 để test.', 1;

    SET @SellerId = (SELECT TOP (1) EmployeeId FROM dbo.NhanVien WHERE IsActive = 1);

    INSERT dbo.HoiVien(MemberCode, FullName, DateOfBirth, Phone)
    VALUES ('ZZ-TEST-M1', N'Hội viên Test Một', '19990101', '0900000901');
    SET @Member1 = SCOPE_IDENTITY();

    INSERT dbo.HoiVien(MemberCode, FullName, DateOfBirth, Phone)
    VALUES ('ZZ-TEST-M2', N'Hội viên Test Hai', '19990101', '0900000902');
    SET @Member2 = SCOPE_IDENTITY();

    INSERT dbo.DangKyGoi(MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
    VALUES (@Member1, @Plan, @SellerId, DATEADD(DAY, -1, CAST(GETDATE() AS date)), DATEADD(DAY, 30, CAST(GETDATE() AS date)), 0, 'ACTIVE'),
           (@Member2, @Plan, @SellerId, DATEADD(DAY, -1, CAST(GETDATE() AS date)), DATEADD(DAY, 30, CAST(GETDATE() AS date)), 0, 'ACTIVE');

    EXEC dbo.sp_DatLop_DatCho @MemberId = @Member1, @SessionId = @SessionId,
        @NewBookingId = @Booking1 OUTPUT, @ResultStatus = @Status1 OUTPUT;
    IF @Status1 <> 'CONFIRMED'
        THROW 52208, N'Smoke test thất bại: hội viên đầu tiên phải được CONFIRMED.', 1;

    EXEC dbo.sp_DatLop_DatCho @MemberId = @Member2, @SessionId = @SessionId,
        @NewBookingId = @Booking2 OUTPUT, @ResultStatus = @Status2 OUTPUT;
    IF @Status2 <> 'WAITLISTED'
        THROW 52209, N'Smoke test thất bại: hội viên thứ hai phải vào WAITLISTED khi capacity = 1.', 1;

    IF dbo.fn_ChoTrongLop(@SessionId) <> 0
        THROW 52210, N'Smoke test thất bại: fn_ChoTrongLop tính sai số chỗ còn lại.', 1;

    EXEC dbo.sp_DatLop_HuyCho @BookingId = @Booking1, @Reason = N'Test hủy để kiểm tra đôn waitlist';
    IF (SELECT Status FROM dbo.DatLop WHERE BookingId = @Booking2) <> 'CONFIRMED'
        THROW 52211, N'Smoke test thất bại: chưa đôn người chờ lên CONFIRMED sau khi có người hủy.', 1;

    DECLARE @RebookId bigint, @RebookStatus varchar(20);
    EXEC dbo.sp_DatLop_DatCho @MemberId = @Member1, @SessionId = @SessionId,
        @NewBookingId = @RebookId OUTPUT, @ResultStatus = @RebookStatus OUTPUT;
    IF @RebookId <> @Booking1 OR @RebookStatus <> 'WAITLISTED'
        THROW 52213, N'Smoke test thất bại: đặt lại sau khi hủy phải dùng dòng cũ và vào hàng chờ.', 1;

    BEGIN TRY
        DECLARE @DummySession bigint;
        DECLARE @OverlapStart datetime2(0) = DATEADD(MINUTE, 30, @TestStart);
        DECLARE @OverlapEnd datetime2(0) = DATEADD(MINUTE, 30, @TestEnd);

        EXEC dbo.sp_LichLop_TaoLich
            @ClassId = @ClassId, @RoomId = @RoomId, @TrainerId = @TrainerId,
            @StartAt = @OverlapStart, @EndAt = @OverlapEnd, @Capacity = 1,
            @NewSessionId = @DummySession OUTPUT;

        THROW 52212, N'Smoke test thất bại: trigger chống trùng lịch không hoạt động.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 52002
            THROW;
    END CATCH;

    PRINT N'ALL TV3 CLASS OPERATIONS SMOKE TESTS PASSED.';

    -- Trigger ở trên đã ROLLBACK toàn bộ transaction; dọn nốt nếu vì lý do nào đó còn mở.
    IF XACT_STATE() = 1
        ROLLBACK TRANSACTION SmokeTv3;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Các lỗi này không được để lại thay đổi dữ liệu: chỉ kiểm tra kết quả trả về.
DECLARE @SeedSessionId bigint =
(
    SELECT TOP (1) d.SessionId
    FROM dbo.DatLop AS d
    INNER JOIN dbo.HoiVien AS m ON m.MemberId = d.MemberId
    INNER JOIN dbo.LichLop AS l ON l.SessionId = d.SessionId
    WHERE m.MemberCode = 'HV0001'
      AND l.StartAt > DATEADD(MINUTE, 30, dbo.fn_GioVN(SYSUTCDATETIME()))
    ORDER BY l.StartAt
);
IF @SeedSessionId IS NULL THROW 52214, N'Smoke test: thiếu buổi tương lai có hội viên đã đặt.', 1;

BEGIN TRY
    EXEC dbo.sp_DatLop_DatCho @MemberId = -1, @SessionId = @SeedSessionId;
    THROW 52215, N'Smoke test: phải chặn hội viên không tồn tại.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 52146 THROW;
END CATCH;

BEGIN TRY
    DECLARE @SeedMemberId int = (SELECT MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0001');
    DECLARE @SeedTrainerId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-TRAINER');
    EXEC dbo.sp_CheckIn_GhiNhan
        @MemberId = @SeedMemberId, @EmployeeId = @SeedTrainerId, @SessionId = @SeedSessionId;
    THROW 52216, N'Smoke test: không được check-in lớp quá sớm.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 52167 THROW;
END CATCH;

BEGIN TRY
    DECLARE @SeedMembershipId bigint =
        (SELECT TOP (1) MembershipId FROM dbo.DangKyGoi WHERE MemberId = @SeedMemberId AND Status = 'ACTIVE');
    EXEC dbo.sp_HuyGoiTap @MembershipId = @SeedMembershipId, @Reason = N'Test còn đặt chỗ';
    THROW 52217, N'Smoke test: không được hủy gói khi còn đặt chỗ sắp tới.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 53023 THROW;
END CATCH;

PRINT N'ALL TV3 BUSINESS GUARDS PASSED.';
GO

-- Hai buổi khác phòng/HLV nhưng cùng giờ: một hội viên không được giữ cả hai.
-- Lỗi 52147 làm rollback toàn bộ nhân viên/phòng/buổi ZZ-TEST của phép thử.
BEGIN TRY
    BEGIN TRANSACTION SmokeMemberOverlap;
    DECLARE @ExistingSessionId bigint =
    (
        SELECT TOP (1) d.SessionId
        FROM dbo.DatLop AS d
        INNER JOIN dbo.HoiVien AS m ON m.MemberId = d.MemberId
        INNER JOIN dbo.LichLop AS l ON l.SessionId = d.SessionId
        WHERE m.MemberCode = 'HV0001' AND l.StartAt > dbo.fn_GioVN(SYSUTCDATETIME())
        ORDER BY l.StartAt
    );
    DECLARE @OverlapMemberId int = (SELECT MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0001');
    DECLARE @OverlapRoomId int, @OverlapTrainerId int, @OverlapSessionId bigint;
    DECLARE @OverlapClassId int, @OverlapStart datetime2(0), @OverlapEnd datetime2(0);
    SELECT @OverlapClassId = ClassId, @OverlapStart = StartAt, @OverlapEnd = EndAt
    FROM dbo.LichLop WHERE SessionId = @ExistingSessionId;

    INSERT dbo.NhanVien(EmployeeCode, FullName, Phone, HireDate, EmployeeType)
    VALUES ('ZZ-TEST-TRAINER', N'HLV kiểm tra trùng lịch hội viên', '0900000988',
            CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME())), 'TRAINER');
    SET @OverlapTrainerId = SCOPE_IDENTITY();
    EXEC dbo.sp_PhongTap_Upsert
        @RoomCode = 'ZZ-TEST-ROOM-2', @RoomName = N'Phòng kiểm tra trùng lịch',
        @Capacity = 10, @NewRoomId = @OverlapRoomId OUTPUT;
    EXEC dbo.sp_LichLop_TaoLich
        @ClassId = @OverlapClassId,
        @RoomId = @OverlapRoomId, @TrainerId = @OverlapTrainerId,
        @StartAt = @OverlapStart, @EndAt = @OverlapEnd,
        @Capacity = 10, @NewSessionId = @OverlapSessionId OUTPUT;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.fn_DieuKienDatLop(@OverlapMemberId, @OverlapSessionId)
        WHERE HasOverlap = 1
    ) THROW 52219, N'Smoke test: function chưa nhận ra hội viên bị trùng giờ.', 1;

    EXEC dbo.sp_DatLop_DatCho @MemberId = @OverlapMemberId, @SessionId = @OverlapSessionId;
    THROW 52218, N'Smoke test: procedure phải chặn hội viên đặt trùng giờ.', 1;
END TRY
BEGIN CATCH
    DECLARE @OverlapError int = ERROR_NUMBER();
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF @OverlapError <> 52147 THROW;
END CATCH;

PRINT N'ALL TV3 MEMBER OVERLAP GUARDS PASSED.';
GO

-- Check-in trong giờ hợp lệ phải ghi một dòng và đổi đặt chỗ sang ATTENDED.
BEGIN TRY
    BEGIN TRANSACTION SmokeCheckIn;
    DECLARE @CheckInMemberId int = (SELECT MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0001');
    DECLARE @CheckInTrainerId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-TRAINER');
    DECLARE @CheckInRoomId int = (SELECT RoomId FROM dbo.PhongTap WHERE RoomCode = 'STUDIO-A');
    DECLARE @CheckInClassId int = (SELECT ClassId FROM dbo.LopTap WHERE ClassCode = 'HIIT-45');
    DECLARE @CheckInStart datetime2(0) = DATEADD(MINUTE, 5, dbo.fn_GioVN(SYSUTCDATETIME()));
    DECLARE @CheckInEnd datetime2(0) = DATEADD(HOUR, 1, @CheckInStart);
    DECLARE @CheckInSessionId bigint, @CheckInBookingId bigint, @CheckInId bigint;
    DECLARE @CheckInBookingStatus varchar(20);

    EXEC dbo.sp_LichLop_TaoLich
        @ClassId = @CheckInClassId, @RoomId = @CheckInRoomId,
        @TrainerId = @CheckInTrainerId, @StartAt = @CheckInStart,
        @EndAt = @CheckInEnd, @Capacity = 2,
        @NewSessionId = @CheckInSessionId OUTPUT;
    EXEC dbo.sp_DatLop_DatCho
        @MemberId = @CheckInMemberId, @SessionId = @CheckInSessionId,
        @NewBookingId = @CheckInBookingId OUTPUT,
        @ResultStatus = @CheckInBookingStatus OUTPUT;
    IF @CheckInBookingStatus <> 'CONFIRMED'
        THROW 52221, N'Smoke check-in: phải đặt chỗ thành công trước.', 1;

    EXEC dbo.sp_CheckIn_GhiNhan
        @MemberId = @CheckInMemberId, @EmployeeId = @CheckInTrainerId,
        @SessionId = @CheckInSessionId, @NewCheckInId = @CheckInId OUTPUT;
    IF NOT EXISTS (SELECT 1 FROM dbo.CheckIn WHERE CheckInId = @CheckInId AND SessionId = @CheckInSessionId)
       OR (SELECT Status FROM dbo.DatLop WHERE BookingId = @CheckInBookingId) <> 'ATTENDED'
       OR dbo.fn_SoLuotCheckInTrongNgay(@CheckInMemberId,
            CONVERT(date, dbo.fn_GioVN(SYSUTCDATETIME()))) < 1
        THROW 52222, N'Smoke check-in: thiếu dòng điểm danh hoặc đặt chỗ chưa ATTENDED.', 1;

    ROLLBACK TRANSACTION SmokeCheckIn;
    PRINT N'ALL TV3 CHECK-IN TRANSACTION TESTS PASSED.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
