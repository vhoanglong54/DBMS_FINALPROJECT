-- PHẦN 5A — TV2: hai index tường minh hỗ trợ tìm đăng ký theo hội viên/trạng thái
-- và hóa đơn theo đăng ký/trạng thái; UX_HoiVien_Email nằm trong 01_schema.sql.
USE [$(DatabaseName)];
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DangKyGoi_MemberId_Status')
    CREATE NONCLUSTERED INDEX IX_DangKyGoi_MemberId_Status
    ON dbo.DangKyGoi(MemberId, Status) INCLUDE (StartDate, EndDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HoaDon_MembershipId_Status')
    CREATE NONCLUSTERED INDEX IX_HoaDon_MembershipId_Status
    ON dbo.HoaDon(MembershipId, Status) INCLUDE (TotalAmount, PaidAmount);
GO
