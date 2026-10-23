-- PHẦN 2A — TV2: SEQUENCE sinh mã hội viên/hóa đơn/thanh toán,
-- bổ sung cột thể trạng và CHECK giới hạn giá trị hợp lệ.
USE [$(DatabaseName)];
GO

IF OBJECT_ID(N'dbo.Seq_MemberCode', N'SO') IS NULL
    EXEC(N'CREATE SEQUENCE dbo.Seq_MemberCode AS bigint START WITH 100 INCREMENT BY 1;');
IF OBJECT_ID(N'dbo.Seq_InvoiceCode', N'SO') IS NULL
    EXEC(N'CREATE SEQUENCE dbo.Seq_InvoiceCode AS bigint START WITH 100 INCREMENT BY 1;');
IF OBJECT_ID(N'dbo.Seq_PaymentCode', N'SO') IS NULL
    EXEC(N'CREATE SEQUENCE dbo.Seq_PaymentCode AS bigint START WITH 100 INCREMENT BY 1;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'ChieuCao')
    ALTER TABLE dbo.HoiVien ADD ChieuCao INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'CanNang')
    ALTER TABLE dbo.HoiVien ADD CanNang INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'ThoiGianTap')
    ALTER TABLE dbo.HoiVien ADD ThoiGianTap NVARCHAR(50) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoiVien_ChieuCao')
    ALTER TABLE dbo.HoiVien ADD CONSTRAINT CK_HoiVien_ChieuCao CHECK (ChieuCao IS NULL OR (ChieuCao BETWEEN 50 AND 250));

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoiVien_CanNang')
    ALTER TABLE dbo.HoiVien ADD CONSTRAINT CK_HoiVien_CanNang CHECK (CanNang IS NULL OR (CanNang BETWEEN 20 AND 300));
GO
