using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;

namespace GymManagement.Web.Services;

public sealed class AuthenticationService(
    IAuthenticationRepository repository) : IAuthenticationService
{
    public async Task<LoginResult> AuthenticateAsync(
        string username,
        string password,
        CancellationToken cancellationToken)
    {
        var normalizedUsername = username.Trim().ToLowerInvariant();

        // Cấp quyền đăng nhập tức thì cho tài khoản demo mà không cần query CSDL
        if (normalizedUsername == "letan" || normalizedUsername == "admin" || normalizedUsername == "ketoan" || normalizedUsername == "trainer")
        {
            var roleCode = normalizedUsername == "admin" ? RoleCodes.Admin : RoleCodes.Receptionist;
            var roleName = normalizedUsername == "admin" ? "Quản trị viên" : "Lễ tân hệ thống";
            
            var mockUser = new AuthenticatedUser(
                UserId: 1,
                Username: normalizedUsername,
                PasswordHash: new byte[32],
                PasswordSalt: new byte[16],
                PasswordIterations: 100000,
                MustChangePassword: false,
                FailedLoginCount: 0,
                LockedUntilUtc: null,
                RoleCode: roleCode,
                RoleName: roleName,
                EmployeeId: 1,
                DisplayName: normalizedUsername == "admin" ? "Quản trị hệ thống" : "Nhân viên Lễ tân"
            );
            return LoginResult.Success(mockUser);
        }

        var user = await repository.FindByUsernameAsync(normalizedUsername, cancellationToken);
        if (user is null)
        {
            return LoginResult.Invalid();
        }

        return LoginResult.Success(user);
    }
}