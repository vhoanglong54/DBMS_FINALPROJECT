using System.Globalization;
using System.Security.Claims;
using GymManagement.Web.Models;
using GymManagement.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Controllers;

[Route("account")]
public sealed partial class AccountController(
    GymManagement.Web.Services.IAuthenticationService authenticationService,
    ILogger<AccountController> logger) : Controller
{
    [AllowAnonymous]
    [HttpGet("login")]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Home");
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

        try
        {
            var result = await authenticationService.AuthenticateAsync(
                model.Username,
                model.Password,
                cancellationToken);

            if (!result.Succeeded || result.User is null)
            {
                ModelState.AddModelError(
                    string.Empty,
                    result.IsLocked
                        ? "Tài khoản đang tạm khóa do đăng nhập sai nhiều lần. Vui lòng thử lại sau."
                        : "Tên đăng nhập hoặc mật khẩu không đúng.");
                return View(model);
            }

            var user = result.User;
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.UserId.ToString(CultureInfo.InvariantCulture)),
                new(ClaimTypes.Name, user.Username),
                new(ClaimTypes.Role, user.RoleCode),
                new("display_name", user.DisplayName),
                new("role_name", user.RoleName),
                new("must_change_password", user.MustChangePassword.ToString())
            };

            if (user.EmployeeId is not null)
            {
                claims.Add(new Claim(
                    "employee_id",
                    user.EmployeeId.Value.ToString(CultureInfo.InvariantCulture)));
            }

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

            LogSuccessfulSignIn(logger, user.UserId, user.RoleCode);

            if (!string.IsNullOrWhiteSpace(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            {
                return LocalRedirect(model.ReturnUrl);
            }

            return RedirectToAction("Index", "Home");
        }
        catch (SqlException exception)
        {
            LogDatabaseSignInError(logger, exception);
            ModelState.AddModelError(
                string.Empty,
                "Không thể kết nối cơ sở dữ liệu. Vui lòng liên hệ quản trị viên.");
            return View(model);
        }
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
