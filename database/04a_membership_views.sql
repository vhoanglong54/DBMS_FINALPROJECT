USE GymManagementDB;
GO

CREATE OR ALTER VIEW dbo.vw_HoiVienSapHetHan
AS
    SELECT 
        hv.MemberId AS MaHV,
        hv.FullName AS HoTen,
        hv.Phone AS SoDienThoai,
        gt.PlanName AS TenGoi,
        dk.EndDate AS NgayKetThuc,
        DATEDIFF(DAY, GETDATE(), dk.EndDate) AS SoNgayConLai
    FROM dbo.DangKyGoi dk
    JOIN dbo.HoiVien hv ON dk.MemberId = hv.MemberId
    JOIN dbo.GoiTap gt ON dk.PlanId = gt.PlanId
    WHERE dk.Status = 'ACTIVE'
      AND DATEDIFF(DAY, GETDATE(), dk.EndDate) BETWEEN 0 AND 30;
GO