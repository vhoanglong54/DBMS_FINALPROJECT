USE [GymManagementDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '--- BAT DAU TEST MODULE MEMBERSHIP & BILLING ---';

PRINT '1. Dang test: sp_TaoGoiTap...';
IF NOT EXISTS (SELECT 1 FROM dbo.GoiTap WHERE PlanCode = 'VIP-12M')
    EXEC dbo.sp_TaoGoiTap 'VIP-12M', N'Gói VIP 1 Năm', 365, 5000000, N'Tặng khăn, nước uống miễn phí';

PRINT '2. Dang test: sp_ThemHoiVien...';
-- Kiem tra xem email da ton tai chua, neu chua moi them
IF NOT EXISTS (SELECT 1 FROM dbo.HoiVien WHERE Email = 'thien@email.com')
    EXEC dbo.sp_ThemHoiVien N'Trần Phạm Hữu Thiên', '0901234567', 'thien@email.com', '2000-12-22', 'MALE';

DECLARE @MaHV INT = (SELECT TOP 1 MemberId FROM dbo.HoiVien WHERE Email = 'thien@email.com' ORDER BY MemberId DESC);
DECLARE @MaGoi INT = (SELECT TOP 1 PlanId FROM dbo.GoiTap WHERE PlanCode = 'VIP-12M');
DECLARE @MaNV INT = 1;

PRINT '3. Dang test Transaction: sp_DangKyGoiTapMoi...';
-- Kiem tra xem hoi vien nay da co goi tap ACTIVE chua, neu chua moi dang ky
IF NOT EXISTS (SELECT 1 FROM dbo.DangKyGoi WHERE MemberId = @MaHV AND Status = 'ACTIVE' AND EndDate >= GETDATE())
BEGIN
    EXEC dbo.sp_DangKyGoiTapMoi @MaHV, @MaGoi, @MaNV, '2026-10-01', 'BANK_TRANSFER';
    PRINT '=> Dang ky goi tap moi thanh cong.';
END
ELSE
BEGIN
    PRINT '=> Hoi vien da co goi tap ACTIVE tu lan chay truoc. Bo qua dang ky!';
END

PRINT '4. Dang test View va Function...';
SELECT * FROM dbo.vw_HoiVienSapHetHan;
SELECT dbo.fn_TongDoanhThuHoiVien(@MaHV) AS TongDoanhThu, dbo.fn_XepHangHoiVien(@MaHV) AS HangThanhVien;

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