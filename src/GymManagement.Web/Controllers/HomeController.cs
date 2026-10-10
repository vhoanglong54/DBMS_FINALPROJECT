using System.Diagnostics;
using GymManagement.Web.Authorization;
using GymManagement.Web.Models;
using GymManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManagement.Web.Controllers;

[Authorize]
public sealed partial class HomeController(IGymReportingRepository reports, ILogger<HomeController> logger) : Controller
{
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value ?? "";
        var isAdmin = User.IsInRole(RoleCodes.Admin);
        var showMembers = isAdmin || User.IsInRole(RoleCodes.Receptionist);
        var showFinance = isAdmin || User.IsInRole(RoleCodes.Accountant);
        var showOperations = isAdmin || User.IsInRole(RoleCodes.Receptionist) || User.IsInRole(RoleCodes.Trainer);

        int? activeMembers = null;
        IReadOnlyList<ExpiringMembership> expiring = [];
        decimal? monthRevenue = null;
        IReadOnlyList<DailyRevenue> revenue = [];
        IReadOnlyList<ClassSessionReport> classes = [];
        IReadOnlyList<AttendanceReport> attendance = [];
        var notices = new List<string>();

        if (showMembers)
        {
            try
            {
                var summary = await reports.GetMembershipSummaryAsync(cancellationToken);
                activeMembers = summary.active;
                expiring = summary.expiring;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogDashboardMembershipFailure(logger, ex, role);
                notices.Add("Chưa tải được số liệu hội viên. Kiểm tra quyền báo cáo và thử tải lại.");
            }
        }
        if (showFinance)
        {
            try
            {
                var monthStart = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1);
                var monthDays = await reports.GetRevenueAsync(monthStart, DateTime.Today, cancellationToken);
                monthRevenue = monthDays.Sum(r => r.Revenue);
                revenue = monthDays.Where(r => r.Date.Date >= DateTime.Today.AddDays(-6)).ToArray();
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogDashboardRevenueFailure(logger, ex, role);
                notices.Add("Chưa tải được doanh thu. Kiểm tra quyền báo cáo và thử tải lại.");
            }
        }
        if (showOperations)
        {
            try
            {
                classes = await reports.GetClassesAsync(DateTime.Today, DateTime.Today, cancellationToken);
                attendance = await reports.GetAttendanceAsync(DateTime.Today, DateTime.Today, cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                LogDashboardOperationsFailure(logger, ex, role);
                notices.Add("Chưa tải được lịch lớp hoặc điểm danh. Kiểm tra quyền báo cáo và thử tải lại.");
            }
        }

        var model = new DashboardViewModel(
            User.FindFirst("display_name")?.Value ?? User.Identity?.Name ?? "Nhân viên",
            User.Identity?.Name ?? "",
            role,
            User.FindFirst("role_name")?.Value ?? role,
            int.TryParse(User.FindFirst("employee_id")?.Value, out var employeeId) ? employeeId : null,
            bool.TryParse(User.FindFirst("must_change_password")?.Value, out var mustChange) && mustChange,
            activeMembers, expiring, monthRevenue, revenue, classes, attendance,
            notices.Count == 0 ? null : string.Join(" ", notices));
        return View(model);
    }

    [AllowAnonymous]
    public IActionResult Error() => View(model: new ErrorViewModel
    {
        RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier
    });

    [AllowAnonymous]
    public IActionResult HttpStatus(int code)
    {
        Response.StatusCode = code;
        return View(model: code);
    }
    [LoggerMessage(EventId = 2001, Level = LogLevel.Error, Message = "Dashboard membership query failed for role {Role}")]
    private static partial void LogDashboardMembershipFailure(ILogger logger, Exception exception, string role);

    [LoggerMessage(EventId = 2002, Level = LogLevel.Error, Message = "Dashboard revenue query failed for role {Role}")]
    private static partial void LogDashboardRevenueFailure(ILogger logger, Exception exception, string role);

    [LoggerMessage(EventId = 2003, Level = LogLevel.Error, Message = "Dashboard operations query failed for role {Role}")]
    private static partial void LogDashboardOperationsFailure(ILogger logger, Exception exception, string role);
}
