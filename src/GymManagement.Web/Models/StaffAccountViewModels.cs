using System.ComponentModel.DataAnnotations;

namespace GymManagement.Web.Models;

public sealed record StaffAccountRow(
    string EmployeeCode,
    string FullName,
    string EmployeeType,
    string Username,
    bool IsActive);

public sealed class StaffAccountCreateViewModel
{
    [Required(ErrorMessage = "Vui lòng nhập mã nhân viên.")]
    [StringLength(20, MinimumLength = 2)]
    [RegularExpression(@"^[A-Za-z0-9-]+$", ErrorMessage = "Mã nhân viên chỉ gồm chữ, số và dấu gạch ngang.")]
    [Display(Name = "Mã nhân viên")]
    public string EmployeeCode { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập họ tên.")]
    [StringLength(120)]
    [Display(Name = "Họ và tên")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
    [RegularExpression(@"^[0-9+]{9,15}$", ErrorMessage = "Số điện thoại gồm 9–15 ký tự số hoặc dấu +.")]
    [Display(Name = "Số điện thoại")]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    [StringLength(254)]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn ngày vào làm.")]
    [DataType(DataType.Date)]
    [Display(Name = "Ngày vào làm")]
    public DateTime? HireDate { get; set; } = DateTime.Today;

    [Required(ErrorMessage = "Vui lòng chọn vị trí.")]
    [RegularExpression("^(MANAGER|RECEPTIONIST|TRAINER|ACCOUNTANT)$", ErrorMessage = "Vị trí không hợp lệ.")]
    [Display(Name = "Vị trí")]
    public string EmployeeType { get; set; } = "RECEPTIONIST";

    [Required(ErrorMessage = "Vui lòng nhập tên đăng nhập.")]
    [StringLength(50, MinimumLength = 4)]
    [RegularExpression(@"^[A-Za-z0-9._-]+$", ErrorMessage = "Tên đăng nhập chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.")]
    [Display(Name = "Tên đăng nhập")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập mật khẩu ban đầu.")]
    [StringLength(128, MinimumLength = 8, ErrorMessage = "Mật khẩu phải từ 8 đến 128 ký tự.")]
    [DataType(DataType.Password)]
    [Display(Name = "Mật khẩu ban đầu")]
    public string InitialPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng xác nhận mật khẩu.")]
    [DataType(DataType.Password)]
    [Compare(nameof(InitialPassword), ErrorMessage = "Mật khẩu xác nhận không khớp.")]
    [Display(Name = "Nhập lại mật khẩu")]
    public string ConfirmPassword { get; set; } = string.Empty;
}

public sealed record StaffAccountCreateCommand(
    int ActorUserId,
    string EmployeeCode,
    string FullName,
    string Phone,
    string? Email,
    DateTime HireDate,
    string EmployeeType,
    string Username,
    byte[] PasswordHash,
    byte[] PasswordSalt,
    int PasswordIterations);
