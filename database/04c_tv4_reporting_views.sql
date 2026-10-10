/* GYM-09: read-only reporting views consumed through TV4 reporting procedures. */
USE [$(DatabaseName)];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.vw_TV4_HoiVienTraCuu
AS
    SELECT
        hv.MemberId,
        hv.MemberCode,
        hv.FullName AS MemberName,
        hv.Phone,
        hv.Email,
        hv.IsActive AS MemberIsActive,
        CASE
            WHEN hv.IsActive = 0 THEN 'INACTIVE'
            WHEN membership.MembershipId IS NULL THEN 'NO_MEMBERSHIP'
            WHEN membership.Status = 'ACTIVE'
                 AND membership.StartDate <= CONVERT(date, GETDATE())
                 AND membership.EndDate >= CONVERT(date, GETDATE()) THEN 'ACTIVE'
            WHEN membership.Status = 'ACTIVE' AND membership.EndDate < CONVERT(date, GETDATE()) THEN 'EXPIRED'
            ELSE membership.Status
        END AS MembershipStatus,
        membership.StartDate,
        membership.EndDate
    FROM dbo.HoiVien AS hv
    OUTER APPLY
    (
        SELECT TOP (1) dk.MembershipId, dk.Status, dk.StartDate, dk.EndDate
        FROM dbo.DangKyGoi AS dk
        WHERE dk.MemberId = hv.MemberId
        ORDER BY CASE WHEN dk.Status = 'ACTIVE'
                            AND dk.StartDate <= CONVERT(date, GETDATE())
                            AND dk.EndDate >= CONVERT(date, GETDATE()) THEN 0 ELSE 1 END,
                 dk.EndDate DESC, dk.MembershipId DESC
    ) AS membership;
GO

CREATE OR ALTER VIEW dbo.vw_TV4_DoanhThuTheoNgay
AS
    SELECT
        CONVERT(date, DATEADD(HOUR, 7, tt.PaidAt)) AS RevenueDate,
        CONVERT(decimal(18,2), SUM(tt.Amount)) AS Revenue,
        CONVERT(int, COUNT_BIG(1)) AS PaymentCount
    FROM dbo.ThanhToan AS tt
    INNER JOIN dbo.HoaDon AS hd ON hd.InvoiceId = tt.InvoiceId
    WHERE tt.Status = 'COMPLETED'
      AND hd.Status <> 'CANCELLED'
    GROUP BY CONVERT(date, DATEADD(HOUR, 7, tt.PaidAt));
GO

PRINT N'GYM-09: đã tạo view tra cứu hội viên và doanh thu ngày.';
GO
