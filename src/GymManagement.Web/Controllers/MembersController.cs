using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = Policies.FrontDesk)]
public sealed partial class MembersController(IMemberRepository repository, ILogger<MembersController> logger) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(string? search, bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        try
        {
            var members = await repository.ListAsync(search, includeInactive, cancellationToken);
            return View(new MemberIndexViewModel { Search = search, IncludeInactive = includeInactive, Members = members });
        }
        catch (SqlException exception)
        {
            LogLoadFailure(logger, exception);
            return View(new MemberIndexViewModel
            {
                Search = search,
                IncludeInactive = includeInactive,
                Notice = "Không thể tải dữ liệu hội viên. Hãy kiểm tra kết nối SQL Server."
            });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id, CancellationToken cancellationToken)
    {
        var member = await repository.GetAsync(id, cancellationToken);
        return member is null ? NotFound() : View(member);
    }

    [HttpGet]
    public IActionResult Create() => View("Edit", new MemberEditViewModel());

    [HttpGet]
    public async Task<IActionResult> Edit(int id, CancellationToken cancellationToken)
    {
        var details = await repository.GetAsync(id, cancellationToken);
        return details is null ? NotFound() : View(details.Member);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public Task<IActionResult> Create(MemberEditViewModel model, CancellationToken cancellationToken) => Save(model, cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, MemberEditViewModel model, CancellationToken cancellationToken)
    {
        if (model.Id != id) return BadRequest();
        return await Save(model, cancellationToken);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetActive(int id, bool isActive, CancellationToken cancellationToken)
    {
        try
        {
            await repository.SetActiveAsync(id, isActive, cancellationToken);
            TempData["Success"] = isActive ? "Đã kích hoạt lại hội viên." : "Đã ngừng hoạt động hội viên.";
        }
        catch (SqlException exception)
        {
            LogStateFailure(logger, exception, id);
            TempData["Error"] = exception.Message;
        }
        return RedirectToAction(nameof(Index), new { includeInactive = true });
    }

    private async Task<IActionResult> Save(MemberEditViewModel model, CancellationToken cancellationToken)
    {
        if (model.DateOfBirth.Date > DateTime.Today) ModelState.AddModelError(nameof(model.DateOfBirth), "Ngày sinh không hợp lệ.");
        if (!ModelState.IsValid) return View("Edit", model);
        try
        {
            var id = await repository.SaveAsync(model, cancellationToken);
            TempData["Success"] = model.Id is null ? "Đã thêm hội viên." : "Đã cập nhật hội viên.";
            return RedirectToAction(nameof(Details), new { id });
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            ModelState.AddModelError(string.Empty, "Mã hội viên hoặc email đã tồn tại.");
        }
        catch (SqlException exception)
        {
            LogSaveFailure(logger, exception);
            ModelState.AddModelError(string.Empty, exception.Message);
        }
        return View("Edit", model);
    }

    [LoggerMessage(EventId = 3001, Level = LogLevel.Error, Message = "Cannot load members")]
    private static partial void LogLoadFailure(ILogger logger, Exception exception);
    [LoggerMessage(EventId = 3002, Level = LogLevel.Warning, Message = "Cannot change member {MemberId} active state")]
    private static partial void LogStateFailure(ILogger logger, Exception exception, int memberId);
    [LoggerMessage(EventId = 3003, Level = LogLevel.Warning, Message = "Cannot save member")]
    private static partial void LogSaveFailure(ILogger logger, Exception exception);
}
