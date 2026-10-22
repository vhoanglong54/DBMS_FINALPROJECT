using System.Security.Claims;
using GymManagement.Web.Authorization;
using Microsoft.AspNetCore.Http;

namespace GymManagement.Tests;

public sealed class MustChangePasswordMiddlewareTests
{
    [Theory]
    [InlineData("/")]
    [InlineData("/reports?type=revenue")]
    [InlineData("/members/create")]
    public async Task TemporaryPasswordBlocksBusinessRoutes(string pathAndQuery)
    {
        var context = CreateContext(true, pathAndQuery);
        var nextCalled = false;
        var middleware = new MustChangePasswordMiddleware(_ =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        await middleware.InvokeAsync(context);

        Assert.False(nextCalled);
        Assert.Equal(StatusCodes.Status302Found, context.Response.StatusCode);
        Assert.Equal("/account/change-password", context.Response.Headers.Location.ToString());
    }

    [Theory]
    [InlineData("/account/change-password")]
    [InlineData("/account/logout")]
    [InlineData("/health")]
    public async Task TemporaryPasswordAllowsChangeLogoutAndHealth(string path)
    {
        var context = CreateContext(true, path);
        var nextCalled = false;
        var middleware = new MustChangePasswordMiddleware(_ =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        await middleware.InvokeAsync(context);

        Assert.True(nextCalled);
    }

    [Fact]
    public async Task NormalAccountCanReachBusinessRoute()
    {
        var context = CreateContext(false, "/members");
        var nextCalled = false;
        var middleware = new MustChangePasswordMiddleware(_ =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });

        await middleware.InvokeAsync(context);

        Assert.True(nextCalled);
    }

    private static DefaultHttpContext CreateContext(bool mustChangePassword, string pathAndQuery)
    {
        var context = new DefaultHttpContext();
        context.Request.Path = pathAndQuery.Split('?')[0];
        context.User = new ClaimsPrincipal(new ClaimsIdentity(
            [new Claim("must_change_password", mustChangePassword.ToString())],
            "TestCookie"));
        return context;
    }
}
