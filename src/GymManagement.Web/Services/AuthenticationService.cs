using GymManagement.Web.Data;
using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public sealed class AuthenticationService(
    IAuthenticationRepository repository,
    IPasswordHasher passwordHasher,
    TimeProvider timeProvider) : IAuthenticationService
{
    public async Task<LoginResult> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken)
    {
        var normalizedUsername = username.Trim().ToLowerInvariant();
        var user = await repository.FindByUsernameAsync(normalizedUsername, cancellationToken);

        if (user is null)
        {
            return LoginResult.Invalid();
        }

        var nowUtc = timeProvider.GetUtcNow().UtcDateTime;
        if (user.LockedUntilUtc is not null && user.LockedUntilUtc > nowUtc)
        {
            return LoginResult.Locked();
        }

        if (!passwordHasher.Verify(
                password,
                user.PasswordSalt,
                user.PasswordHash,
                user.PasswordIterations))
        {
            await repository.RecordFailedLoginAsync(user.UserId, cancellationToken);
            return LoginResult.Invalid();
        }

        await repository.RecordSuccessfulLoginAsync(user.UserId, cancellationToken);
        return LoginResult.Success(user);
    }
}
