namespace GymManagement.Web.Models;

public sealed record AuthenticatedUser(
    int UserId,
    string Username,
    byte[] PasswordHash,
    byte[] PasswordSalt,
    int PasswordIterations,
    bool MustChangePassword,
    byte FailedLoginCount,
    DateTime? LockedUntilUtc,
    string RoleCode,
    string RoleName,
    int? EmployeeId,
    string DisplayName);
