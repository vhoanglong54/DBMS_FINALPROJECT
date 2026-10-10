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

/* Hội viên: ứng dụng chỉ ghi qua procedure; xóa vật lý bị thay bằng ngừng hoạt động. */
CREATE OR ALTER PROCEDURE dbo.sp_HoiVien_DanhSach
    @Search nvarchar(120) = NULL,
    @IncludeInactive bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');

    SELECT MemberId, MemberCode, FullName, DateOfBirth, Gender, Phone, Email,
           Address, EmergencyContact, MedicalNote, ChieuCao, CanNang, ThoiGianTap,
           JoinedAt, IsActive
    FROM dbo.HoiVien
    WHERE (IsActive = 1 OR @IncludeInactive = 1)
      AND (@Search IS NULL OR MemberCode LIKE @Search + N'%'
           OR FullName LIKE N'%' + @Search + N'%'
           OR Phone LIKE @Search + N'%')
    ORDER BY FullName, MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HoiVien_ChiTiet
    @MemberId int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MemberId, MemberCode, FullName, DateOfBirth, Gender, Phone, Email,
           Address, EmergencyContact, MedicalNote, ChieuCao, CanNang, ThoiGianTap,
           JoinedAt, IsActive
    FROM dbo.HoiVien
    WHERE MemberId = @MemberId;

    SELECT dk.MembershipId, gt.PlanName, dk.StartDate, dk.EndDate,
           dk.PriceAtPurchase, dk.Status, dk.CancellationReason
    FROM dbo.DangKyGoi AS dk
    INNER JOIN dbo.GoiTap AS gt ON gt.PlanId = dk.PlanId
    WHERE dk.MemberId = @MemberId
    ORDER BY dk.StartDate DESC, dk.MembershipId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HoiVien_Luu
    @MemberId int = NULL,
    @FullName nvarchar(120),
    @Phone varchar(15),
    @Email varchar(254) = NULL,
    @DateOfBirth date,
    @Gender varchar(10) = NULL,
    @Address nvarchar(300) = NULL,
    @EmergencyContact nvarchar(150) = NULL,
    @MedicalNote nvarchar(1000) = NULL,
    @ChieuCao int = NULL,
    @CanNang int = NULL,
    @ThoiGianTap nvarchar(50) = NULL,
    @SavedMemberId int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        SET @FullName = NULLIF(LTRIM(RTRIM(@FullName)), N'');
        SET @Email = NULLIF(LOWER(LTRIM(RTRIM(@Email))), '');
        IF @FullName IS NULL THROW 53001, N'Họ tên hội viên không được để trống.', 1;
        IF @DateOfBirth > CONVERT(date, DATEADD(HOUR, 7, SYSUTCDATETIME()))
            THROW 53002, N'Ngày sinh không được nằm trong tương lai.', 1;

        IF @MemberId IS NULL
        BEGIN
            DECLARE @MemberNumber bigint = NEXT VALUE FOR dbo.Seq_MemberCode;
            DECLARE @MemberCode varchar(20) = CONCAT('HV', RIGHT(CONCAT('000000', @MemberNumber), 6));
            INSERT dbo.HoiVien(MemberCode, FullName, Phone, Email, DateOfBirth, Gender,
                               Address, EmergencyContact, MedicalNote, ChieuCao, CanNang, ThoiGianTap)
            VALUES(@MemberCode, @FullName, @Phone, @Email, @DateOfBirth, @Gender,
                   @Address, @EmergencyContact, @MedicalNote, @ChieuCao, @CanNang, @ThoiGianTap);
            SET @SavedMemberId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.HoiVien
            SET FullName = @FullName, Phone = @Phone, Email = @Email,
                DateOfBirth = @DateOfBirth, Gender = @Gender, Address = @Address,
                EmergencyContact = @EmergencyContact, MedicalNote = @MedicalNote,
                ChieuCao = @ChieuCao, CanNang = @CanNang, ThoiGianTap = @ThoiGianTap,
                UpdatedAt = SYSUTCDATETIME()
            WHERE MemberId = @MemberId;
            IF @@ROWCOUNT = 0 THROW 53003, N'Không tìm thấy hội viên.', 1;
            SET @SavedMemberId = @MemberId;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HoiVien_SetActive
    @MemberId int, @IsActive bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @IsActive = 0 AND EXISTS
        (
            SELECT 1 FROM dbo.DangKyGoi
            WHERE MemberId = @MemberId AND Status = 'ACTIVE'
              AND EndDate >= CONVERT(date, DATEADD(HOUR, 7, SYSUTCDATETIME()))
        ) THROW 53004, N'Hãy hủy hoặc kết thúc gói tập đang hiệu lực trước khi ngừng hội viên.', 1;
        UPDATE dbo.HoiVien SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE MemberId = @MemberId;
        IF @@ROWCOUNT = 0 THROW 53003, N'Không tìm thấy hội viên.', 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Gói tập */
