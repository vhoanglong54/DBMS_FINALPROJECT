using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public interface IAuthenticationService
{
    Task<LoginResult> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken);
}
