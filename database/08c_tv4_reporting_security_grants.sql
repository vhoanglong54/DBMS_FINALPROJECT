-- PHẦN 8C — TV4: cấp quyền gọi đúng 5 procedure báo cáo/tìm kiếm.
-- Không cấp SELECT bảng nguồn cho rl_GymApp trong file này.
USE [$(DatabaseName)];
GO

-- rl_GymApp bị DENY SELECT trực tiếp schema dbo trong 08_security.sql.
GRANT EXECUTE ON dbo.sp_TV4_TimKiemHoiVien TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_DashboardHoiVien TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoDoanhThu TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoCongSuatLop TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoDiemDanh TO rl_GymApp;
GO
