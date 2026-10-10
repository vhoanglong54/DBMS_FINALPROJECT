USE [$(DatabaseName)];
GO

/* rl_GymApp is denied direct dbo SELECT; grant only the reporting entry points. */
GRANT EXECUTE ON dbo.sp_TV4_TimKiemHoiVien TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_DashboardHoiVien TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoDoanhThu TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoCongSuatLop TO rl_GymApp;
GRANT EXECUTE ON dbo.sp_TV4_BaoCaoDiemDanh TO rl_GymApp;
GO
