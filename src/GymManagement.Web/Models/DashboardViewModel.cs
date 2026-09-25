namespace GymManagement.Web.Models;

public sealed record DashboardViewModel(
    string DisplayName,
    string Username,
    string RoleCode,
    string RoleName,
    int? EmployeeId,
    bool MustChangePassword);
