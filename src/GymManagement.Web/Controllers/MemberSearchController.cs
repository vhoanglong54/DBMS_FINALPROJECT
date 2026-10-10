using GymManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = "MembershipSearch")]
public sealed partial class MemberSearchController(IGymReportingRepository reports, ILogger<MemberSearchController> logger) : Controller
{
    private static readonly string[] AllowedStatuses = ["ACTIVE", "EXPIRED", "PENDING", "SUSPENDED", "CANCELLED", "NO_MEMBERSHIP", "INACTIVE"];
    private static readonly int[] PageSizeOptions = [10, 20, 50, 100];

    [HttpGet]
    public async Task<IActionResult> Index(string? q, string? status, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = PageSizeOptions.Contains(pageSize) ? pageSize : 20;
        q = string.IsNullOrWhiteSpace(q) ? null : q.Trim()[..Math.Min(q.Trim().Length, 120)];
        if (!AllowedStatuses.Contains(status, StringComparer.OrdinalIgnoreCase)) status = null;

        try { return View(await reports.SearchMembersAsync(q, status, page, pageSize, cancellationToken)); }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogMemberSearchFailure(logger, ex);
            return View(new Models.MemberSearchViewModel
            {
                Query = q,
                Status = status,
                Page = page,
                PageSize = pageSize,
                Notice = "Không tải được kết quả. Kiểm tra kết nối SQL Server và thử lại."
            });
        }
    }

    [LoggerMessage(EventId = 2101, Level = LogLevel.Error, Message = "Member report search failed")]
    private static partial void LogMemberSearchFailure(ILogger logger, Exception exception);
}
