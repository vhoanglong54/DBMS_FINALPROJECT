using System.ComponentModel.DataAnnotations;
using GymManagement.Web.Models;

namespace GymManagement.Tests;

public sealed class LoginViewModelTests
{
    [Fact]
    public void ValidationReturnsErrorsForEmptyCredentials()
    {
        var model = new LoginViewModel();
        var results = new List<ValidationResult>();

        var isValid = Validator.TryValidateObject(
            model,
            new ValidationContext(model),
            results,
            validateAllProperties: true);

        Assert.False(isValid);
        Assert.Contains(results, result => result.MemberNames.Contains(nameof(LoginViewModel.Username)));
        Assert.Contains(results, result => result.MemberNames.Contains(nameof(LoginViewModel.Password)));
    }
}
