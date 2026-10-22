using System.ComponentModel.DataAnnotations;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using GymManagement.Web.Services;

namespace GymManagement.Tests;

public sealed class StaffAccountServiceTests
{
    [Fact]
    public async Task SuggestEmployeeCodeAsyncReturnsRepositorySuggestion()
    {
        var repository = new FakeStaffAccountRepository();
        var service = new StaffAccountService(repository, new Pbkdf2PasswordHasher());

        var code = await service.SuggestEmployeeCodeAsync(1, default);

        Assert.Equal("NV-0005", code);
        Assert.Equal(1, repository.SuggestActorUserId);
    }

    [Fact]
    public async Task CreateAsyncNormalizesFieldsAndStoresOnlyPasswordHash()
    {
        var repository = new FakeStaffAccountRepository();
        var service = new StaffAccountService(repository, new Pbkdf2PasswordHasher());
        var model = ValidModel();
        model.EmployeeCode = "nv-moi-01";
        model.Username = " New.Staff ";

        await service.CreateAsync(1, model, default);

        var saved = Assert.IsType<StaffAccountCreateCommand>(repository.Created);
        Assert.Equal(1, saved.ActorUserId);
        Assert.Equal("NV-MOI-01", saved.EmployeeCode);
        Assert.Equal("new.staff", saved.Username);
        Assert.Equal("RECEPTIONIST", saved.EmployeeType);
        Assert.Equal(Pbkdf2PasswordHasher.MinimumIterations, saved.PasswordIterations);
        Assert.Equal(16, saved.PasswordSalt.Length);
        Assert.True(new Pbkdf2PasswordHasher().Verify(
            model.InitialPassword, saved.PasswordSalt, saved.PasswordHash, saved.PasswordIterations));
    }

    [Fact]
    public async Task CreateAsyncRejectsMismatchedPasswordsBeforeRepositoryCall()
    {
        var repository = new FakeStaffAccountRepository();
        var service = new StaffAccountService(repository, new Pbkdf2PasswordHasher());
        var model = ValidModel();
        model.ConfirmPassword = "SomethingElse";

        await Assert.ThrowsAsync<ArgumentException>(() => service.CreateAsync(1, model, default));

        Assert.Null(repository.Created);
    }

    [Fact]
    public void CreateModelRejectsInvalidFields()
    {
        var model = ValidModel();
        model.EmployeeCode = "NV 01";
        model.Username = "a";
        model.ConfirmPassword = "WrongPassword";

        var errors = new List<ValidationResult>();
        var valid = Validator.TryValidateObject(model, new ValidationContext(model), errors, true);

        Assert.False(valid);
        Assert.True(errors.Count >= 3);
    }

    private static StaffAccountCreateViewModel ValidModel() => new()
    {
        EmployeeCode = "NV-MOI-01",
        FullName = "Nguyễn Nhân Viên",
        Phone = "0900000012",
        Email = "staff@example.test",
        HireDate = new DateTime(2026, 10, 22),
        EmployeeType = "RECEPTIONIST",
        Username = "new.staff",
        InitialPassword = "NewStaff@123",
        ConfirmPassword = "NewStaff@123"
    };

    private sealed class FakeStaffAccountRepository : IStaffAccountRepository
    {
        public StaffAccountCreateCommand? Created { get; private set; }
        public int? SuggestActorUserId { get; private set; }

        public Task<string> SuggestEmployeeCodeAsync(int actorUserId, CancellationToken cancellationToken)
        {
            SuggestActorUserId = actorUserId;
            return Task.FromResult("NV-0005");
        }

        public Task<IReadOnlyList<StaffAccountRow>> ListAsync(
            int actorUserId, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<StaffAccountRow>>([]);

        public Task CreateAsync(StaffAccountCreateCommand account, CancellationToken cancellationToken)
        {
            Created = account;
            return Task.CompletedTask;
        }
    }
}
