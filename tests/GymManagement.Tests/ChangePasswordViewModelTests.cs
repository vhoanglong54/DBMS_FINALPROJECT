using System.ComponentModel.DataAnnotations;
using GymManagement.Web.Models;

namespace GymManagement.Tests;

public sealed class ChangePasswordViewModelTests
{
    [Fact]
    public void RejectsMissingFieldsAndMismatchedConfirmation()
    {
        var empty = new ChangePasswordViewModel();
        Assert.False(IsValid(empty));

        var mismatched = new ChangePasswordViewModel
        {
            CurrentPassword = "Current@123",
            NewPassword = "NewSecret@123",
            ConfirmPassword = "Different@123"
        };
        Assert.False(IsValid(mismatched));
    }

    [Fact]
    public void AcceptsValidFields()
    {
        var model = new ChangePasswordViewModel
        {
            CurrentPassword = "Current@123",
            NewPassword = "NewSecret@123",
            ConfirmPassword = "NewSecret@123"
        };
        Assert.True(IsValid(model));
    }

    private static bool IsValid(ChangePasswordViewModel model) => Validator.TryValidateObject(
        model, new ValidationContext(model), [], validateAllProperties: true);
}
