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

    [Fact]
    public async Task ChangePasswordAsyncStoresNewHashAndClearsTemporaryPasswordFlag()
    {
        var repository = new FakeAuthenticationRepository(CreateUser() with { MustChangePassword = true });
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Admin@123", "Another@123", default);

        Assert.Equal(PasswordChangeResult.Success, result);
        Assert.Equal(1, repository.PasswordChangeCount);
        Assert.False(repository.User!.MustChangePassword);
        Assert.True(new Pbkdf2PasswordHasher().Verify(
            "Another@123", repository.User.PasswordSalt, repository.User.PasswordHash,
            repository.User.PasswordIterations));
        Assert.False(new Pbkdf2PasswordHasher().Verify(
            "Admin@123", repository.User.PasswordSalt, repository.User.PasswordHash,
            repository.User.PasswordIterations));
    }

    [Fact]
    public async Task ChangePasswordAsyncCountsWrongCurrentPasswordWithoutUpdatingHash()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Wrong@123", "Another@123", default);

        Assert.Equal(PasswordChangeResult.InvalidCurrentPassword, result);
        Assert.Equal(1, repository.FailureCount);
        Assert.Equal(0, repository.PasswordChangeCount);
    }

    [Fact]
    public async Task ChangePasswordAsyncRejectsReuseOfCurrentPassword()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Admin@123", "Admin@123", default);

        Assert.Equal(PasswordChangeResult.SameAsCurrentPassword, result);
        Assert.Equal(0, repository.PasswordChangeCount);
    }

    [Fact]
    public async Task ChangePasswordAsyncDoesNotAcceptAnotherUsersId()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(2, "admin", "Admin@123", "Another@123", default);

        Assert.Equal(PasswordChangeResult.AccountUnavailable, result);
        Assert.Equal(0, repository.PasswordChangeCount);
    }

    [Fact]
    public async Task ChangePasswordAsyncRefusesLockedAccount()
    {
        var repository = new FakeAuthenticationRepository(
            CreateUser() with { LockedUntilUtc = DateTime.UtcNow.AddMinutes(10) });
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Admin@123", "Another@123", default);

        Assert.Equal(PasswordChangeResult.Locked, result);
        Assert.Equal(0, repository.PasswordChangeCount);
    }

    [Fact]
    public async Task ChangePasswordAsyncLocksAccountOnFifthWrongCurrentPassword()
    {
        var repository = new FakeAuthenticationRepository(
            CreateUser() with { FailedLoginCount = 4 });
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Wrong@123", "Another@123", default);

        Assert.Equal(PasswordChangeResult.Locked, result);
        Assert.Equal(1, repository.FailureCount);
        Assert.Equal(0, repository.PasswordChangeCount);
    }

    [Fact]
    public async Task ChangePasswordAsyncRejectsShortNewPassword()
    {
        var repository = new FakeAuthenticationRepository(CreateUser());
        var service = new AuthenticationService(repository, new Pbkdf2PasswordHasher(), TimeProvider.System);

        var result = await service.ChangePasswordAsync(1, "admin", "Admin@123", "short", default);

        Assert.Equal(PasswordChangeResult.InvalidNewPassword, result);
        Assert.Equal(0, repository.PasswordChangeCount);
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
        public AuthenticatedUser? User { get; private set; } = user;
        public int FailureCount { get; private set; }
        public int SuccessCount { get; private set; }
        public int PasswordChangeCount { get; private set; }

        public Task<AuthenticatedUser?> FindByUsernameAsync(
            string username,
            CancellationToken cancellationToken) => Task.FromResult(User);

        public Task RecordFailedLoginAsync(int userId, CancellationToken cancellationToken)
        {
            FailureCount++;
            if (User is not null)
            {
                var failedLoginCount = (byte)(User.FailedLoginCount + 1);
                User = User with
                {
                    FailedLoginCount = failedLoginCount,
                    LockedUntilUtc = failedLoginCount >= 5 ? DateTime.UtcNow.AddMinutes(15) : User.LockedUntilUtc
                };
            }
            return Task.CompletedTask;
        }

        public Task RecordSuccessfulLoginAsync(int userId, CancellationToken cancellationToken)
        {
            SuccessCount++;
            return Task.CompletedTask;
        }

        public Task ChangePasswordAsync(int userId, byte[] passwordHash, byte[] passwordSalt,
            int passwordIterations, CancellationToken cancellationToken)
        {
            PasswordChangeCount++;
            User = User! with
            {
                PasswordHash = passwordHash,
                PasswordSalt = passwordSalt,
                PasswordIterations = passwordIterations,
                MustChangePassword = false
            };
            return Task.CompletedTask;
        }
    }
}
