using System.Security.Claims;
using GymManagement.Web.Authorization;
using GymManagement.Web.Models;
using GymManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = Policies.AdminOnly)]
public sealed partial class StaffAccountsController(
    IStaffAccountService staffAccounts,
    ILogger<StaffAccountsController> logger) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Forbid();

        try
        {
            return View(await staffAccounts.ListAsync(userId, cancellationToken));
        }
        catch (SqlException exception)
        {
            LogListError(logger, exception);
            ViewData["Notice"] = "Chưa thể tải danh sách tài khoản. Vui lòng thử lại.";
            return View(Array.Empty<StaffAccountRow>());
        }
    }

    [HttpGet]
    public async Task<IActionResult> Create(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId)) return Forbid();

        try
        {
            var code = await staffAccounts.SuggestEmployeeCodeAsync(userId, cancellationToken);
            return View(new StaffAccountCreateViewModel { EmployeeCode = code });
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            LogCreateDenied(logger, exception, userId);
            return Forbid();
        }
        catch (SqlException exception)
        {
            LogSuggestCodeError(logger, exception, userId);
            ModelState.AddModelError(string.Empty, "Chưa thể gợi ý mã nhân viên. Vui lòng thử lại.");
            return View(new StaffAccountCreateViewModel());
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
        StaffAccountCreateViewModel model,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return View(model);
        if (!TryGetUserId(out var userId)) return Forbid();

        try
        {
            await staffAccounts.CreateAsync(userId, model, cancellationToken);
            TempData["Success"] = "Đã cấp tài khoản cho nhân viên.";
            return RedirectToAction(nameof(Index));
        }
        catch (SqlException exception) when (exception.Number == 51046 ||
            (exception.Number is 2601 or 2627 &&
             exception.Message.Contains("UQ_NhanVien_EmployeeCode", StringComparison.OrdinalIgnoreCase)))
        {
            ModelState.AddModelError(nameof(model.EmployeeCode), "Mã nhân viên đã được sử dụng.");
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627 &&
            exception.Message.Contains("UQ_NguoiDung_Username", StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError(nameof(model.Username), "Tên đăng nhập đã được sử dụng.");
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            ModelState.AddModelError(string.Empty, "Mã nhân viên hoặc tên đăng nhập đã được sử dụng.");
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            LogCreateDenied(logger, exception, userId);
            return Forbid();
        }
        catch (SqlException exception)
        {
            LogCreateError(logger, exception, userId);
            ModelState.AddModelError(string.Empty, "Chưa thể cấp tài khoản. Vui lòng kiểm tra thông tin và thử lại.");
        }

        return View(model);
    }

    private bool TryGetUserId(out int userId) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out userId) && userId > 0;

    [LoggerMessage(EventId = 1101, Level = LogLevel.Error, Message = "Cannot list staff accounts.")]
    private static partial void LogListError(ILogger logger, Exception exception);

    [LoggerMessage(EventId = 1102, Level = LogLevel.Warning, Message = "Account provisioning was denied for user {UserId}.")]
    private static partial void LogCreateDenied(ILogger logger, Exception exception, int userId);

    [LoggerMessage(EventId = 1103, Level = LogLevel.Error, Message = "Cannot create staff account for user {UserId}.")]
    private static partial void LogCreateError(ILogger logger, Exception exception, int userId);

    [LoggerMessage(EventId = 1104, Level = LogLevel.Error, Message = "Cannot suggest staff code for user {UserId}.")]
    private static partial void LogSuggestCodeError(ILogger logger, Exception exception, int userId);
}
