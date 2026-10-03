using System.ComponentModel.DataAnnotations;

namespace GymManagement.Web.Models;

public class MemberViewModel
{
    [Required(ErrorMessage = "Vui lòng nhập họ và tên.")]
    [StringLength(120, ErrorMessage = "Họ tên không được vượt quá 120 ký tự.")]
    [Display(Name = "Họ và tên")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
    [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
    [StringLength(15, ErrorMessage = "Số điện thoại tối đa 15 ký tự.")]
    [Display(Name = "Số điện thoại")]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    [StringLength(254)]
    [Display(Name = "Địa chỉ Email")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn ngày sinh.")]
    [DataType(DataType.Date)]
    [Display(Name = "Ngày sinh")]
    public DateTime DateOfBirth { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn giới tính.")]
    [Display(Name = "Giới tính")]
    public string Gender { get; set; } = "MALE";
}