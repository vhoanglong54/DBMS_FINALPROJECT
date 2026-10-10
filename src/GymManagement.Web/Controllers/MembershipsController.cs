using System.Globalization;
using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = Policies.Billing)]
public sealed partial class MembershipsController(
    IMembershipRepository repository,
    ILogger<MembershipsController> logger) : Controller
{
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        try
        {
            return View(new MembershipIndexViewModel
            {
                Items = await repository.ListMembershipsAsync(cancellationToken)
            });
        }
        catch (SqlException exception)
        {
            LogLoadFailure(logger, exception);
            return View(new MembershipIndexViewModel
            {
                Notice = "Không thể tải dữ liệu đăng ký và hóa đơn."
            });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Create(
        int? memberId,
        CancellationToken cancellationToken)
    {
        var model = new MembershipCreateViewModel
        {
            MemberId = memberId ?? 0,
            StartDate = DateTime.Today
        };
        await PopulateOptionsAsync(model, cancellationToken);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
        MembershipCreateViewModel model,
        CancellationToken cancellationToken)
    {
        if (model.InitialPayment > 0 && string.IsNullOrWhiteSpace(model.PaymentMethod))
            ModelState.AddModelError(nameof(model.PaymentMethod), "Chọn phương thức thanh toán.");

        if (!ModelState.IsValid)
        {
            await PopulateOptionsAsync(model, cancellationToken);
            return View(model);
        }

        try
        {
            var result = await repository.CreateMembershipAsync(
                model,
                GetEmployeeId(),
                cancellationToken);
            TempData["Success"] = $"Đã tạo đăng ký #{result.membershipId} và hóa đơn #{result.invoiceId}.";
            return RedirectToAction(nameof(Index));
        }
        catch (SqlException exception)
        {
            LogCreateFailure(logger, exception);
            ModelState.AddModelError(string.Empty, exception.Message);
            await PopulateOptionsAsync(model, cancellationToken);
            return View(model);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Pay(long invoiceId, CancellationToken cancellationToken)
    {
        var item = (await repository.ListMembershipsAsync(cancellationToken))
            .FirstOrDefault(membership => membership.InvoiceId == invoiceId);
        if (item?.Total is null || item.Paid is null) return NotFound();

        var remaining = item.Total.Value - item.Paid.Value;
        if (remaining <= 0)
        {
            TempData["Error"] = "Hóa đơn đã thanh toán đủ.";
            return RedirectToAction(nameof(Index));
        }

        return View(new PaymentCreateViewModel
        {
            InvoiceId = invoiceId,
            InvoiceCode = item.InvoiceCode ?? invoiceId.ToString(CultureInfo.InvariantCulture),
            MemberName = item.MemberName,
            Remaining = remaining,
            Amount = remaining
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Pay(
        PaymentCreateViewModel model,
        CancellationToken cancellationToken)
    {
        if (model.Amount > model.Remaining)
            ModelState.AddModelError(nameof(model.Amount), "Số tiền vượt công nợ.");
        if (!ModelState.IsValid) return View(model);

        try
        {
            await repository.AddPaymentAsync(model, GetEmployeeId(), cancellationToken);
            TempData["Success"] = "Đã ghi nhận thanh toán.";
            return RedirectToAction(nameof(Index));
        }
        catch (SqlException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(model);
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Cancel(
        long id,
        string reason,
        CancellationToken cancellationToken)
    {
        try
        {
            await repository.CancelMembershipAsync(id, reason, cancellationToken);
            TempData["Success"] = "Đã hủy gói đăng ký.";
        }
        catch (SqlException exception)
        {
            TempData["Error"] = exception.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    private int GetEmployeeId() =>
        int.TryParse(User.FindFirst("employee_id")?.Value, out var id)
            ? id
            : throw new InvalidOperationException("Tài khoản chưa gắn nhân viên.");

    private async Task PopulateOptionsAsync(
        MembershipCreateViewModel model,
        CancellationToken cancellationToken)
    {
        model.Members = await repository.ListMembersAsync(cancellationToken);
        model.Plans = await repository.ListPlansAsync(false, cancellationToken);
    }

    [LoggerMessage(EventId = 3101, Level = LogLevel.Error, Message = "Cannot load memberships")]
    private static partial void LogLoadFailure(ILogger logger, Exception exception);

    [LoggerMessage(EventId = 3102, Level = LogLevel.Warning, Message = "Cannot create membership")]
    private static partial void LogCreateFailure(ILogger logger, Exception exception);
}
