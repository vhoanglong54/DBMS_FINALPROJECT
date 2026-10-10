using GymManagement.Web.Models;

namespace GymManagement.Web.Data;

public interface IMembershipRepository
{
    Task<IReadOnlyList<PlanListItem>> ListPlansAsync(bool includeInactive, CancellationToken cancellationToken);
    Task<int> SavePlanAsync(PlanEditViewModel model, CancellationToken cancellationToken);
    Task SetPlanActiveAsync(int id, bool active, CancellationToken cancellationToken);
    Task<IReadOnlyList<SelectOption>> ListMembersAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<MembershipListItem>> ListMembershipsAsync(CancellationToken cancellationToken);
    Task<(long membershipId, long invoiceId)> CreateMembershipAsync(MembershipCreateViewModel model, int employeeId, CancellationToken cancellationToken);
    Task AddPaymentAsync(PaymentCreateViewModel model, int employeeId, CancellationToken cancellationToken);
    Task CancelMembershipAsync(long id, string reason, CancellationToken cancellationToken);
}
