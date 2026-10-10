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

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.VaiTro WHERE RoleCode = 'ADMIN')
        INSERT dbo.VaiTro(RoleCode, RoleName, Description) VALUES ('ADMIN', N'Quản trị viên', N'Quản trị toàn hệ thống');
    IF NOT EXISTS (SELECT 1 FROM dbo.VaiTro WHERE RoleCode = 'RECEPTIONIST')
        INSERT dbo.VaiTro(RoleCode, RoleName, Description) VALUES ('RECEPTIONIST', N'Lễ tân', N'Quản lý hội viên, đăng ký, check-in');
    IF NOT EXISTS (SELECT 1 FROM dbo.VaiTro WHERE RoleCode = 'TRAINER')
        INSERT dbo.VaiTro(RoleCode, RoleName, Description) VALUES ('TRAINER', N'Huấn luyện viên', N'Quản lý lịch và điểm danh lớp phụ trách');
    IF NOT EXISTS (SELECT 1 FROM dbo.VaiTro WHERE RoleCode = 'ACCOUNTANT')
        INSERT dbo.VaiTro(RoleCode, RoleName, Description) VALUES ('ACCOUNTANT', N'Kế toán', N'Quản lý thanh toán và báo cáo doanh thu');

    DECLARE @AdminRoleId smallint = (SELECT RoleId FROM dbo.VaiTro WHERE RoleCode = 'ADMIN');
    DECLARE @ReceptionRoleId smallint = (SELECT RoleId FROM dbo.VaiTro WHERE RoleCode = 'RECEPTIONIST');
    DECLARE @TrainerRoleId smallint = (SELECT RoleId FROM dbo.VaiTro WHERE RoleCode = 'TRAINER');
    DECLARE @AccountantRoleId smallint = (SELECT RoleId FROM dbo.VaiTro WHERE RoleCode = 'ACCOUNTANT');

    /* Demo passwords được ghi trong README; bắt buộc đổi trước khi dùng ngoài môi trường học tập. */
    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = 'admin')
        INSERT dbo.NguoiDung(RoleId, Username, PasswordHash, PasswordSalt, PasswordIterations, MustChangePassword)
        VALUES (@AdminRoleId, 'admin', 0xE0FC83C65A2988A6F52D0D1BAD26DFCBB24A5CA4C1DE0B197A893DC1C38615B4, 0xD8B3991DFEE1B083627855E67FB83D0E, 100000, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = 'letan')
        INSERT dbo.NguoiDung(RoleId, Username, PasswordHash, PasswordSalt, PasswordIterations, MustChangePassword)
        VALUES (@ReceptionRoleId, 'letan', 0x2B48684BD5D189124B845CB1CF0AE73FC2064969CFB628CB462FA266C80A30A6, 0x4A21BC0858BF34872C000A4C48FE064B, 100000, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = 'trainer')
        INSERT dbo.NguoiDung(RoleId, Username, PasswordHash, PasswordSalt, PasswordIterations, MustChangePassword)
        VALUES (@TrainerRoleId, 'trainer', 0x9EFB2E806C46DCE2CA7329CFCC6CEC7957E3DDEF18BFA117E3F5A3FBA7FCBA88, 0x3DACE0CDA0998B0F6269B02FBAA342D6, 100000, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.NguoiDung WHERE Username = 'ketoan')
        INSERT dbo.NguoiDung(RoleId, Username, PasswordHash, PasswordSalt, PasswordIterations, MustChangePassword)
        VALUES (@AccountantRoleId, 'ketoan', 0x57E5BF222335A8BAF38688E6FE36493B60DB1E9048658643F77199D77A25E1D1, 0xF0A4CDADC9E25573AF0BF514A1A1543F, 100000, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.NhanVien WHERE EmployeeCode = 'NV-ADMIN')
        INSERT dbo.NhanVien(UserId, EmployeeCode, FullName, DateOfBirth, Gender, Phone, Email, HireDate, EmployeeType)
        SELECT UserId, 'NV-ADMIN', N'Nguyễn Quản Trị', '19900115', 'MALE', '0900000001', 'admin@gym.local', '20240101', 'MANAGER'
        FROM dbo.NguoiDung WHERE Username = 'admin';

    IF NOT EXISTS (SELECT 1 FROM dbo.NhanVien WHERE EmployeeCode = 'NV-LETAN')
        INSERT dbo.NhanVien(UserId, EmployeeCode, FullName, DateOfBirth, Gender, Phone, Email, HireDate, EmployeeType)
        SELECT UserId, 'NV-LETAN', N'Trần Lễ Tân', '19980620', 'FEMALE', '0900000002', 'letan@gym.local', '20240201', 'RECEPTIONIST'
        FROM dbo.NguoiDung WHERE Username = 'letan';

    IF NOT EXISTS (SELECT 1 FROM dbo.NhanVien WHERE EmployeeCode = 'NV-TRAINER')
        INSERT dbo.NhanVien(UserId, EmployeeCode, FullName, DateOfBirth, Gender, Phone, Email, HireDate, EmployeeType)
        SELECT UserId, 'NV-TRAINER', N'Lê Huấn Luyện', '19950710', 'MALE', '0900000003', 'trainer@gym.local', '20240301', 'TRAINER'
        FROM dbo.NguoiDung WHERE Username = 'trainer';

    IF NOT EXISTS (SELECT 1 FROM dbo.NhanVien WHERE EmployeeCode = 'NV-KETOAN')
        INSERT dbo.NhanVien(UserId, EmployeeCode, FullName, DateOfBirth, Gender, Phone, Email, HireDate, EmployeeType)
        SELECT UserId, 'NV-KETOAN', N'Phạm Kế Toán', '19940214', 'FEMALE', '0900000004', 'ketoan@gym.local', '20240401', 'ACCOUNTANT'
        FROM dbo.NguoiDung WHERE Username = 'ketoan';

    IF NOT EXISTS (SELECT 1 FROM dbo.HoiVien WHERE MemberCode = 'HV0001')
        INSERT dbo.HoiVien(MemberCode, FullName, DateOfBirth, Gender, Phone, Email, Address, EmergencyContact)
        VALUES ('HV0001', N'Võ Minh Anh', '20010520', 'FEMALE', '0911000001', 'minhanh@example.test', N'Thành phố Hồ Chí Minh', N'Mẹ - 0911999001');

    IF NOT EXISTS (SELECT 1 FROM dbo.HoiVien WHERE MemberCode = 'HV0002')
        INSERT dbo.HoiVien(MemberCode, FullName, DateOfBirth, Gender, Phone, Email, Address, EmergencyContact)
        VALUES ('HV0002', N'Đỗ Quốc Bảo', '19991111', 'MALE', '0911000002', 'quocbao@example.test', N'Thành phố Thủ Đức', N'Anh - 0911999002');

    IF NOT EXISTS (SELECT 1 FROM dbo.GoiTap WHERE PlanCode = 'BASIC-30')
        INSERT dbo.GoiTap(PlanCode, PlanName, Description, DurationDays, Price, MaxCheckInsPerDay, AllowsClasses)
        VALUES ('BASIC-30', N'Gói cơ bản 30 ngày', N'Tập tự do, không bao gồm lớp nhóm', 30, 500000, 1, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.GoiTap WHERE PlanCode = 'PREMIUM-90')
        INSERT dbo.GoiTap(PlanCode, PlanName, Description, DurationDays, Price, MaxCheckInsPerDay, AllowsClasses)
        VALUES ('PREMIUM-90', N'Gói Premium 90 ngày', N'Tập tự do và tham gia lớp nhóm', 90, 1200000, 2, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.PhongTap WHERE RoomCode = 'GYM-FLOOR')
        INSERT dbo.PhongTap(RoomCode, RoomName, Capacity, Location)
        VALUES ('GYM-FLOOR', N'Khu tập tự do', 100, N'Tầng 1');

    IF NOT EXISTS (SELECT 1 FROM dbo.PhongTap WHERE RoomCode = 'STUDIO-A')
        INSERT dbo.PhongTap(RoomCode, RoomName, Capacity, Location)
        VALUES ('STUDIO-A', N'Phòng Studio A', 25, N'Tầng 2');

    IF NOT EXISTS (SELECT 1 FROM dbo.LopTap WHERE ClassCode = 'YOGA-BASIC')
        INSERT dbo.LopTap(ClassCode, ClassName, Description, DefaultDurationMinutes, DifficultyLevel)
        VALUES ('YOGA-BASIC', N'Yoga cơ bản', N'Lớp yoga dành cho người mới', 60, 'BEGINNER');

    IF NOT EXISTS (SELECT 1 FROM dbo.LopTap WHERE ClassCode = 'HIIT-45')
        INSERT dbo.LopTap(ClassCode, ClassName, Description, DefaultDurationMinutes, DifficultyLevel)
        VALUES ('HIIT-45', N'HIIT 45 phút', N'Lớp cường độ cao', 45, 'ADVANCED');

    DECLARE @MemberId int = (SELECT MemberId FROM dbo.HoiVien WHERE MemberCode = 'HV0001');
    DECLARE @PlanId int = (SELECT PlanId FROM dbo.GoiTap WHERE PlanCode = 'PREMIUM-90');
    DECLARE @ReceptionId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-LETAN');
    DECLARE @TrainerId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-TRAINER');
    DECLARE @AccountantId int = (SELECT EmployeeId FROM dbo.NhanVien WHERE EmployeeCode = 'NV-KETOAN');
    DECLARE @RoomId int = (SELECT RoomId FROM dbo.PhongTap WHERE RoomCode = 'STUDIO-A');
    DECLARE @ClassId int = (SELECT ClassId FROM dbo.LopTap WHERE ClassCode = 'YOGA-BASIC');

    IF NOT EXISTS (SELECT 1 FROM dbo.DangKyGoi WHERE MemberId = @MemberId AND PlanId = @PlanId)
        INSERT dbo.DangKyGoi(MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
        VALUES (@MemberId, @PlanId, @ReceptionId, CONVERT(date, GETDATE()), DATEADD(DAY, 89, CONVERT(date, GETDATE())), 1200000, 'ACTIVE');

    DECLARE @MembershipId bigint =
    (
        SELECT TOP (1) MembershipId
        FROM dbo.DangKyGoi
        WHERE MemberId = @MemberId AND PlanId = @PlanId
        ORDER BY MembershipId
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.HoaDon WHERE InvoiceCode = 'HD-DEMO-0001')
        INSERT dbo.HoaDon(InvoiceCode, MembershipId, CreatedByEmployeeId, TotalAmount, PaidAmount, Status, Note)
        VALUES ('HD-DEMO-0001', @MembershipId, @ReceptionId, 1200000, 1200000, 'PAID', N'Hóa đơn seed demo');

    DECLARE @InvoiceId bigint = (SELECT InvoiceId FROM dbo.HoaDon WHERE InvoiceCode = 'HD-DEMO-0001');

    IF NOT EXISTS (SELECT 1 FROM dbo.CTHoaDon WHERE InvoiceId = @InvoiceId)
        INSERT dbo.CTHoaDon(InvoiceId, ItemType, Description, Quantity, UnitPrice, DiscountAmount)
        VALUES (@InvoiceId, 'MEMBERSHIP', N'Gói Premium 90 ngày', 1, 1200000, 0);

    IF NOT EXISTS (SELECT 1 FROM dbo.ThanhToan WHERE PaymentCode = 'TT-DEMO-0001')
        INSERT dbo.ThanhToan(PaymentCode, InvoiceId, ReceivedByEmployeeId, Amount, PaymentMethod, Status, TransactionReference)
        VALUES ('TT-DEMO-0001', @InvoiceId, @AccountantId, 1200000, 'BANK_TRANSFER', 'COMPLETED', 'DEMO-TRANSFER');

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.LichLop
        WHERE ClassId = @ClassId AND TrainerId = @TrainerId AND Status = 'SCHEDULED'
    )
        INSERT dbo.LichLop(ClassId, RoomId, TrainerId, StartAt, EndAt, Capacity, Status)
        VALUES
        (
            @ClassId,
            @RoomId,
            @TrainerId,
            DATEADD(HOUR, 18, CONVERT(datetime2(0), DATEADD(DAY, 1, CONVERT(date, GETDATE())))),
            DATEADD(HOUR, 19, CONVERT(datetime2(0), DATEADD(DAY, 1, CONVERT(date, GETDATE())))),
            20,
            'SCHEDULED'
        );

    DECLARE @SessionId bigint =
    (
        SELECT TOP (1) SessionId
        FROM dbo.LichLop
        WHERE ClassId = @ClassId AND TrainerId = @TrainerId AND Status = 'SCHEDULED'
        ORDER BY StartAt
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.DatLop WHERE MemberId = @MemberId AND SessionId = @SessionId)
        INSERT dbo.DatLop(MemberId, SessionId, Status) VALUES (@MemberId, @SessionId, 'CONFIRMED');

    COMMIT TRANSACTION;
    PRINT N'Đã seed dữ liệu demo idempotent.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
