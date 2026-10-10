/*
    SESSION A - cửa sổ SSMS thứ nhất. Chạy từng khối (bôi đen + Ctrl+E), không chạy cả file.
*/

USE [GymManagementDB]; -- đổi tên database cho đúng máy demo
GO

-- Khối 1: dựng buổi lớp demo chỉ có 1 chỗ
DECLARE @RoomId int, @ClassId int, @TrainerId int, @SessionId bigint;

SELECT TOP (1) @TrainerId = EmployeeId FROM dbo.NhanVien WHERE EmployeeType = 'TRAINER' AND IsActive = 1;

EXEC dbo.sp_PhongTap_Upsert
    @RoomCode = 'DEMO-CONC-ROOM', @RoomName = N'Phòng demo concurrency', @Capacity = 5,
    @NewRoomId = @RoomId OUTPUT;

EXEC dbo.sp_LopTap_Upsert
    @ClassCode = 'DEMO-CONC-CLASS', @ClassName = N'Lớp demo concurrency', @DefaultDurationMinutes = 60,
    @NewClassId = @ClassId OUTPUT;

EXEC dbo.sp_LichLop_TaoLich
    @ClassId = @ClassId, @RoomId = @RoomId, @TrainerId = @TrainerId,
    @StartAt = '2027-02-01T18:00:00', @EndAt = '2027-02-01T19:00:00', @Capacity = 1,
    @NewSessionId = @SessionId OUTPUT;

PRINT CONCAT(N'SessionId để demo = ', @SessionId);
GO

-- Khối 2 (chạy liền với khối 3): điền SessionId vừa in ra
DECLARE @DemoSessionId bigint = 0; -- <-- sửa số 0

BEGIN TRANSACTION;

DECLARE @Member1 int, @Booking1 bigint, @Status1 varchar(20);
SELECT @Member1 = MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0001';

EXEC dbo.sp_DatLop_DatCho
    @MemberId = @Member1, @SessionId = @DemoSessionId,
    @NewBookingId = @Booking1 OUTPUT, @ResultStatus = @Status1 OUTPUT;

PRINT CONCAT(N'Session A đặt chỗ lúc ', CONVERT(varchar(30), SYSUTCDATETIME(), 121),
             N' - BookingId=', @Booking1, N', Status=', @Status1);

-- Giữ transaction/lock 20 giây: mở Session B và chạy ngay trong lúc này.
WAITFOR DELAY '00:00:20';

COMMIT TRANSACTION;
PRINT CONCAT(N'Session A COMMIT lúc ', CONVERT(varchar(30), SYSUTCDATETIME(), 121));
GO
