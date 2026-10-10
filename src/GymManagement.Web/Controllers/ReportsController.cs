using GymManagement.Web.Authorization;
using GymManagement.Web.Models;
using GymManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManagement.Web.Controllers;

[Authorize]
public sealed partial class ReportsController(IGymReportingRepository reports, ILogger<ReportsController> logger) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(string type = "revenue", DateTime? from = null, DateTime? to = null, CancellationToken cancellationToken = default)
    {
        type = type.ToLowerInvariant();
        var canFinance = User.IsInRole(RoleCodes.Admin) || User.IsInRole(RoleCodes.Accountant);
        var canOperations = User.IsInRole(RoleCodes.Admin) || User.IsInRole(RoleCodes.Receptionist) || User.IsInRole(RoleCodes.Trainer);
        if ((type == "revenue" && !canFinance)
            || (type == "members" && !User.IsInRole(RoleCodes.Admin) && !User.IsInRole(RoleCodes.Receptionist))
            || ((type is "classes" or "attendance") && !canOperations)) return Forbid();
        if (type is not ("revenue" or "members" or "classes" or "attendance")) return BadRequest();

        var start = (from ?? DateTime.Today.AddDays(-30)).Date;
        var end = (to ?? DateTime.Today).Date;
        if (start > end || (end - start).TotalDays > 366)
        {
            ViewData["Error"] = "Khoảng ngày không hợp lệ. Hãy chọn ngày bắt đầu trước ngày kết thúc, tối đa 366 ngày.";
            return View(new ReportViewModel { Type = type, From = start, To = end });
        }

        try
        {
            var model = new ReportViewModel { Type = type, From = start, To = end };
            model = type switch
            {
                "revenue" => new() { Type = type, From = start, To = end, Revenue = await reports.GetRevenueAsync(start, end, cancellationToken) },
                "members" => new() { Type = type, From = start, To = end, Expiring = (await reports.GetMembershipSummaryAsync(cancellationToken)).expiring },
                "classes" => new() { Type = type, From = start, To = end, Classes = await reports.GetClassesAsync(start, end, cancellationToken) },
                _ => new() { Type = type, From = start, To = end, Attendance = await reports.GetAttendanceAsync(start, end, cancellationToken) }
            };
            return View(model);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogReportFailure(logger, ex, type);
            ViewData["Error"] = "Không tải được báo cáo. Kiểm tra kết nối và quyền xem báo cáo rồi thử lại.";
            return View(new ReportViewModel { Type = type, From = start, To = end });
        }
    }

    [LoggerMessage(EventId = 2201, Level = LogLevel.Error, Message = "Report {ReportType} failed")]
    private static partial void LogReportFailure(ILogger logger, Exception exception, string reportType);
}
