using System.ComponentModel.DataAnnotations;
using GymManagement.Web.Models;
using GymManagement.Web.Presentation;

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

    [Theory]
    [InlineData("")]
    [InlineData("1")]
    [InlineData("MEMBER-001")]
    public void CheckInRejectsMissingOrInternalMemberIdentifier(string memberCode)
    {
        var model = new CheckInViewModel { MemberCode = memberCode };
        Assert.Contains(Validate(model), result => result.MemberNames.Contains(nameof(model.MemberCode)));
    }

    [Theory]
    [InlineData("HV0001")]
    [InlineData("hv1234")]
    public void CheckInAcceptsPublicMemberCode(string memberCode)
    {
        var model = new CheckInViewModel { MemberCode = memberCode };
        Assert.Empty(Validate(model));
    }

    [Theory]
    [InlineData("ACTIVE", "Đang hoạt động", "status-active")]
    [InlineData("WAITLISTED", "Hàng chờ", "status-pending")]
    [InlineData("CANCELLED", "Đã hủy", "status-inactive")]
    public void CanonicalStatusesHaveFriendlyAndSafePresentation(
        string status,
        string expectedLabel,
        string expectedCss)
    {
        Assert.Equal(expectedLabel, DisplayLabels.Status(status));
        Assert.Equal(expectedCss, DisplayLabels.StatusCss(status));
    }

    private static List<ValidationResult> Validate(object model)
    {
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(model, new ValidationContext(model), results, true);
        return results;
    }
}
