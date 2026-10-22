namespace GymManagement.Web.Models;

public enum PasswordChangeResult
{
    Success,
    InvalidCurrentPassword,
    InvalidNewPassword,
    SameAsCurrentPassword,
    Locked,
    AccountUnavailable
}
