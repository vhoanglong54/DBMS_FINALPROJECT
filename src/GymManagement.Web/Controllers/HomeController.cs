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
        // Ép chuyển hướng thẳng sang phân hệ Quản lý Hội viên
        return RedirectToAction("Index", "Members");
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
}