using GymManagement.Web.Services;

namespace GymManagement.Tests;

public sealed class Pbkdf2PasswordHasherTests
{
    private readonly Pbkdf2PasswordHasher _hasher = new();

    [Fact]
    public void VerifyReturnsTrueForSeededAdminPassword()
    {
        var salt = Convert.FromHexString("D8B3991DFEE1B083627855E67FB83D0E");
        var hash = Convert.FromHexString(
            "E0FC83C65A2988A6F52D0D1BAD26DFCBB24A5CA4C1DE0B197A893DC1C38615B4");

        var result = _hasher.Verify("Admin@123", salt, hash, 100_000);

        Assert.True(result);
    }

    [Fact]
    public void VerifyReturnsFalseForWrongPassword()
    {
        var salt = Convert.FromHexString("D8B3991DFEE1B083627855E67FB83D0E");
        var hash = Convert.FromHexString(
            "E0FC83C65A2988A6F52D0D1BAD26DFCBB24A5CA4C1DE0B197A893DC1C38615B4");

        var result = _hasher.Verify("WrongPassword", salt, hash, 100_000);

        Assert.False(result);
    }

    [Theory]
    [InlineData(99_999)]
    [InlineData(1_000_001)]
    public void VerifyReturnsFalseForUnsafeIterationCount(int iterations)
    {
        var salt = new byte[16];
        var hash = new byte[32];

        Assert.False(_hasher.Verify("Password@123", salt, hash, iterations));
    }
}
