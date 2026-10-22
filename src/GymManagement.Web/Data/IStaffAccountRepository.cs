using GymManagement.Web.Models;

namespace GymManagement.Web.Data;

public interface IStaffAccountRepository
{
    Task<IReadOnlyList<StaffAccountRow>> ListAsync(int actorUserId, CancellationToken cancellationToken);
    Task<string> SuggestEmployeeCodeAsync(int actorUserId, CancellationToken cancellationToken);
    Task CreateAsync(StaffAccountCreateCommand account, CancellationToken cancellationToken);
}
