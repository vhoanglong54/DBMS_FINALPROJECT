using GymManagement.Web.Models;

namespace GymManagement.Web.Data;

public interface IAuthenticationRepository
{
    Task<AuthenticatedUser?> FindByUsernameAsync(string username, CancellationToken cancellationToken);
    Task RecordFailedLoginAsync(int userId, CancellationToken cancellationToken);
    Task RecordSuccessfulLoginAsync(int userId, CancellationToken cancellationToken);
}
