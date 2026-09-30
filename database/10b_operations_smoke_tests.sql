USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
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
    ('fn_SoChoConLai', 'fn_HoiVien_CoGoiHieuLuc', 'fn_LichLop_TheoTuan')) <> 3
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
        @StartAt = '2027-01-01T18:00:00', @EndAt = '2027-01-01T19:00:00', @Capacity = 1,
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

    IF dbo.fn_SoChoConLai(@SessionId) <> 0
        THROW 52210, N'Smoke test thất bại: fn_SoChoConLai tính sai số chỗ còn lại.', 1;

    EXEC dbo.sp_DatLop_HuyCho @BookingId = @Booking1, @Reason = N'Test hủy để kiểm tra đôn waitlist';
    IF (SELECT Status FROM dbo.DatLop WHERE BookingId = @Booking2) <> 'CONFIRMED'
        THROW 52211, N'Smoke test thất bại: chưa đôn người chờ lên CONFIRMED sau khi có người hủy.', 1;

    BEGIN TRY
        DECLARE @DummySession bigint;

        EXEC dbo.sp_LichLop_TaoLich
            @ClassId = @ClassId, @RoomId = @RoomId, @TrainerId = @TrainerId,
            @StartAt = '2027-01-01T18:30:00', @EndAt = '2027-01-01T19:30:00', @Capacity = 1,
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
