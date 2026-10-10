using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Authorize(Policy = Policies.AdminOnly)]
public sealed class PlansController(IMembershipRepository repository) : Controller
{
    public async Task<IActionResult> Index(CancellationToken cancellationToken) =>
        View(await repository.ListPlansAsync(true, cancellationToken));

    [HttpGet]
    public IActionResult Create() => View("Edit", new PlanEditViewModel());

    [HttpGet]
    public async Task<IActionResult> Edit(int id, CancellationToken cancellationToken)
    {
        var plan = (await repository.ListPlansAsync(true, cancellationToken))
            .FirstOrDefault(item => item.Id == id);
        if (plan is null) return NotFound();

        return View(new PlanEditViewModel
        {
            Id = plan.Id,
            Code = plan.Code,
            Name = plan.Name,
            Description = plan.Description,
            DurationDays = plan.DurationDays,
            Price = plan.Price,
            MaxCheckInsPerDay = plan.MaxCheckInsPerDay,
            AllowsClasses = plan.AllowsClasses
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public Task<IActionResult> Create(
        PlanEditViewModel model,
        CancellationToken cancellationToken) => Save(model, cancellationToken);

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(
        int id,
        PlanEditViewModel model,
        CancellationToken cancellationToken)
    {
        if (model.Id != id) return BadRequest();
        return await Save(model, cancellationToken);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetActive(
        int id,
        bool active,
        CancellationToken cancellationToken)
    {
        await repository.SetPlanActiveAsync(id, active, cancellationToken);
        TempData["Success"] = "Đã cập nhật trạng thái gói tập.";
        return RedirectToAction(nameof(Index));
    }

    private async Task<IActionResult> Save(
        PlanEditViewModel model,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return View("Edit", model);

        try
        {
            await repository.SavePlanAsync(model, cancellationToken);
            TempData["Success"] = "Đã lưu gói tập.";
            return RedirectToAction(nameof(Index));
        }
        catch (SqlException exception)
        {
            ModelState.AddModelError(
                string.Empty,
                exception.Number is 2601 or 2627 ? "Mã gói đã tồn tại." : exception.Message);
            return View("Edit", model);
        }
    }
}
