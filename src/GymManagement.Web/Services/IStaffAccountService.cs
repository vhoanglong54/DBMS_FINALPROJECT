using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public interface IStaffAccountService
{
    Task<IReadOnlyList<StaffAccountRow>> ListAsync(int actorUserId, CancellationToken cancellationToken);
    Task<string> SuggestEmployeeCodeAsync(int actorUserId, CancellationToken cancellationToken);
    Task CreateAsync(int actorUserId, StaffAccountCreateViewModel model, CancellationToken cancellationToken);
}
