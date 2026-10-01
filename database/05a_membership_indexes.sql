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