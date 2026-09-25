using System.Diagnostics;
using System.Security.Claims;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManagement.Web.Controllers;

[Authorize]
public sealed class HomeController : Controller
{
    public IActionResult Index()
    {
        var employeeId = int.TryParse(User.FindFirstValue("employee_id"), out var parsedEmployeeId)
            ? parsedEmployeeId
            : null as int?;

        var model = new DashboardViewModel(
            User.FindFirstValue("display_name") ?? User.Identity?.Name ?? "Người dùng",
            User.Identity?.Name ?? string.Empty,
            User.FindFirstValue(ClaimTypes.Role) ?? string.Empty,
            User.FindFirstValue("role_name") ?? string.Empty,
            employeeId,
            bool.TryParse(User.FindFirstValue("must_change_password"), out var mustChange)
                && mustChange);

        return View(model);
    }

    [AllowAnonymous]
    public IActionResult Error() => View(new ErrorViewModel
    {
        RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier
    });

    [AllowAnonymous]
    public IActionResult HttpStatus(int code)
    {
        Response.StatusCode = code;
        return View(model: code);
    }
}
