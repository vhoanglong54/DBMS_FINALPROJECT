USE [$(DatabaseName)];
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
        ON dbo.LichLop(RoomId, StartAt, EndAt)
        INCLUDE (Status);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LichLop_TrainerId_StartAt_EndAt')
    CREATE NONCLUSTERED INDEX IX_LichLop_TrainerId_StartAt_EndAt
        ON dbo.LichLop(TrainerId, StartAt, EndAt)
        INCLUDE (Status);
GO

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
