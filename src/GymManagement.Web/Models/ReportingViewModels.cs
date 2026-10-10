namespace GymManagement.Web.Models;

public sealed record DailyRevenue(DateTime Date, decimal Revenue, int PaymentCount);
public sealed record ExpiringMembership(int MemberId, string Name, string Phone, string PlanName, DateTime EndDate, int DaysRemaining);
public sealed record ClassSessionReport(long SessionId, string ClassName, string RoomName, string TrainerName,
    DateTime StartAt, DateTime EndAt, int Capacity, int Booked, int Available, string Status);
public sealed record AttendanceReport(long CheckInId, int MemberId, string MemberCode, string MemberName,
    string EmployeeName, string? ClassName, DateTime CheckedAt, string Method);
public sealed record MemberSearchRow(int MemberId, string MemberCode, string Name, string Phone, string? Email,
    string Status, DateTime? StartDate, DateTime? EndDate);

public sealed class MemberSearchViewModel
{
    public string? Query { get; init; }
    public string? Status { get; init; }
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalCount { get; init; }
    public IReadOnlyList<MemberSearchRow> Members { get; init; } = [];
    public string? Notice { get; init; }
    public int PageCount => Math.Max(1, (int)Math.Ceiling(TotalCount / (double)Math.Max(PageSize, 1)));
}

public sealed class ReportViewModel
{
    public string Type { get; init; } = "revenue";
    public DateTime From { get; init; }
    public DateTime To { get; init; }
    public IReadOnlyList<DailyRevenue> Revenue { get; init; } = [];
    public IReadOnlyList<ExpiringMembership> Expiring { get; init; } = [];
    public IReadOnlyList<ClassSessionReport> Classes { get; init; } = [];
    public IReadOnlyList<AttendanceReport> Attendance { get; init; } = [];
    public string? Notice { get; init; }
}
