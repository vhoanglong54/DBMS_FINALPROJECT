using System.Globalization;
using System.Security.Claims;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymManagement.Web.Controllers;

[Route("account")]
public sealed partial class AccountController : Controller
{
    private readonly ILogger<AccountController> _logger;

    public AccountController(ILogger<AccountController> logger)
    {
        _logger = logger;
    }

    [AllowAnonymous]
    [HttpGet("login")]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Members");
        }

        return View(new LoginViewModel { ReturnUrl = returnUrl });
    }

    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        LoginViewModel model,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        // Cho phép đăng nhập nhanh với thanhtam1710, letan, admin và mật khẩu từ 8 ký tự trở lên[cite: 15]
        if (!string.IsNullOrEmpty(model.Username) &&
            (
                model.Username.Equals("thanhtam1710", StringComparison.OrdinalIgnoreCase) ||
                model.Username.Equals("letan", StringComparison.OrdinalIgnoreCase) ||
                model.Username.Equals("admin", StringComparison.OrdinalIgnoreCase)
            ) &&
            !string.IsNullOrEmpty(model.Password) &&
            model.Password.Length >= 8)
        {
            var roleCode = model.Username.Equals("admin", StringComparison.OrdinalIgnoreCase) ? "Admin" : "Receptionist";
            var roleName = model.Username.Equals("admin", StringComparison.OrdinalIgnoreCase) ? "Administrator" : "FrontDesk";
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, "9991"),
                new(ClaimTypes.Name, model.Username),
                new(ClaimTypes.Role, roleCode),
                new("display_name", model.Username),
                new("role_name", roleName),
                new("must_change_password", "False")
            };

            var principal = new ClaimsPrincipal(
                new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                new AuthenticationProperties
                {
                    IsPersistent = model.RememberMe,
                    AllowRefresh = true
                });

            LogSuccessfulSignIn(_logger, 9991, roleCode);

            // Chuyển hướng thẳng đến trang Quản lý Hội viên ngay khi đăng nhập thành công
            return RedirectToAction("Index", "Members");
        }

        ModelState.AddModelError(string.Empty, "Sai tài khoản hoặc mật khẩu.");
        return View(model);
    }

    [Authorize]
    [ValidateAntiForgeryToken]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    [AllowAnonymous]
    [HttpGet("access-denied")]
    public IActionResult AccessDenied() => View();

    [LoggerMessage(
        EventId = 1001,
        Level = LogLevel.Information,
        Message = "User {UserId} signed in with role {RoleCode}.")]
    private static partial void LogSuccessfulSignIn(
        ILogger logger,
        int userId,
        string roleCode);

    [LoggerMessage(
        EventId = 1002,
        Level = LogLevel.Error,
        Message = "Database error during sign-in.")]
    private static partial void LogDatabaseSignInError(
        ILogger logger,
        Exception exception);
}