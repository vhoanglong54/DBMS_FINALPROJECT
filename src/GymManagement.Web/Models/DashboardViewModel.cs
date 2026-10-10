namespace GymManagement.Web.Models;

public sealed record DashboardViewModel(
    string DisplayName,
    string Username,
    string RoleCode,
    string RoleName,
    int? EmployeeId,
    bool MustChangePassword,
    int? ActiveMembers,
    IReadOnlyList<ExpiringMembership> Expiring,
    decimal? MonthRevenue,
    IReadOnlyList<DailyRevenue> Revenue,
    IReadOnlyList<ClassSessionReport> Classes,
    IReadOnlyList<AttendanceReport> Attendance,
    string? DataNotice);
