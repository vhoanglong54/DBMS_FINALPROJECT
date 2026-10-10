using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public interface IGymReportingRepository
{
    Task<(int active, IReadOnlyList<ExpiringMembership> expiring)> GetMembershipSummaryAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<DailyRevenue>> GetRevenueAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken);
    Task<IReadOnlyList<ClassSessionReport>> GetClassesAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken);
    Task<IReadOnlyList<AttendanceReport>> GetAttendanceAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken);
    Task<MemberSearchViewModel> SearchMembersAsync(string? query, string? status, int page, int pageSize, CancellationToken cancellationToken);
}