CREATE OR ALTER PROCEDURE dbo.sp_GoiTap_DanhSach @IncludeInactive bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, PlanCode, PlanName, Description, DurationDays, Price,
           MaxCheckInsPerDay, AllowsClasses, IsActive
    FROM dbo.GoiTap WHERE IsActive = 1 OR @IncludeInactive = 1
    ORDER BY Price, PlanName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GoiTap_Luu
    @PlanId int = NULL, @PlanCode varchar(20), @PlanName nvarchar(120),
    @DurationDays smallint, @Price decimal(18,2), @MaxCheckInsPerDay tinyint = 1,
    @AllowsClasses bit = 1, @Description nvarchar(500) = NULL,
    @SavedPlanId int = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @PlanId IS NULL
        BEGIN
            INSERT dbo.GoiTap(PlanCode, PlanName, DurationDays, Price, MaxCheckInsPerDay, AllowsClasses, Description)
            VALUES(UPPER(LTRIM(RTRIM(@PlanCode))), LTRIM(RTRIM(@PlanName)), @DurationDays,
                   @Price, @MaxCheckInsPerDay, @AllowsClasses, @Description);
            SET @SavedPlanId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.GoiTap
            SET PlanCode = UPPER(LTRIM(RTRIM(@PlanCode))), PlanName = LTRIM(RTRIM(@PlanName)),
                DurationDays = @DurationDays, Price = @Price, MaxCheckInsPerDay = @MaxCheckInsPerDay,
                AllowsClasses = @AllowsClasses, Description = @Description, UpdatedAt = SYSUTCDATETIME()
            WHERE PlanId = @PlanId;
            IF @@ROWCOUNT = 0 THROW 53010, N'Không tìm thấy gói tập.', 1;
            SET @SavedPlanId = @PlanId;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GoiTap_SetActive @PlanId int, @IsActive bit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.GoiTap SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE PlanId = @PlanId;
        IF @@ROWCOUNT = 0 THROW 53010, N'Không tìm thấy gói tập.', 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Đăng ký gói + hóa đơn + chi tiết + thanh toán đầu tiên là một transaction. */
CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoiTapMoi
    @MemberId int, @PlanId int, @EmployeeId int, @StartDate date,
    @InitialPayment decimal(18,2) = 0, @PaymentMethod varchar(20) = NULL,
    @TransactionReference varchar(100) = NULL,
    @MembershipId bigint = NULL OUTPUT, @InvoiceId bigint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.HoiVien WITH (UPDLOCK, HOLDLOCK) WHERE MemberId = @MemberId AND IsActive = 1)
            THROW 53011, N'Hội viên không tồn tại hoặc đã ngừng hoạt động.', 1;
        DECLARE @DurationDays smallint, @Price decimal(18,2), @PlanName nvarchar(120);
        SELECT @DurationDays = DurationDays, @Price = Price, @PlanName = PlanName
        FROM dbo.GoiTap WHERE PlanId = @PlanId AND IsActive = 1;
        IF @Price IS NULL THROW 53012, N'Gói tập không tồn tại hoặc đã ngừng bán.', 1;
        IF @InitialPayment < 0 OR @InitialPayment > @Price THROW 53013, N'Số tiền thanh toán ban đầu không hợp lệ.', 1;
        IF @InitialPayment > 0 AND @PaymentMethod IS NULL THROW 53014, N'Phải chọn phương thức thanh toán.', 1;
        IF EXISTS
        (
            SELECT 1 FROM dbo.DangKyGoi WITH (UPDLOCK, HOLDLOCK)
            WHERE MemberId = @MemberId AND Status IN ('PENDING', 'ACTIVE', 'SUSPENDED')
              AND EndDate >= @StartDate AND StartDate <= DATEADD(DAY, @DurationDays - 1, @StartDate)
        ) THROW 53015, N'Hội viên đã có gói tập chồng lấn thời gian.', 1;

        DECLARE @MembershipStatus varchar(20) = CASE WHEN @InitialPayment = @Price THEN 'ACTIVE' ELSE 'PENDING' END;
        INSERT dbo.DangKyGoi(MemberId, PlanId, SoldByEmployeeId, StartDate, EndDate, PriceAtPurchase, Status)
        VALUES(@MemberId, @PlanId, @EmployeeId, @StartDate,
               DATEADD(DAY, @DurationDays - 1, @StartDate), @Price, @MembershipStatus);
        SET @MembershipId = SCOPE_IDENTITY();

        DECLARE @InvoiceNumber bigint = NEXT VALUE FOR dbo.Seq_InvoiceCode;
        DECLARE @InvoiceCode varchar(30) = CONCAT('HD', RIGHT(CONCAT('00000000', @InvoiceNumber), 8));
        DECLARE @InvoiceStatus varchar(20) = CASE WHEN @InitialPayment = 0 THEN 'PENDING'
                                                  WHEN @InitialPayment = @Price THEN 'PAID' ELSE 'PARTIAL' END;
        INSERT dbo.HoaDon(InvoiceCode, MembershipId, CreatedByEmployeeId, TotalAmount, PaidAmount, Status)
        VALUES(@InvoiceCode, @MembershipId, @EmployeeId, @Price, @InitialPayment, @InvoiceStatus);
        SET @InvoiceId = SCOPE_IDENTITY();
        INSERT dbo.CTHoaDon(InvoiceId, ItemType, Description, Quantity, UnitPrice, DiscountAmount)
        VALUES(@InvoiceId, 'MEMBERSHIP', @PlanName, 1, @Price, 0);

        IF @InitialPayment > 0
        BEGIN
            DECLARE @PaymentNumber bigint = NEXT VALUE FOR dbo.Seq_PaymentCode;
            DECLARE @PaymentCode varchar(30) = CONCAT('TT', RIGHT(CONCAT('00000000', @PaymentNumber), 8));
            INSERT dbo.ThanhToan(PaymentCode, InvoiceId, ReceivedByEmployeeId, Amount,
                                 PaymentMethod, Status, TransactionReference)
            VALUES(@PaymentCode, @InvoiceId, @EmployeeId, @InitialPayment,
                   @PaymentMethod, 'COMPLETED', @TransactionReference);
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ThanhToan_Them
    @InvoiceId bigint, @EmployeeId int, @Amount decimal(18,2),
    @PaymentMethod varchar(20), @TransactionReference varchar(100) = NULL,
    @PaymentId bigint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Total decimal(18,2), @Paid decimal(18,2), @MembershipId bigint;
        SELECT @Total = TotalAmount, @Paid = PaidAmount, @MembershipId = MembershipId
        FROM dbo.HoaDon WITH (UPDLOCK, HOLDLOCK) WHERE InvoiceId = @InvoiceId AND Status <> 'CANCELLED';
        IF @Total IS NULL THROW 53016, N'Hóa đơn không tồn tại hoặc đã hủy.', 1;
        IF @Amount <= 0 OR @Paid + @Amount > @Total THROW 53017, N'Số tiền vượt quá công nợ còn lại.', 1;
        DECLARE @PaymentNumber bigint = NEXT VALUE FOR dbo.Seq_PaymentCode;
        DECLARE @PaymentCode varchar(30) = CONCAT('TT', RIGHT(CONCAT('00000000', @PaymentNumber), 8));
        INSERT dbo.ThanhToan(PaymentCode, InvoiceId, ReceivedByEmployeeId, Amount,
                             PaymentMethod, Status, TransactionReference)
        VALUES(@PaymentCode, @InvoiceId, @EmployeeId, @Amount, @PaymentMethod, 'COMPLETED', @TransactionReference);
        SET @PaymentId = SCOPE_IDENTITY();
        SET @Paid += @Amount;
        UPDATE dbo.HoaDon
        SET PaidAmount = @Paid, Status = CASE WHEN @Paid = @Total THEN 'PAID' ELSE 'PARTIAL' END,
            UpdatedAt = SYSUTCDATETIME()
        WHERE InvoiceId = @InvoiceId;
        IF @Paid = @Total
            UPDATE dbo.DangKyGoi SET Status = 'ACTIVE', UpdatedAt = SYSUTCDATETIME()
            WHERE MembershipId = @MembershipId AND Status = 'PENDING';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HuyGoiTap @MembershipId bigint, @Reason nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NULLIF(LTRIM(RTRIM(@Reason)), N'') IS NULL THROW 53018, N'Phải nhập lý do hủy.', 1;
        UPDATE dbo.DangKyGoi
        SET Status = 'CANCELLED', CancellationReason = @Reason, UpdatedAt = SYSUTCDATETIME()
        WHERE MembershipId = @MembershipId AND Status IN ('PENDING', 'ACTIVE', 'SUSPENDED');
        IF @@ROWCOUNT = 0 THROW 53019, N'Gói đăng ký không tồn tại hoặc không thể hủy.', 1;

        UPDATE dbo.HoaDon
        SET Status = 'CANCELLED', UpdatedAt = SYSUTCDATETIME()
        WHERE MembershipId = @MembershipId AND Status = 'PENDING' AND PaidAmount = 0;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoi_DanhSach @MemberId int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dk.MembershipId, hv.MemberId, hv.MemberCode, hv.FullName AS MemberName,
           gt.PlanId, gt.PlanName, dk.StartDate, dk.EndDate, dk.PriceAtPurchase,
           dk.Status, hd.InvoiceId, hd.InvoiceCode, hd.TotalAmount, hd.PaidAmount, hd.Status AS InvoiceStatus
    FROM dbo.DangKyGoi AS dk
    INNER JOIN dbo.HoiVien AS hv ON hv.MemberId = dk.MemberId
    INNER JOIN dbo.GoiTap AS gt ON gt.PlanId = dk.PlanId
    LEFT JOIN dbo.HoaDon AS hd ON hd.MembershipId = dk.MembershipId
    WHERE @MemberId IS NULL OR dk.MemberId = @MemberId
    ORDER BY dk.StartDate DESC, dk.MembershipId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTheHinh
    @MemberId int, @ChieuCao int = NULL, @CanNang int = NULL, @ThoiGianTap nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.HoiVien SET ChieuCao=@ChieuCao, CanNang=@CanNang, ThoiGianTap=@ThoiGianTap,
            UpdatedAt=SYSUTCDATETIME() WHERE MemberId=@MemberId;
        IF @@ROWCOUNT = 0 THROW 53003, N'Không tìm thấy hội viên.', 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Tên cũ giữ để tương thích. */
CREATE OR ALTER PROCEDURE dbo.sp_ThemHoiVien
    @FullName nvarchar(120), @Phone varchar(15), @Email varchar(254) = NULL,
    @DateOfBirth date, @Gender varchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SavedMemberId int;
    EXEC dbo.sp_HoiVien_Luu @FullName=@FullName, @Phone=@Phone, @Email=@Email,
         @DateOfBirth=@DateOfBirth, @Gender=@Gender, @SavedMemberId=@SavedMemberId OUTPUT;
    SELECT @SavedMemberId AS MemberId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoGoiTap
    @PlanCode varchar(20), @PlanName nvarchar(120), @DurationDays smallint,
    @Price decimal(18,2), @Description nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SavedPlanId int;
    EXEC dbo.sp_GoiTap_Luu @PlanCode=@PlanCode, @PlanName=@PlanName,
         @DurationDays=@DurationDays, @Price=@Price, @Description=@Description,
         @SavedPlanId=@SavedPlanId OUTPUT;
    SELECT @SavedPlanId AS PlanId;
END;
GO

PRINT N'Đã tạo procedure quản lý hội viên, gói tập, đăng ký, hóa đơn và thanh toán.';
GO
