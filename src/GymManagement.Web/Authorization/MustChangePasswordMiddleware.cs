namespace GymManagement.Web.Authorization;

public sealed class MustChangePasswordMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var mustChangePassword = string.Equals(
            context.User.FindFirst("must_change_password")?.Value,
            bool.TrueString,
            StringComparison.OrdinalIgnoreCase);

        if (context.User.Identity?.IsAuthenticated == true && mustChangePassword &&
            !context.Request.Path.StartsWithSegments("/account/change-password") &&
            !context.Request.Path.StartsWithSegments("/account/logout") &&
            !context.Request.Path.StartsWithSegments("/health"))
        {
            context.Response.Redirect("/account/change-password");
            return;
        }

        await next(context);
    }
}
