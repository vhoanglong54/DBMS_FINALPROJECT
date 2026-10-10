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
    public async Task<IActionResult> Room(int? id, CancellationToken cancellationToken)
    {
        if (id is null) return View(new RoomEditViewModel());

        var room = (await repository.RoomsAsync(true, cancellationToken))
            .FirstOrDefault(item => item.Id == id);
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
    public Task<IActionResult> Room(
        RoomEditViewModel model,
        CancellationToken cancellationToken) =>
        SaveCatalogAsync(model, repository.SaveRoomAsync, "Đã lưu phòng tập.", cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetRoomActive(
        int id,
        bool active,
        CancellationToken cancellationToken)
    {
        await repository.SetRoomActiveAsync(id, active, cancellationToken);
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> ClassType(int? id, CancellationToken cancellationToken)
    {
        if (id is null) return View(new ClassTypeEditViewModel());

        var classType = (await repository.ClassesAsync(true, cancellationToken))
            .FirstOrDefault(item => item.Id == id);
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
    public Task<IActionResult> ClassType(
        ClassTypeEditViewModel model,
        CancellationToken cancellationToken) =>
        SaveCatalogAsync(model, repository.SaveClassAsync, "Đã lưu loại lớp.", cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetClassActive(
        int id,
        bool active,
        CancellationToken cancellationToken)
    {
        await repository.SetClassActiveAsync(id, active, cancellationToken);
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> CreateSession(CancellationToken cancellationToken)
    {
        var model = new SessionCreateViewModel();
        await PopulateSessionOptionsAsync(model, cancellationToken);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
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
        var session = (await repository.SessionsAsync(
                DateTime.Today.AddYears(-1),
                DateTime.Today.AddYears(2),
                cancellationToken))
            .FirstOrDefault(item => item.Id == id);
        if (session is null) return NotFound();

        return View(new SessionDetailsViewModel
        {
            Session = session,
            Bookings = await repository.BookingsAsync(id, cancellationToken)
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
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
    public async Task<IActionResult> Book(
        long sessionId,
        int memberId,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await repository.BookAsync(memberId, sessionId, cancellationToken);
            TempData["Success"] = $"Đã tạo lượt đặt #{result.id}: {result.status}.";
        }
        catch (SqlException exception)
        {
            TempData["Error"] = exception.Message;
        }
        return RedirectToAction(nameof(Session), new { id = sessionId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
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
    public async Task<IActionResult> CheckIn(
        int? memberId,
        CancellationToken cancellationToken) =>
        View(new CheckInViewModel
        {
            MemberId = memberId ?? 0,
            History = await repository.CheckInHistoryAsync(memberId, cancellationToken)
        });

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CheckIn(
        CheckInViewModel model,
        CancellationToken cancellationToken)
    {
        try
        {
            var id = await repository.CheckInAsync(
                model.MemberId,
                GetEmployeeId(),
                model.SessionId,
                model.Method,
                cancellationToken);
            TempData["Success"] = $"Check-in #{id} thành công.";
            return RedirectToAction(nameof(CheckIn), new { memberId = model.MemberId });
        }
        catch (SqlException exception)
        {
            LogCheckInFailure(logger, exception);
            ModelState.AddModelError(string.Empty, exception.Message);
            model.History = await repository.CheckInHistoryAsync(model.MemberId, cancellationToken);
            return View(model);
        }
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
