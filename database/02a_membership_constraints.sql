USE [$(DatabaseName)];
GO

-- Thêm các cột mới cho phân hệ Membership nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'ChieuCao')
    ALTER TABLE dbo.HoiVien ADD ChieuCao INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'CanNang')
    ALTER TABLE dbo.HoiVien ADD CanNang INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'ThoiGianTap')
    ALTER TABLE dbo.HoiVien ADD ThoiGianTap NVARCHAR(50) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoiVien') AND name = 'HangHoiVien')
    ALTER TABLE dbo.HoiVien ADD HangHoiVien VARCHAR(20) NOT NULL CONSTRAINT DF_HoiVien_Hang DEFAULT ('Standard');
GO

-- Ràng buộc dữ liệu hợp lệ
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoiVien_ChieuCao')
    ALTER TABLE dbo.HoiVien ADD CONSTRAINT CK_HoiVien_ChieuCao CHECK (ChieuCao IS NULL OR (ChieuCao BETWEEN 50 AND 250));

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_HoiVien_CanNang')
    ALTER TABLE dbo.HoiVien ADD CONSTRAINT CK_HoiVien_CanNang CHECK (CanNang IS NULL OR (CanNang BETWEEN 20 AND 300));
GO