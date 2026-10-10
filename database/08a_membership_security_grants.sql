USE [$(DatabaseName)];
GO

GRANT EXECUTE ON dbo.sp_HoiVien_DanhSach TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_HoiVien_ChiTiet TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_HoiVien_Luu TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_HoiVien_SetActive TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_GoiTap_DanhSach TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_KeToan;
GRANT EXECUTE ON dbo.sp_GoiTap_Luu TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_GoiTap_SetActive TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_DangKyGoiTapMoi TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_DangKyGoi_DanhSach TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_KeToan;
GRANT EXECUTE ON dbo.sp_ThanhToan_Them TO rl_GymApp, rl_GymAdmin, rl_KeToan;
GRANT EXECUTE ON dbo.sp_HuyGoiTap TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_CapNhatTheHinh TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GO

PRINT N'Đã cấp quyền procedure cho module hội viên và thanh toán.';
GO
