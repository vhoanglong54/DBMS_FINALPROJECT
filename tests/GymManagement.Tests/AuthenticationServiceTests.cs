using GymManagement.Web.Data;
using GymManagement.Web.Models;
using GymManagement.Web.Services;

namespace GymManagement.Tests;

public sealed class AuthenticationServiceTests
{
    [Fact]
    public async Task AuthenticateAsyncRecordsSuccessForValidCredentials()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(
            repository,
            new Pbkdf2PasswordHasher(),
            TimeProvider.System);

        var result = await service.AuthenticateAsync(" ADMIN ", "Admin@123", default);

        Assert.True(result.Succeeded);
        Assert.Equal(1, repository.SuccessCount);
        Assert.Equal(0, repository.FailureCount);
    }

    [Fact]
    public async Task AuthenticateAsyncRecordsFailureForWrongPassword()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(
            repository,
            new Pbkdf2PasswordHasher(),
            TimeProvider.System);

        var result = await service.AuthenticateAsync("admin", "WrongPassword", default);

        Assert.False(result.Succeeded);
        Assert.False(result.IsLocked);
        Assert.Equal(0, repository.SuccessCount);
        Assert.Equal(1, repository.FailureCount);
    }

    [Fact]
    public async Task AuthenticateAsyncDoesNotUpdateLockedUser()
    {
        var lockedUser = CreateUser() with { LockedUntilUtc = DateTime.UtcNow.AddMinutes(10) };
        var repository = new FakeAuthenticationRepository(lockedUser);
        var service = new AuthenticationService(
            repository,
            new Pbkdf2PasswordHasher(),
            TimeProvider.System);

        var result = await service.AuthenticateAsync("admin", "Admin@123", default);

        Assert.True(result.IsLocked);
        Assert.Equal(0, repository.SuccessCount);
        Assert.Equal(0, repository.FailureCount);
    }

    private static AuthenticatedUser CreateUser() => new(
        1,
        "admin",
        Convert.FromHexString("E0FC83C65A2988A6F52D0D1BAD26DFCBB24A5CA4C1DE0B197A893DC1C38615B4"),
        Convert.FromHexString("D8B3991DFEE1B083627855E67FB83D0E"),
        100_000,
        false,
        0,
        null,
        "ADMIN",
        "Quản trị viên",
        1,
        "Nguyễn Quản Trị");

    private sealed class FakeAuthenticationRepository(AuthenticatedUser? user)
        : IAuthenticationRepository
    {
        public int FailureCount { get; private set; }
        public int SuccessCount { get; private set; }

        public Task<AuthenticatedUser?> FindByUsernameAsync(
            string username,
            CancellationToken cancellationToken) => Task.FromResult(user);

        public Task RecordFailedLoginAsync(int userId, CancellationToken cancellationToken)
        {
            FailureCount++;
            return Task.CompletedTask;
        }

        public Task RecordSuccessfulLoginAsync(int userId, CancellationToken cancellationToken)
        {
            SuccessCount++;
            return Task.CompletedTask;
        }
    }
}
