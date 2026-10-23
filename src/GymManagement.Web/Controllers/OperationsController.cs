using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = Policies.Operations)]
public sealed partial class OperationsController(
    IOperationsRepository repository,
    ILogger<OperationsController> logger) : Controller
{
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        var model = new OperationsIndexViewModel
        {
            Rooms = await repository.RoomsAsync(true, cancellationToken),
            Classes = await repository.ClassesAsync(true, cancellationToken),
            Sessions = await repository.SessionsAsync(
                DateTime.Today,
                DateTime.Today.AddDays(30),
                cancellationToken)
        };
        return View(model);
    }

    [HttpGet]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> Room(int? id, CancellationToken cancellationToken)
    {
        if (id is null) return View(new RoomEditViewModel());

        var room = await repository.RoomAsync(id.Value, cancellationToken);
        if (room is null) return NotFound();

        return View(new RoomEditViewModel
        {
            Id = room.Id,
            Code = room.Code,
            Name = room.Name,
            Capacity = room.Capacity,
            Location = room.Location
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public Task<IActionResult> Room(
        RoomEditViewModel model,
        CancellationToken cancellationToken) =>
        SaveCatalogAsync(model, repository.SaveRoomAsync, "Đã lưu phòng tập.", cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> SetRoomActive(
        int id,
        bool active,
        CancellationToken cancellationToken)
    {
        try { await repository.SetRoomActiveAsync(id, active, cancellationToken); }
        catch (SqlException exception) { TempData["Error"] = exception.Message; }
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> ClassType(int? id, CancellationToken cancellationToken)
    {
        if (id is null) return View(new ClassTypeEditViewModel());

        var classType = await repository.ClassAsync(id.Value, cancellationToken);
        if (classType is null) return NotFound();

        return View(new ClassTypeEditViewModel
        {
            Id = classType.Id,
            Code = classType.Code,
            Name = classType.Name,
            Description = classType.Description,
            Duration = classType.Duration,
            Difficulty = classType.Difficulty
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public Task<IActionResult> ClassType(
        ClassTypeEditViewModel model,
        CancellationToken cancellationToken) =>
        SaveCatalogAsync(model, repository.SaveClassAsync, "Đã lưu loại lớp.", cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> SetClassActive(
        int id,
        bool active,
        CancellationToken cancellationToken)
    {
        try { await repository.SetClassActiveAsync(id, active, cancellationToken); }
        catch (SqlException exception) { TempData["Error"] = exception.Message; }
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> CreateSession(CancellationToken cancellationToken)
    {
        var model = new SessionCreateViewModel();
        await PopulateSessionOptionsAsync(model, cancellationToken);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> CreateSession(
        SessionCreateViewModel model,
        CancellationToken cancellationToken)
    {
        if (model.EndAt <= model.StartAt)
            ModelState.AddModelError(nameof(model.EndAt), "Giờ kết thúc phải sau giờ bắt đầu.");

        if (!ModelState.IsValid)
        {
            await PopulateSessionOptionsAsync(model, cancellationToken);
            return View(model);
        }

        try
        {
            var id = await repository.CreateSessionAsync(model, cancellationToken);
            return RedirectToAction(nameof(Session), new { id });
        }
        catch (SqlException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            await PopulateSessionOptionsAsync(model, cancellationToken);
            return View(model);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Session(long id, CancellationToken cancellationToken)
    {
        var session = await repository.SessionAsync(id, cancellationToken);
        if (session is null) return NotFound();

        return View(new SessionDetailsViewModel
        {
            Session = session,
            Bookings = await repository.BookingsAsync(id, cancellationToken)
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.AdminOnly)]
    public async Task<IActionResult> CancelSession(
        long id,
        string reason,
        CancellationToken cancellationToken)
    {
        try
        {
            await repository.CancelSessionAsync(id, reason, cancellationToken);
        }
        catch (SqlException exception)
        {
            TempData["Error"] = exception.Message;
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.FrontDesk)]
    public async Task<IActionResult> Book(
        long sessionId,
        string memberCode,
        CancellationToken cancellationToken)
    {
        try
        {
            var member = await FindActiveMemberAsync(memberCode, cancellationToken);
            if (member is null)
            {
                TempData["Error"] = "Không tìm thấy hội viên đang hoạt động với mã đã nhập.";
                return RedirectToAction(nameof(Session), new { id = sessionId });
            }

            var result = await repository.BookAsync(member.Id, sessionId, cancellationToken);
            var resultLabel = result.status == "WAITLISTED" ? "đã vào hàng chờ" : "đã xác nhận";
            TempData["Success"] = $"Đặt chỗ cho {member.Code} thành công ({resultLabel}).";
        }
        catch (SqlException exception)
        {
            TempData["Error"] = exception.Message;
        }
        return RedirectToAction(nameof(Session), new { id = sessionId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = Policies.FrontDesk)]
    public async Task<IActionResult> CancelBooking(
        long id,
        long sessionId,
        string reason,
        CancellationToken cancellationToken)
    {
        try
        {
            await repository.CancelBookingAsync(id, reason, cancellationToken);
        }
        catch (SqlException exception)
        {
            TempData["Error"] = exception.Message;
        }
        return RedirectToAction(nameof(Session), new { id = sessionId });
    }

    [HttpGet]
    public async Task<IActionResult> CheckIn(string? memberCode, CancellationToken cancellationToken)
    {
        var model = new CheckInViewModel
        {
            MemberCode = memberCode ?? string.Empty,
            History = await repository.CheckInHistoryAsync(
                (await FindActiveMemberAsync(memberCode, cancellationToken))?.Id,
                cancellationToken)
        };
        await PopulateCheckInOptionsAsync(model, cancellationToken);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CheckIn(
        CheckInViewModel model,
        CancellationToken cancellationToken)
    {
        if (User.IsInRole(RoleCodes.Trainer) && model.SessionId is null)
            ModelState.AddModelError(nameof(model.SessionId), "Huấn luyện viên phải chọn buổi lớp mình phụ trách.");

        if (!ModelState.IsValid)
        {
            model.History = await repository.CheckInHistoryAsync(null, cancellationToken);
            await PopulateCheckInOptionsAsync(model, cancellationToken);
            return View(model);
        }

        try
        {
            var member = await FindActiveMemberAsync(model.MemberCode, cancellationToken);
            if (member is null)
            {
                ModelState.AddModelError(nameof(model.MemberCode), "Không tìm thấy hội viên đang hoạt động với mã này.");
                model.History = await repository.CheckInHistoryAsync(null, cancellationToken);
                await PopulateCheckInOptionsAsync(model, cancellationToken);
                return View(model);
            }

            var id = await repository.CheckInAsync(
                member.Id,
                GetEmployeeId(),
                model.SessionId,
                model.Method,
                cancellationToken);
            TempData["Success"] = $"Check-in {member.Code} thành công (giao dịch #{id}).";
            return RedirectToAction(nameof(CheckIn), new { memberCode = member.Code });
        }
        catch (SqlException exception)
        {
            LogCheckInFailure(logger, exception);
            ModelState.AddModelError(string.Empty, exception.Message);
            model.History = await repository.CheckInHistoryAsync(null, cancellationToken);
            await PopulateCheckInOptionsAsync(model, cancellationToken);
            return View(model);
        }
    }

    private async Task PopulateCheckInOptionsAsync(CheckInViewModel model, CancellationToken cancellationToken)
    {
        model.IsTrainer = User.IsInRole(RoleCodes.Trainer);
        var now = DateTime.UtcNow.AddHours(7);
        var sessions = await repository.SessionsAsync(now.Date.AddDays(-1), now.Date.AddDays(1), cancellationToken);
        model.AvailableSessions = sessions.Where(session =>
            (session.Status is "SCHEDULED" or "IN_PROGRESS")
            && session.StartAt.AddMinutes(-30) <= now
            && session.EndAt >= now
            && (!model.IsTrainer || session.TrainerId == GetEmployeeId())).ToArray();
    }

    private async Task<MemberLookupRow?> FindActiveMemberAsync(
        string? memberCode,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(memberCode)) return null;

        var normalizedCode = memberCode.Trim();
        return await repository.FindActiveMemberAsync(normalizedCode, cancellationToken);
    }

    private int GetEmployeeId() =>
        int.TryParse(User.FindFirst("employee_id")?.Value, out var id)
            ? id
            : throw new InvalidOperationException("Tài khoản chưa gắn nhân viên.");

    private async Task PopulateSessionOptionsAsync(
        SessionCreateViewModel model,
        CancellationToken cancellationToken)
    {
        model.Rooms = await repository.RoomsAsync(false, cancellationToken);
        model.Classes = await repository.ClassesAsync(false, cancellationToken);
        model.Trainers = await repository.TrainersAsync(cancellationToken);
    }

    private async Task<IActionResult> SaveCatalogAsync<T>(
        T model,
        Func<T, CancellationToken, Task<int>> save,
        string successMessage,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            await save(model, cancellationToken);
            TempData["Success"] = successMessage;
            return RedirectToAction(nameof(Index));
        }
        catch (SqlException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(model);
        }
    }

    [LoggerMessage(EventId = 3201, Level = LogLevel.Warning, Message = "Check-in failed")]
    private static partial void LogCheckInFailure(ILogger logger, Exception exception);
}
