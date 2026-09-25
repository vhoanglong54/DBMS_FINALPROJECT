using System.Security.Cryptography;

namespace GymManagement.Web.Services;

public sealed class Pbkdf2PasswordHasher : IPasswordHasher
{
    public bool Verify(string password, byte[] salt, byte[] expectedHash, int iterations)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);
        ArgumentNullException.ThrowIfNull(salt);
        ArgumentNullException.ThrowIfNull(expectedHash);

        if (salt.Length < 16 || expectedHash.Length < 32)
        {
            return false;
        }

        if (iterations is < 100_000 or > 1_000_000)
        {
            return false;
        }

        var actualHash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            iterations,
            HashAlgorithmName.SHA256,
            expectedHash.Length);

        return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
    }
}
