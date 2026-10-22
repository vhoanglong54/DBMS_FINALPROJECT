namespace GymManagement.Web.Services;

public interface IPasswordHasher
{
    bool Verify(string password, byte[] salt, byte[] expectedHash, int iterations);
    PasswordHashResult Hash(string password, int iterations);
}

public sealed record PasswordHashResult(byte[] Hash, byte[] Salt, int Iterations);
