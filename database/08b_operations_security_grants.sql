USE [$(DatabaseName)];
GO

/*
    rl_GymApp bị DENY SELECT/INSERT/UPDATE/DELETE trên schema dbo (08_security.sql),
    nên ứng dụng chỉ đọc/ghi được qua stored procedure. Procedure thuộc dbo truy cập
    bảng dbo nhờ ownership chaining.

    File này chỉ cấp quyền cho object mới của TV3. Gửi kèm PR để TV1 review.
*/

GRANT EXECUTE ON dbo.sp_PhongTap_Upsert         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_PhongTap_SetActive      TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_PhongTap_DanhSach       TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_PhongTap_ChiTiet        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

GRANT EXECUTE ON dbo.sp_LopTap_Upsert           TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LopTap_SetActive        TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LopTap_DanhSach         TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_LopTap_ChiTiet          TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

GRANT EXECUTE ON dbo.sp_LichLop_TaoLich         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LichLop_HuyLich         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LichLop_DanhSach        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_LichLop_ChiTiet        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_NhanVien_DanhSachHLV    TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

GRANT EXECUTE ON dbo.sp_DatLop_DatCho           TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_DatLop_HuyCho           TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_DatLop_DanhSachTheoBuoi TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_HoiVien_TimKiemNhanh    TO rl_GymApp, rl_GymAdmin, rl_LeTan;

GRANT EXECUTE ON dbo.sp_CheckIn_GhiNhan         TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_CheckIn_LichSu          TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

GRANT SELECT ON dbo.vw_LichLop_ConCho TO rl_LeTan, rl_HuanLuyenVien;
GRANT SELECT ON dbo.vw_LichLop_HomNay TO rl_LeTan, rl_HuanLuyenVien;
GRANT SELECT ON dbo.vw_CongSuatLop    TO rl_LeTan;
GRANT SELECT ON dbo.vw_LichSuCheckIn  TO rl_LeTan, rl_HuanLuyenVien;

PRINT N'Đã cấp quyền cho procedure/view của module Class Operations.';
GO
