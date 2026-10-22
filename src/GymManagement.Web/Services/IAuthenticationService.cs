using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public interface IAuthenticationService
{
    Task<LoginResult> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken);

    Task<PasswordChangeResult> ChangePasswordAsync(
        int userId,
        string username,
        string currentPassword,
        string newPassword,
        CancellationToken cancellationToken);
}
