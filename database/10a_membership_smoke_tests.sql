USE [GymManagementDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '--- BAT DAU TEST MODULE MEMBERSHIP & BILLING ---';

-- 1. TEST SP: Tạo gói tập mới
PRINT '1. Dang test: sp_TaoGoiTap...';
IF NOT EXISTS (SELECT 1 FROM dbo.GoiTap WHERE PlanCode = 'VIP-12M')
    EXEC dbo.sp_TaoGoiTap 'VIP-12M', N'Gói VIP 1 Năm', 365, 5000000, N'Tặng khăn, nước uống miễn phí';

-- 2. TEST SP: Thêm hội viên mới (Sử dụng tên tiếng Việt có dấu chuẩn Unicode)
PRINT '2. Dang test: sp_ThemHoiVien...';
EXEC dbo.sp_ThemHoiVien N'Trần Phạm Hữu Thiên', '0901234567', 'thien@email.com', '2000-12-22', 'MALE';

-- Lấy ID hội viên và gói tập vừa tạo
DECLARE @MaHV INT = (SELECT TOP 1 MemberId FROM dbo.HoiVien ORDER BY MemberId DESC);
DECLARE @MaGoi INT = (SELECT TOP 1 PlanId FROM dbo.GoiTap WHERE PlanCode = 'VIP-12M');
DECLARE @MaNV INT = 1;

-- 3. TEST TRANSACTION: Đăng ký gói tập và tự động xuất hóa đơn, thanh toán
PRINT '3. Dang test Transaction: sp_DangKyGoiTapMoi...';
EXEC dbo.sp_DangKyGoiTapMoi @MaHV, @MaGoi, @MaNV, '2026-10-01', 'BANK_TRANSFER';

-- 4. TEST FUNCTION & VIEW: Kiểm tra báo cáo và xếp hạng
PRINT '4. Dang test View va Function...';
SELECT * FROM dbo.vw_HoiVienSapHetHan;
SELECT dbo.fn_TongDoanhThuHoiVien(@MaHV) AS TongDoanhThu, dbo.fn_XepHangHoiVien(@MaHV) AS HangThanhVien;

-- 5. TEST TRIGGER: Cố tình xóa hội viên đang có gói tập còn hạn
PRINT '5. Dang test Trigger: trg_HoiVien_PreventDeleteActive...';
BEGIN TRY
    DELETE FROM dbo.HoiVien WHERE MemberId = @MaHV;
END TRY
BEGIN CATCH
    PRINT '=> TEST TRIGGER THANH CONG: He thong da chan thao tac xoa!';
    PRINT '=> Thong bao loi hop le tu Trigger: ' + ERROR_MESSAGE();
END CATCH

PRINT '--- KET THUC TEST ---';
GO