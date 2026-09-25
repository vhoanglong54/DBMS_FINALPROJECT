namespace GymManagement.Web.Models;

public sealed record LoginResult(bool Succeeded, bool IsLocked, AuthenticatedUser? User)
{
    public static LoginResult Invalid() => new(false, false, null);
    public static LoginResult Locked() => new(false, true, null);
    public static LoginResult Success(AuthenticatedUser user) => new(true, false, user);
}
