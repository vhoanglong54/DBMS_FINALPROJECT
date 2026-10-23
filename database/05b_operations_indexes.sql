-- PHẦN 5B — Index vận hành: TV3 phụ trách bốn index đặt chỗ/lịch/check-in;
-- TV4 phụ trách IX_LichLop_StartAt_Status cho lọc lịch và báo cáo.
USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/*
    Không trùng PK/UNIQUE đã có. Các index phục vụ workload đọc nặng nhất:
    đếm chỗ đã đặt, kiểm tra trùng lịch, tra lịch sử check-in.
    Benchmark trước/sau: tests/index/tv3_benchmark.sql.
*/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DatLop_SessionId_Status')
    CREATE NONCLUSTERED INDEX IX_DatLop_SessionId_Status
        ON dbo.DatLop(SessionId, Status)
        INCLUDE (MemberId, BookedAt);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LichLop_RoomId_StartAt_EndAt')
    CREATE NONCLUSTERED INDEX IX_LichLop_RoomId_StartAt_EndAt
        ON dbo.LichLop(RoomId, Status, StartAt, EndAt);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LichLop_TrainerId_StartAt_EndAt')
    CREATE NONCLUSTERED INDEX IX_LichLop_TrainerId_StartAt_EndAt
        ON dbo.LichLop(TrainerId, Status, StartAt, EndAt);
GO

-- TV4 — Lọc lịch theo thời điểm bắt đầu và trạng thái.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LichLop_StartAt_Status')
    CREATE NONCLUSTERED INDEX IX_LichLop_StartAt_Status
        ON dbo.LichLop(StartAt, Status)
        INCLUDE (ClassId, RoomId, TrainerId, Capacity);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CheckIn_MemberId_CheckedAt')
    CREATE NONCLUSTERED INDEX IX_CheckIn_MemberId_CheckedAt
        ON dbo.CheckIn(MemberId, CheckedAt DESC)
        INCLUDE (SessionId, CheckInMethod);
GO

PRINT N'Đã tạo 5 index cho module Class Operations.';
GO
