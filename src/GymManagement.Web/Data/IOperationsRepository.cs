using GymManagement.Web.Models;

namespace GymManagement.Web.Data;

public interface IOperationsRepository
{
    Task<IReadOnlyList<RoomRow>> RoomsAsync(bool includeInactive, CancellationToken cancellationToken);
    Task<RoomRow?> RoomAsync(int id, CancellationToken cancellationToken);
    Task<int> SaveRoomAsync(RoomEditViewModel model, CancellationToken cancellationToken);
    Task SetRoomActiveAsync(int id, bool active, CancellationToken cancellationToken);
    Task<IReadOnlyList<ClassTypeRow>> ClassesAsync(bool includeInactive, CancellationToken cancellationToken);
    Task<ClassTypeRow?> ClassAsync(int id, CancellationToken cancellationToken);
    Task<int> SaveClassAsync(ClassTypeEditViewModel model, CancellationToken cancellationToken);
    Task SetClassActiveAsync(int id, bool active, CancellationToken cancellationToken);
    Task<IReadOnlyList<TrainerOption>> TrainersAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<SessionRow>> SessionsAsync(DateTime from, DateTime through, CancellationToken cancellationToken);
    Task<SessionRow?> SessionAsync(long id, CancellationToken cancellationToken);
    Task<long> CreateSessionAsync(SessionCreateViewModel model, CancellationToken cancellationToken);
    Task CancelSessionAsync(long id, string reason, CancellationToken cancellationToken);
    Task<IReadOnlyList<BookingRow>> BookingsAsync(long sessionId, CancellationToken cancellationToken);
    Task<MemberLookupRow?> FindActiveMemberAsync(string memberCode, CancellationToken cancellationToken);
    Task<(long id, string status)> BookAsync(int memberId, long sessionId, CancellationToken cancellationToken);
    Task CancelBookingAsync(long id, string reason, CancellationToken cancellationToken);
    Task<long> CheckInAsync(int memberId, int employeeId, long? sessionId, string method, CancellationToken cancellationToken);
    Task<IReadOnlyList<CheckInRow>> CheckInHistoryAsync(int? memberId, CancellationToken cancellationToken);
}
