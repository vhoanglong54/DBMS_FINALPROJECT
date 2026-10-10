USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
    Seed bổ sung cho demo module Class Operations (chạy sau 09_seed_demo.sql).
    Idempotent: chạy lại không tạo trùng.
*/
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PlanId int = (SELECT PlanId FROM dbo.GoiTap WHERE PlanCode = 'PREMIUM-90');
    DECLARE @ReceptionId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-LETAN');
    DECLARE @TrainerId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-TRAINER');
    DECLARE @Member2 int = (SELECT MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0002');
    DECLARE @StudioId int = (SELECT RoomId FROM dbo.PhongTap WHERE RoomCode = 'STUDIO-A');
    DECLARE @HiitId int = (SELECT ClassId FROM dbo.LopTap WHERE ClassCode = 'HIIT-45');
    DECLARE @Today date = CONVERT(date, GETDATE());

    IF @Member2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.DangKyGoi WHERE MemberId = @Member2 AND PlanId = @PlanId)
        INSERT dbo.DangKyGoi(MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
        VALUES (@Member2, @PlanId, @ReceptionId, @Today, DATEADD(DAY, 89, @Today), 1200000, 'ACTIVE');

    IF NOT EXISTS (SELECT 1 FROM dbo.LichLop WHERE ClassId = @HiitId AND RoomId = @StudioId AND Status = 'SCHEDULED')
        INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
        VALUES
        (
            @HiitId, @StudioId, @TrainerId,
            DATEADD(HOUR, 7, CONVERT(datetime2(0), DATEADD(DAY, 2, @Today))),
            DATEADD(MINUTE, 7 * 60 + 45, CONVERT(datetime2(0), DATEADD(DAY, 2, @Today))),
            2, 'SCHEDULED'
        );

    COMMIT TRANSACTION;
    PRINT N'Đã seed dữ liệu demo cho module Class Operations.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
