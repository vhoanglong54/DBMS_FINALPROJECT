using GymManagement.Web.Models;

namespace GymManagement.Web.Data;

public interface IMemberRepository
{
    Task<IReadOnlyList<MemberListItem>> ListAsync(string? search, bool includeInactive, CancellationToken cancellationToken);
    Task<MemberDetailsViewModel?> GetAsync(int id, CancellationToken cancellationToken);
    Task<int> SaveAsync(MemberEditViewModel member, CancellationToken cancellationToken);
    Task SetActiveAsync(int id, bool isActive, CancellationToken cancellationToken);
}
