-- PHẦN 8B — TV3: GRANT EXECUTE/SELECT cho các điểm vào nghiệp vụ vận hành lớp.
-- Quyền SQL role và policy của tài khoản web là hai lớp khác nhau.
USE [$(DatabaseName)];
GO

/*
    rl_GymApp bị DENY SELECT/INSERT/UPDATE/DELETE trên schema dbo (08_security.sql),
    nên ứng dụng chỉ đọc/ghi được qua stored procedure. Procedure thuộc dbo truy cập
    bảng dbo nhờ ownership chaining.

    File này cấp quyền cho các object vận hành do TV3 phụ trách theo phiếu.
*/

-- Phòng tập: trong các role nghiệp vụ chỉ admin được EXECUTE sửa;
-- rl_GymApp là service role của web, còn quyền người dùng web do policy quyết định.
GRANT EXECUTE ON dbo.sp_PhongTap_Upsert         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_PhongTap_SetActive      TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_PhongTap_DanhSach       TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_PhongTap_ChiTiet        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

-- Loại lớp: cùng nguyên tắc, tách rõ quyền sửa và quyền xem.
GRANT EXECUTE ON dbo.sp_LopTap_Upsert           TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LopTap_SetActive        TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LopTap_DanhSach         TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_LopTap_ChiTiet          TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

-- Lịch lớp: trong các role nghiệp vụ chỉ admin tạo/hủy; lễ tân và HLV được đọc.
GRANT EXECUTE ON dbo.sp_LichLop_TaoLich         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LichLop_HuyLich         TO rl_GymApp, rl_GymAdmin;
GRANT EXECUTE ON dbo.sp_LichLop_DanhSach        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_LichLop_ChiTiet        TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_NhanVien_DanhSachHLV    TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

-- Đặt/hủy chỗ: role lễ tân và admin thao tác; HLV chỉ xem danh sách buổi.
GRANT EXECUTE ON dbo.sp_DatLop_DatCho           TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_DatLop_HuyCho           TO rl_GymApp, rl_GymAdmin, rl_LeTan;
GRANT EXECUTE ON dbo.sp_DatLop_DanhSachTheoBuoi TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_HoiVien_TimKiemNhanh    TO rl_GymApp, rl_GymAdmin, rl_LeTan;

-- Check-in: web truyền EmployeeId từ phiên đăng nhập; procedure so sánh TrainerId
-- với tham số này. Chỉ GRANT EXECUTE cho SQL role không tự ràng buộc danh tính tham số.
GRANT EXECUTE ON dbo.sp_CheckIn_GhiNhan         TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;
GRANT EXECUTE ON dbo.sp_CheckIn_LichSu          TO rl_GymApp, rl_GymAdmin, rl_LeTan, rl_HuanLuyenVien;

-- Quyền đọc trực tiếp bốn view vận hành, không phải quyền ghi bảng nguồn.
GRANT SELECT ON dbo.vw_LichLop_ConCho TO rl_LeTan, rl_HuanLuyenVien;
GRANT SELECT ON dbo.vw_LichLop_HomNay TO rl_LeTan, rl_HuanLuyenVien;
GRANT SELECT ON dbo.vw_CongSuatLop    TO rl_LeTan;
GRANT SELECT ON dbo.vw_LichSuCheckIn  TO rl_LeTan, rl_HuanLuyenVien;

PRINT N'Đã cấp quyền cho procedure/view của module Class Operations.';
GO
