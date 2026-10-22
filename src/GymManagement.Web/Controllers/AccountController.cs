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
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        return View(new LoginViewModel { ReturnUrl = returnUrl });
    }

    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginViewModel model, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            var result = await authenticationService.AuthenticateAsync(model.Username, model.Password, cancellationToken);
            if (!result.Succeeded || result.User is null)
            {
                ModelState.AddModelError(string.Empty, result.IsLocked
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
                claims.Add(new Claim("employee_id", user.EmployeeId.Value.ToString(CultureInfo.InvariantCulture)));

            var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));
            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal,
                new AuthenticationProperties { IsPersistent = model.RememberMe, AllowRefresh = true });
            LogSuccessfulSignIn(logger, user.UserId, user.RoleCode);

            if (user.MustChangePassword)
                return RedirectToAction(nameof(ChangePassword));

            if (!string.IsNullOrWhiteSpace(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
                return LocalRedirect(model.ReturnUrl);
            return RedirectToAction("Index", "Home");
        }
        catch (SqlException exception)
        {
            LogDatabaseSignInError(logger, exception);
            ModelState.AddModelError(string.Empty, "Không thể kết nối cơ sở dữ liệu. Vui lòng liên hệ quản trị viên.");
            return View(model);
        }
    }

    [Authorize]
    [HttpGet("change-password")]
    public IActionResult ChangePassword() => View(new ChangePasswordViewModel());

    [Authorize]
    [ValidateAntiForgeryToken]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword(
        ChangePasswordViewModel model,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return View(model);

        if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ||
            string.IsNullOrWhiteSpace(User.Identity?.Name))
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction(nameof(Login));
        }

        try
        {
            var result = await authenticationService.ChangePasswordAsync(
                userId, User.Identity.Name, model.CurrentPassword, model.NewPassword,
                cancellationToken);

            switch (result)
            {
                case PasswordChangeResult.InvalidCurrentPassword:
                    ModelState.AddModelError(nameof(model.CurrentPassword), "Mật khẩu hiện tại không đúng.");
                    return View(model);
                case PasswordChangeResult.InvalidNewPassword:
                    ModelState.AddModelError(nameof(model.NewPassword), "Mật khẩu mới phải từ 8 đến 128 ký tự.");
                    return View(model);
                case PasswordChangeResult.SameAsCurrentPassword:
                    ModelState.AddModelError(nameof(model.NewPassword), "Mật khẩu mới phải khác mật khẩu hiện tại.");
                    return View(model);
                case PasswordChangeResult.Locked:
                case PasswordChangeResult.AccountUnavailable:
                    await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                    TempData["LoginNotice"] = result == PasswordChangeResult.Locked
                        ? "Tài khoản đang tạm khóa. Vui lòng đăng nhập lại sau khi hết thời gian khóa."
                        : "Phiên đăng nhập không còn hợp lệ. Vui lòng đăng nhập lại.";
                    return RedirectToAction(nameof(Login));
                case not PasswordChangeResult.Success:
                    ModelState.AddModelError(string.Empty, "Không thể đổi mật khẩu lúc này. Vui lòng thử lại sau.");
                    return View(model);
            }

            var ticket = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            var claims = User.Claims.Where(claim => claim.Type != "must_change_password").ToList();
            claims.Add(new Claim("must_change_password", bool.FalseString));
            var principal = new ClaimsPrincipal(
                new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));
            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                ticket.Properties ?? new AuthenticationProperties { AllowRefresh = true });

            LogSuccessfulPasswordChange(logger, userId);
            TempData["PasswordChanged"] = "Mật khẩu đã được đổi thành công.";
            return RedirectToAction("Index", "Home");
        }
        catch (SqlException exception)
        {
            LogDatabasePasswordChangeError(logger, exception);
            ModelState.AddModelError(string.Empty, "Không thể đổi mật khẩu lúc này. Vui lòng thử lại sau.");
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

    [LoggerMessage(EventId = 1001, Level = LogLevel.Information, Message = "User {UserId} signed in with role {RoleCode}.")]
    private static partial void LogSuccessfulSignIn(ILogger logger, int userId, string roleCode);

    [LoggerMessage(EventId = 1002, Level = LogLevel.Error, Message = "Database error during sign-in.")]
    private static partial void LogDatabaseSignInError(ILogger logger, Exception exception);

    [LoggerMessage(EventId = 1003, Level = LogLevel.Information, Message = "User {UserId} changed password.")]
    private static partial void LogSuccessfulPasswordChange(ILogger logger, int userId);

    [LoggerMessage(EventId = 1004, Level = LogLevel.Error, Message = "Database error during password change.")]
    private static partial void LogDatabasePasswordChangeError(ILogger logger, Exception exception);
}
