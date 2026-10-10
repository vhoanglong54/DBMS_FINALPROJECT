namespace GymManagement.Web.Services;

public interface IPasswordHasher
{
    bool Verify(string password, byte[] salt, byte[] expectedHash, int iterations);
}
