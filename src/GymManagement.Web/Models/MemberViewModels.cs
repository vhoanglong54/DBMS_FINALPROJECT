using System.ComponentModel.DataAnnotations;

namespace GymManagement.Web.Models;

public sealed record MemberListItem(
    int Id, string Code, string FullName, string Phone, string? Email,
    DateTime DateOfBirth, string? Gender, bool IsActive);

public sealed record MemberMembershipRow(
    long MembershipId, string PlanName, DateTime StartDate, DateTime EndDate,
    decimal Price, string Status, string? CancellationReason);

public sealed class MemberEditViewModel
{
    public int? Id { get; set; }
    public string? Code { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập họ tên.")]
    [StringLength(120)]
    [Display(Name = "Họ và tên")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
    [RegularExpression(@"^[0-9+]{9,15}$", ErrorMessage = "Số điện thoại gồm 9–15 chữ số, có thể bắt đầu bằng +.")]
    [Display(Name = "Số điện thoại")]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    [StringLength(254)]
    public string? Email { get; set; }

    [Required]
    [DataType(DataType.Date)]
    [Display(Name = "Ngày sinh")]
    public DateTime DateOfBirth { get; set; } = new(2000, 1, 1);

    [Display(Name = "Giới tính")]
    public string? Gender { get; set; } = "OTHER";

    [StringLength(300)]
    [Display(Name = "Địa chỉ")]
    public string? Address { get; set; }

    [StringLength(150)]
    [Display(Name = "Liên hệ khẩn cấp")]
    public string? EmergencyContact { get; set; }

    [StringLength(1000)]
    [Display(Name = "Lưu ý sức khỏe")]
    public string? MedicalNote { get; set; }

    [Range(50, 250)]
    [Display(Name = "Chiều cao (cm)")]
    public int? HeightCm { get; set; }

    [Range(20, 300)]
    [Display(Name = "Cân nặng (kg)")]
    public int? WeightKg { get; set; }

    [StringLength(50)]
    [Display(Name = "Khung giờ tập ưu tiên")]
    public string? PreferredWorkoutTime { get; set; }
    public bool IsActive { get; set; } = true;
}

public sealed class MemberDetailsViewModel
{
    public required MemberEditViewModel Member { get; init; }
    public IReadOnlyList<MemberMembershipRow> Memberships { get; init; } = [];
}

public sealed class MemberIndexViewModel
{
    public string? Search { get; init; }
    public bool IncludeInactive { get; init; }
    public IReadOnlyList<MemberListItem> Members { get; init; } = [];
    public string? Notice { get; init; }
}
