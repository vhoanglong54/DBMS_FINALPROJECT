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
        if (user is null) return LoginResult.Invalid();

        var nowUtc = timeProvider.GetUtcNow().UtcDateTime;
        if (user.LockedUntilUtc is not null && user.LockedUntilUtc > nowUtc)
            return LoginResult.Locked();

        if (!passwordHasher.Verify(password, user.PasswordSalt, user.PasswordHash, user.PasswordIterations))
        {
            await repository.RecordFailedLoginAsync(user.UserId, cancellationToken);
            return LoginResult.Invalid();
        }

        await repository.RecordSuccessfulLoginAsync(user.UserId, cancellationToken);
        return LoginResult.Success(user);
    }

    public async Task<PasswordChangeResult> ChangePasswordAsync(
        int userId,
        string username,
        string currentPassword,
        string newPassword,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length is < 8 or > 128)
            return PasswordChangeResult.InvalidNewPassword;

        var user = await repository.FindByUsernameAsync(username, cancellationToken);
        if (user is null || user.UserId != userId)
            return PasswordChangeResult.AccountUnavailable;

        if (user.LockedUntilUtc is not null &&
            user.LockedUntilUtc > timeProvider.GetUtcNow().UtcDateTime)
            return PasswordChangeResult.Locked;

        if (string.IsNullOrEmpty(currentPassword) ||
            !passwordHasher.Verify(currentPassword, user.PasswordSalt, user.PasswordHash, user.PasswordIterations))
        {
            await repository.RecordFailedLoginAsync(user.UserId, cancellationToken);
            var updatedUser = await repository.FindByUsernameAsync(username, cancellationToken);
            return updatedUser?.LockedUntilUtc > timeProvider.GetUtcNow().UtcDateTime
                ? PasswordChangeResult.Locked
                : PasswordChangeResult.InvalidCurrentPassword;
        }

        if (passwordHasher.Verify(newPassword, user.PasswordSalt, user.PasswordHash, user.PasswordIterations))
            return PasswordChangeResult.SameAsCurrentPassword;

        var newHash = passwordHasher.Hash(
            newPassword,
            Math.Max(user.PasswordIterations, Pbkdf2PasswordHasher.MinimumIterations));
        await repository.ChangePasswordAsync(
            user.UserId, newHash.Hash, newHash.Salt, newHash.Iterations, cancellationToken);
        return PasswordChangeResult.Success;
    }
}
