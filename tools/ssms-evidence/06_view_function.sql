USE [GymManagementDemo];
GO

SET NOCOUNT ON;

SELECT TOP (10)
    SessionId,
    ClassName,
    RoomName,
    StartAt,
    Capacity,
    ConfirmedCount,
    SeatsLeft
FROM dbo.vw_LichLop_ConCho
ORDER BY StartAt;

SELECT
    l.SessionId,
    [SoChoConLai_TuFunction] = dbo.fn_ChoTrongLop(l.SessionId),
    dk.MemberActive,
    dk.HasActivePlan,
    dk.PlanAllowsClasses,
    dk.HasOverlap
FROM dbo.LichLop AS l
CROSS APPLY dbo.fn_DieuKienDatLop(2, l.SessionId) AS dk
WHERE l.Status = 'SCHEDULED'
ORDER BY l.SessionId;
GO
