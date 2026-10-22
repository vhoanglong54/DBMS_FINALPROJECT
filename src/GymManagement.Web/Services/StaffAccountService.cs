using GymManagement.Web.Data;
using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public sealed class StaffAccountService(IStaffAccountRepository repository, IPasswordHasher passwordHasher)
    : IStaffAccountService
{
    public Task<IReadOnlyList<StaffAccountRow>> ListAsync(int actorUserId, CancellationToken cancellationToken) =>
        repository.ListAsync(actorUserId, cancellationToken);

    public Task<string> SuggestEmployeeCodeAsync(int actorUserId, CancellationToken cancellationToken) =>
        repository.SuggestEmployeeCodeAsync(actorUserId, cancellationToken);

    public Task CreateAsync(int actorUserId, StaffAccountCreateViewModel model, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(model);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(actorUserId);
        if (model.HireDate is null || model.InitialPassword is null ||
            model.InitialPassword.Length is < 8 or > 128 ||
            model.InitialPassword != model.ConfirmPassword)
            throw new ArgumentException("Thông tin tài khoản không hợp lệ.", nameof(model));

        var password = passwordHasher.Hash(model.InitialPassword, Pbkdf2PasswordHasher.MinimumIterations);
        return repository.CreateAsync(new StaffAccountCreateCommand(
            actorUserId,
            model.EmployeeCode.Trim().ToUpperInvariant(),
            model.FullName.Trim(),
            model.Phone.Trim(),
            string.IsNullOrWhiteSpace(model.Email) ? null : model.Email.Trim(),
            model.HireDate.Value.Date,
            model.EmployeeType,
            model.Username.Trim().ToLowerInvariant(),
            password.Hash,
            password.Salt,
            password.Iterations), cancellationToken);
    }
}
