using System.ComponentModel.DataAnnotations;
using GymManagement.Web.Models;

namespace GymManagement.Tests;

public sealed class BusinessModelValidationTests
{
    [Fact]
    public void MemberRejectsInvalidPhone()
    {
        var model = new MemberEditViewModel { FullName = "Nguyễn Văn A", Phone = "abc", DateOfBirth = new(2000, 1, 1) };
        Assert.Contains(Validate(model), x => x.MemberNames.Contains(nameof(model.Phone)));
    }

    [Fact]
    public void MemberAcceptsCompleteProfile()
    {
        var model = new MemberEditViewModel { FullName = "Nguyễn Văn A", Phone = "0901234567", Email = "a@example.test", DateOfBirth = new(2000, 1, 1), HeightCm = 170, WeightKg = 65 };
        Assert.Empty(Validate(model));
    }

    [Theory]
    [InlineData("basic 30")]
    [InlineData("BASIC_30")]
    public void PlanRejectsNonCanonicalCode(string code)
    {
        var model = new PlanEditViewModel { Code = code, Name = "Gói cơ bản", DurationDays = 30, Price = 100000 };
        Assert.Contains(Validate(model), x => x.MemberNames.Contains(nameof(model.Code)));
    }

    [Fact]
    public void MembershipRejectsMissingReferences()
    {
        var model = new MembershipCreateViewModel { MemberId = 0, PlanId = 0, InitialPayment = 0 };
        var results = Validate(model);
        Assert.Contains(results, x => x.MemberNames.Contains(nameof(model.MemberId)));
        Assert.Contains(results, x => x.MemberNames.Contains(nameof(model.PlanId)));
    }

    [Fact]
    public void PaymentRejectsZeroAmount()
    {
        var model = new PaymentCreateViewModel { Amount = 0, PaymentMethod = "CASH" };
        Assert.Contains(Validate(model), x => x.MemberNames.Contains(nameof(model.Amount)));
    }

    [Fact]
    public void RoomRejectsCapacityOutsideBusinessLimit()
    {
        var model = new RoomEditViewModel { Code = "ROOM-A", Name = "Phòng A", Capacity = 0 };
        Assert.Contains(Validate(model), x => x.MemberNames.Contains(nameof(model.Capacity)));
    }

    [Fact]
    public void ClassTypeRejectsTooShortDuration()
    {
        var model = new ClassTypeEditViewModel { Code = "YOGA", Name = "Yoga", Duration = 5, Difficulty = "BEGINNER" };
        Assert.Contains(Validate(model), x => x.MemberNames.Contains(nameof(model.Duration)));
    }

    private static List<ValidationResult> Validate(object model)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(model, new ValidationContext(model), results, true);
        return results;
    }
}
