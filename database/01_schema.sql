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

IF OBJECT_ID(N'dbo.VaiTro', N'U') IS NOT NULL
    THROW 51001, N'Schema đã tồn tại. Hãy dùng database rỗng hoặc quy trình migration, không chạy đè 01_schema.sql.', 1;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.VaiTro
    (
        RoleId          smallint IDENTITY(1,1) NOT NULL,
        RoleCode        varchar(30) NOT NULL,
        RoleName        nvarchar(100) NOT NULL,
        Description     nvarchar(500) NULL,
        IsActive        bit NOT NULL CONSTRAINT DF_VaiTro_IsActive DEFAULT (1),
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_VaiTro_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_VaiTro PRIMARY KEY CLUSTERED (RoleId),
        CONSTRAINT UQ_VaiTro_RoleCode UNIQUE (RoleCode),
        CONSTRAINT UQ_VaiTro_RoleName UNIQUE (RoleName),
        CONSTRAINT CK_VaiTro_RoleCode CHECK (RoleCode NOT LIKE '%[^A-Z_]%')
    );

    CREATE TABLE dbo.NguoiDung
    (
        UserId              int IDENTITY(1,1) NOT NULL,
        RoleId              smallint NOT NULL,
        Username            varchar(50) NOT NULL,
        PasswordHash        varbinary(64) NOT NULL,
        PasswordSalt        varbinary(32) NOT NULL,
        PasswordIterations  int NOT NULL CONSTRAINT DF_NguoiDung_PasswordIterations DEFAULT (100000),
        MustChangePassword  bit NOT NULL CONSTRAINT DF_NguoiDung_MustChangePassword DEFAULT (1),
        FailedLoginCount    tinyint NOT NULL CONSTRAINT DF_NguoiDung_FailedLoginCount DEFAULT (0),
        LockedUntil         datetime2(0) NULL,
        LastLoginAt         datetime2(0) NULL,
        IsActive            bit NOT NULL CONSTRAINT DF_NguoiDung_IsActive DEFAULT (1),
        CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_NguoiDung_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt           datetime2(0) NOT NULL CONSTRAINT DF_NguoiDung_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion          rowversion NOT NULL,
        CONSTRAINT PK_NguoiDung PRIMARY KEY CLUSTERED (UserId),
        CONSTRAINT FK_NguoiDung_VaiTro FOREIGN KEY (RoleId) REFERENCES dbo.VaiTro(RoleId),
        CONSTRAINT UQ_NguoiDung_Username UNIQUE (Username),
        CONSTRAINT CK_NguoiDung_Username CHECK
        (
            LEN(Username) BETWEEN 4 AND 50
            AND Username NOT LIKE '%[^A-Za-z0-9._-]%'
        ),
        CONSTRAINT CK_NguoiDung_PasswordIterations CHECK (PasswordIterations BETWEEN 100000 AND 1000000),
        CONSTRAINT CK_NguoiDung_FailedLoginCount CHECK (FailedLoginCount BETWEEN 0 AND 20)
    );

    CREATE TABLE dbo.NhanVien
    (
        EmployeeId      int IDENTITY(1,1) NOT NULL,
        UserId          int NULL,
        EmployeeCode    varchar(20) NOT NULL,
        FullName        nvarchar(120) NOT NULL,
        DateOfBirth     date NULL,
        Gender          varchar(10) NULL,
        Phone           varchar(15) NOT NULL,
        Email           varchar(254) NULL,
        Address         nvarchar(300) NULL,
        HireDate        date NOT NULL,
        EmployeeType    varchar(20) NOT NULL,
        IsActive        bit NOT NULL CONSTRAINT DF_NhanVien_IsActive DEFAULT (1),
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_NhanVien_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt       datetime2(0) NOT NULL CONSTRAINT DF_NhanVien_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion      rowversion NOT NULL,
        CONSTRAINT PK_NhanVien PRIMARY KEY CLUSTERED (EmployeeId),
        CONSTRAINT FK_NhanVien_NguoiDung FOREIGN KEY (UserId) REFERENCES dbo.NguoiDung(UserId),
        CONSTRAINT UQ_NhanVien_EmployeeCode UNIQUE (EmployeeCode),
        CONSTRAINT CK_NhanVien_EmployeeCode CHECK (EmployeeCode NOT LIKE '%[^A-Z0-9-]%'),
        CONSTRAINT CK_NhanVien_Gender CHECK (Gender IS NULL OR Gender IN ('MALE', 'FEMALE', 'OTHER')),
        CONSTRAINT CK_NhanVien_Phone CHECK (Phone NOT LIKE '%[^0-9+]%' AND LEN(Phone) BETWEEN 9 AND 15),
        CONSTRAINT CK_NhanVien_EmployeeType CHECK (EmployeeType IN ('MANAGER', 'RECEPTIONIST', 'TRAINER', 'ACCOUNTANT'))
    );

    CREATE UNIQUE INDEX UX_NhanVien_UserId
        ON dbo.NhanVien(UserId)
        WHERE UserId IS NOT NULL;

    CREATE TABLE dbo.HoiVien
    (
        MemberId            int IDENTITY(1,1) NOT NULL,
        MemberCode          varchar(20) NOT NULL,
        FullName            nvarchar(120) NOT NULL,
        DateOfBirth         date NOT NULL,
        Gender              varchar(10) NULL,
        Phone               varchar(15) NOT NULL,
        Email               varchar(254) NULL,
        Address             nvarchar(300) NULL,
        EmergencyContact    nvarchar(150) NULL,
        MedicalNote         nvarchar(1000) NULL,
        JoinedAt            date NOT NULL CONSTRAINT DF_HoiVien_JoinedAt DEFAULT (CONVERT(date, SYSUTCDATETIME())),
        IsActive            bit NOT NULL CONSTRAINT DF_HoiVien_IsActive DEFAULT (1),
        CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_HoiVien_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt           datetime2(0) NOT NULL CONSTRAINT DF_HoiVien_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion          rowversion NOT NULL,
        CONSTRAINT PK_HoiVien PRIMARY KEY CLUSTERED (MemberId),
        CONSTRAINT UQ_HoiVien_MemberCode UNIQUE (MemberCode),
        CONSTRAINT CK_HoiVien_MemberCode CHECK (MemberCode NOT LIKE '%[^A-Z0-9-]%'),
        CONSTRAINT CK_HoiVien_Gender CHECK (Gender IS NULL OR Gender IN ('MALE', 'FEMALE', 'OTHER')),
        CONSTRAINT CK_HoiVien_Phone CHECK (Phone NOT LIKE '%[^0-9+]%' AND LEN(Phone) BETWEEN 9 AND 15),
        CONSTRAINT CK_HoiVien_DateOfBirth CHECK (DateOfBirth >= '19000101')
    );

    CREATE UNIQUE INDEX UX_HoiVien_Email
        ON dbo.HoiVien(Email)
        WHERE Email IS NOT NULL;

    CREATE TABLE dbo.GoiTap
    (
        PlanId              int IDENTITY(1,1) NOT NULL,
        PlanCode            varchar(20) NOT NULL,
        PlanName            nvarchar(120) NOT NULL,
        Description         nvarchar(500) NULL,
        DurationDays        smallint NOT NULL,
        Price               decimal(18,2) NOT NULL,
        MaxCheckInsPerDay   tinyint NOT NULL CONSTRAINT DF_GoiTap_MaxCheckInsPerDay DEFAULT (1),
        AllowsClasses       bit NOT NULL CONSTRAINT DF_GoiTap_AllowsClasses DEFAULT (1),
        IsActive            bit NOT NULL CONSTRAINT DF_GoiTap_IsActive DEFAULT (1),
        CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_GoiTap_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt           datetime2(0) NOT NULL CONSTRAINT DF_GoiTap_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion          rowversion NOT NULL,
        CONSTRAINT PK_GoiTap PRIMARY KEY CLUSTERED (PlanId),
        CONSTRAINT UQ_GoiTap_PlanCode UNIQUE (PlanCode),
        CONSTRAINT CK_GoiTap_DurationDays CHECK (DurationDays BETWEEN 1 AND 1095),
        CONSTRAINT CK_GoiTap_Price CHECK (Price >= 0),
        CONSTRAINT CK_GoiTap_MaxCheckInsPerDay CHECK (MaxCheckInsPerDay BETWEEN 1 AND 10)
    );

    CREATE TABLE dbo.DangKyGoi
    (
        MembershipId       bigint IDENTITY(1,1) NOT NULL,
        MemberId           int NOT NULL,
        PlanId             int NOT NULL,
        SoldByEmployeeId   int NOT NULL,
        StartDate          date NOT NULL,
        EndDate            date NOT NULL,
        PriceAtPurchase    decimal(18,2) NOT NULL,
        Status             varchar(20) NOT NULL CONSTRAINT DF_DangKyGoi_Status DEFAULT ('PENDING'),
        CancellationReason nvarchar(500) NULL,
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_DangKyGoi_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt          datetime2(0) NOT NULL CONSTRAINT DF_DangKyGoi_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion         rowversion NOT NULL,
        CONSTRAINT PK_DangKyGoi PRIMARY KEY CLUSTERED (MembershipId),
        CONSTRAINT FK_DangKyGoi_HoiVien FOREIGN KEY (MemberId) REFERENCES dbo.HoiVien(MemberId),
        CONSTRAINT FK_DangKyGoi_GoiTap FOREIGN KEY (PlanId) REFERENCES dbo.GoiTap(PlanId),
        CONSTRAINT FK_DangKyGoi_NhanVien FOREIGN KEY (SoldByEmployeeId) REFERENCES dbo.NhanVien(EmployeeId),
        CONSTRAINT CK_DangKyGoi_Dates CHECK (EndDate >= StartDate),
        CONSTRAINT CK_DangKyGoi_Price CHECK (PriceAtPurchase >= 0),
        CONSTRAINT CK_DangKyGoi_Status CHECK (Status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'EXPIRED', 'CANCELLED')),
        CONSTRAINT CK_DangKyGoi_Cancellation CHECK (Status <> 'CANCELLED' OR CancellationReason IS NOT NULL)
    );

    CREATE TABLE dbo.HoaDon
    (
        InvoiceId          bigint IDENTITY(1,1) NOT NULL,
        InvoiceCode        varchar(30) NOT NULL,
        MembershipId       bigint NOT NULL,
        CreatedByEmployeeId int NOT NULL,
        IssuedAt           datetime2(0) NOT NULL CONSTRAINT DF_HoaDon_IssuedAt DEFAULT (SYSUTCDATETIME()),
        TotalAmount        decimal(18,2) NOT NULL CONSTRAINT DF_HoaDon_TotalAmount DEFAULT (0),
        PaidAmount         decimal(18,2) NOT NULL CONSTRAINT DF_HoaDon_PaidAmount DEFAULT (0),
        Status             varchar(20) NOT NULL CONSTRAINT DF_HoaDon_Status DEFAULT ('PENDING'),
        Note               nvarchar(500) NULL,
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_HoaDon_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt          datetime2(0) NOT NULL CONSTRAINT DF_HoaDon_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion         rowversion NOT NULL,
        CONSTRAINT PK_HoaDon PRIMARY KEY CLUSTERED (InvoiceId),
        CONSTRAINT FK_HoaDon_DangKyGoi FOREIGN KEY (MembershipId) REFERENCES dbo.DangKyGoi(MembershipId),
        CONSTRAINT FK_HoaDon_NhanVien FOREIGN KEY (CreatedByEmployeeId) REFERENCES dbo.NhanVien(EmployeeId),
        CONSTRAINT UQ_HoaDon_InvoiceCode UNIQUE (InvoiceCode),
        CONSTRAINT CK_HoaDon_Amounts CHECK (TotalAmount >= 0 AND PaidAmount >= 0 AND PaidAmount <= TotalAmount),
        CONSTRAINT CK_HoaDon_Status CHECK (Status IN ('PENDING', 'PARTIAL', 'PAID', 'CANCELLED'))
    );

    CREATE TABLE dbo.CTHoaDon
    (
        InvoiceDetailId    bigint IDENTITY(1,1) NOT NULL,
        InvoiceId          bigint NOT NULL,
        ItemType           varchar(30) NOT NULL,
        Description        nvarchar(250) NOT NULL,
        Quantity           smallint NOT NULL CONSTRAINT DF_CTHoaDon_Quantity DEFAULT (1),
        UnitPrice          decimal(18,2) NOT NULL,
        DiscountAmount     decimal(18,2) NOT NULL CONSTRAINT DF_CTHoaDon_Discount DEFAULT (0),
        LineTotal AS (CONVERT(decimal(18,2), Quantity * UnitPrice - DiscountAmount)) PERSISTED,
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_CTHoaDon_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_CTHoaDon PRIMARY KEY CLUSTERED (InvoiceDetailId),
        CONSTRAINT FK_CTHoaDon_HoaDon FOREIGN KEY (InvoiceId) REFERENCES dbo.HoaDon(InvoiceId),
        CONSTRAINT CK_CTHoaDon_ItemType CHECK (ItemType IN ('MEMBERSHIP', 'CLASS', 'SERVICE', 'PRODUCT', 'DISCOUNT')),
        CONSTRAINT CK_CTHoaDon_Amounts CHECK (Quantity > 0 AND UnitPrice >= 0 AND DiscountAmount >= 0 AND DiscountAmount <= Quantity * UnitPrice)
    );

    CREATE TABLE dbo.ThanhToan
    (
        PaymentId          bigint IDENTITY(1,1) NOT NULL,
        PaymentCode        varchar(30) NOT NULL,
        InvoiceId          bigint NOT NULL,
        ReceivedByEmployeeId int NOT NULL,
        Amount             decimal(18,2) NOT NULL,
        PaymentMethod      varchar(20) NOT NULL,
        Status             varchar(20) NOT NULL CONSTRAINT DF_ThanhToan_Status DEFAULT ('COMPLETED'),
        TransactionReference varchar(100) NULL,
        PaidAt             datetime2(0) NOT NULL CONSTRAINT DF_ThanhToan_PaidAt DEFAULT (SYSUTCDATETIME()),
        Note               nvarchar(500) NULL,
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_ThanhToan_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ThanhToan PRIMARY KEY CLUSTERED (PaymentId),
        CONSTRAINT FK_ThanhToan_HoaDon FOREIGN KEY (InvoiceId) REFERENCES dbo.HoaDon(InvoiceId),
        CONSTRAINT FK_ThanhToan_NhanVien FOREIGN KEY (ReceivedByEmployeeId) REFERENCES dbo.NhanVien(EmployeeId),
        CONSTRAINT UQ_ThanhToan_PaymentCode UNIQUE (PaymentCode),
        CONSTRAINT CK_ThanhToan_Amount CHECK (Amount > 0),
        CONSTRAINT CK_ThanhToan_Method CHECK (PaymentMethod IN ('CASH', 'BANK_TRANSFER', 'CARD', 'E_WALLET')),
        CONSTRAINT CK_ThanhToan_Status CHECK (Status IN ('PENDING', 'COMPLETED', 'VOIDED', 'REFUNDED'))
    );

    CREATE TABLE dbo.PhongTap
    (
        RoomId          int IDENTITY(1,1) NOT NULL,
        RoomCode        varchar(20) NOT NULL,
        RoomName        nvarchar(100) NOT NULL,
        Capacity        smallint NOT NULL,
        Location        nvarchar(200) NULL,
        IsActive        bit NOT NULL CONSTRAINT DF_PhongTap_IsActive DEFAULT (1),
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_PhongTap_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt       datetime2(0) NOT NULL CONSTRAINT DF_PhongTap_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion      rowversion NOT NULL,
        CONSTRAINT PK_PhongTap PRIMARY KEY CLUSTERED (RoomId),
        CONSTRAINT UQ_PhongTap_RoomCode UNIQUE (RoomCode),
        CONSTRAINT CK_PhongTap_Capacity CHECK (Capacity BETWEEN 1 AND 500)
    );

    CREATE TABLE dbo.LopTap
    (
        ClassId          int IDENTITY(1,1) NOT NULL,
        ClassCode        varchar(20) NOT NULL,
        ClassName        nvarchar(120) NOT NULL,
        Description      nvarchar(500) NULL,
        DefaultDurationMinutes smallint NOT NULL,
        DifficultyLevel  varchar(20) NOT NULL CONSTRAINT DF_LopTap_Difficulty DEFAULT ('ALL_LEVELS'),
        IsActive         bit NOT NULL CONSTRAINT DF_LopTap_IsActive DEFAULT (1),
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_LopTap_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt        datetime2(0) NOT NULL CONSTRAINT DF_LopTap_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion       rowversion NOT NULL,
        CONSTRAINT PK_LopTap PRIMARY KEY CLUSTERED (ClassId),
        CONSTRAINT UQ_LopTap_ClassCode UNIQUE (ClassCode),
        CONSTRAINT CK_LopTap_Duration CHECK (DefaultDurationMinutes BETWEEN 15 AND 240),
        CONSTRAINT CK_LopTap_Difficulty CHECK (DifficultyLevel IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ALL_LEVELS'))
    );

    CREATE TABLE dbo.LichLop
    (
        SessionId       bigint IDENTITY(1,1) NOT NULL,
        ClassId         int NOT NULL,
        RoomId          int NOT NULL,
        TrainerId       int NOT NULL,
        StartAt         datetime2(0) NOT NULL,
        EndAt           datetime2(0) NOT NULL,
        Capacity        smallint NOT NULL,
        Status          varchar(20) NOT NULL CONSTRAINT DF_LichLop_Status DEFAULT ('SCHEDULED'),
        Note            nvarchar(500) NULL,
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_LichLop_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt       datetime2(0) NOT NULL CONSTRAINT DF_LichLop_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion      rowversion NOT NULL,
        CONSTRAINT PK_LichLop PRIMARY KEY CLUSTERED (SessionId),
        CONSTRAINT FK_LichLop_LopTap FOREIGN KEY (ClassId) REFERENCES dbo.LopTap(ClassId),
        CONSTRAINT FK_LichLop_PhongTap FOREIGN KEY (RoomId) REFERENCES dbo.PhongTap(RoomId),
        CONSTRAINT FK_LichLop_NhanVien FOREIGN KEY (TrainerId) REFERENCES dbo.NhanVien(EmployeeId),
        CONSTRAINT CK_LichLop_Time CHECK (EndAt > StartAt),
        CONSTRAINT CK_LichLop_Capacity CHECK (Capacity BETWEEN 1 AND 500),
        CONSTRAINT CK_LichLop_Status CHECK (Status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
    );

    CREATE TABLE dbo.DatLop
    (
        BookingId       bigint IDENTITY(1,1) NOT NULL,
        MemberId        int NOT NULL,
        SessionId       bigint NOT NULL,
        Status          varchar(20) NOT NULL CONSTRAINT DF_DatLop_Status DEFAULT ('CONFIRMED'),
        BookedAt        datetime2(0) NOT NULL CONSTRAINT DF_DatLop_BookedAt DEFAULT (SYSUTCDATETIME()),
        CancelledAt     datetime2(0) NULL,
        CancellationReason nvarchar(500) NULL,
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_DatLop_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt       datetime2(0) NOT NULL CONSTRAINT DF_DatLop_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion      rowversion NOT NULL,
        CONSTRAINT PK_DatLop PRIMARY KEY CLUSTERED (BookingId),
        CONSTRAINT FK_DatLop_HoiVien FOREIGN KEY (MemberId) REFERENCES dbo.HoiVien(MemberId),
        CONSTRAINT FK_DatLop_LichLop FOREIGN KEY (SessionId) REFERENCES dbo.LichLop(SessionId),
        CONSTRAINT UQ_DatLop_Member_Session UNIQUE (MemberId, SessionId),
        CONSTRAINT CK_DatLop_Status CHECK (Status IN ('CONFIRMED', 'WAITLISTED', 'ATTENDED', 'NO_SHOW', 'CANCELLED')),
        CONSTRAINT CK_DatLop_Cancellation CHECK
        (
            (Status = 'CANCELLED' AND CancelledAt IS NOT NULL)
            OR (Status <> 'CANCELLED' AND CancelledAt IS NULL)
        )
    );

    CREATE TABLE dbo.CheckIn
    (
        CheckInId       bigint IDENTITY(1,1) NOT NULL,
        MemberId        int NOT NULL,
        EmployeeId      int NOT NULL,
        SessionId       bigint NULL,
        CheckedAt       datetime2(0) NOT NULL CONSTRAINT DF_CheckIn_CheckedAt DEFAULT (SYSUTCDATETIME()),
        CheckInMethod   varchar(20) NOT NULL CONSTRAINT DF_CheckIn_Method DEFAULT ('FRONT_DESK'),
        Note            nvarchar(500) NULL,
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_CheckIn_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_CheckIn PRIMARY KEY CLUSTERED (CheckInId),
        CONSTRAINT FK_CheckIn_HoiVien FOREIGN KEY (MemberId) REFERENCES dbo.HoiVien(MemberId),
        CONSTRAINT FK_CheckIn_NhanVien FOREIGN KEY (EmployeeId) REFERENCES dbo.NhanVien(EmployeeId),
        CONSTRAINT FK_CheckIn_LichLop FOREIGN KEY (SessionId) REFERENCES dbo.LichLop(SessionId),
        CONSTRAINT CK_CheckIn_Method CHECK (CheckInMethod IN ('FRONT_DESK', 'BARCODE', 'KIOSK'))
    );

    CREATE TABLE dbo.AuditLog
    (
        AuditId         bigint IDENTITY(1,1) NOT NULL,
        TableName       sysname NOT NULL,
        ActionType      varchar(10) NOT NULL,
        EntityKey       nvarchar(200) NOT NULL,
        OldValues       nvarchar(max) NULL,
        NewValues       nvarchar(max) NULL,
        ChangedByUserId int NULL,
        CorrelationId   uniqueidentifier NOT NULL CONSTRAINT DF_AuditLog_CorrelationId DEFAULT (NEWID()),
        ChangedAt       datetime2(0) NOT NULL CONSTRAINT DF_AuditLog_ChangedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_AuditLog PRIMARY KEY CLUSTERED (AuditId),
        CONSTRAINT FK_AuditLog_NguoiDung FOREIGN KEY (ChangedByUserId) REFERENCES dbo.NguoiDung(UserId),
        CONSTRAINT CK_AuditLog_ActionType CHECK (ActionType IN ('INSERT', 'UPDATE', 'DELETE', 'LOGIN')),
        CONSTRAINT CK_AuditLog_OldValuesJson CHECK (OldValues IS NULL OR ISJSON(OldValues) = 1),
        CONSTRAINT CK_AuditLog_NewValuesJson CHECK (NewValues IS NULL OR ISJSON(NewValues) = 1)
    );

    COMMIT TRANSACTION;
    PRINT N'Đã tạo 15 bảng và toàn bộ PK/FK/constraint nền tảng.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
