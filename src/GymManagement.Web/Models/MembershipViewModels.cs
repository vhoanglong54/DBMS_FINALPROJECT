using System.ComponentModel.DataAnnotations;

namespace GymManagement.Web.Models;

public sealed record SelectOption(int Id, string Label);
public sealed record PlanListItem(int Id, string Code, string Name, string? Description, short DurationDays,
    decimal Price, byte MaxCheckInsPerDay, bool AllowsClasses, bool IsActive);
public sealed record MembershipListItem(long Id, int MemberId, string MemberCode, string MemberName,
    int PlanId, string PlanName, DateTime StartDate, DateTime EndDate, decimal Price, string Status,
    long? InvoiceId, string? InvoiceCode, decimal? Total, decimal? Paid, string? InvoiceStatus);

public sealed class PlanEditViewModel
{
    public int? Id { get; set; }
    [Required, StringLength(20), RegularExpression(@"^[A-Z0-9-]+$")]
    [Display(Name = "Mã gói")]
    public string Code { get; set; } = string.Empty;
    [Required, StringLength(120), Display(Name = "Tên gói")]
    public string Name { get; set; } = string.Empty;
    [StringLength(500), Display(Name = "Mô tả")]
    public string? Description { get; set; }
    [Range(1, 1095), Display(Name = "Số ngày")]
    public short DurationDays { get; set; } = 30;
    [Range(0, double.MaxValue), Display(Name = "Giá")]
    public decimal Price { get; set; }
    [Range(1, 10), Display(Name = "Lượt check-in/ngày")]
    public byte MaxCheckInsPerDay { get; set; } = 1;
    [Display(Name = "Bao gồm lớp nhóm")]
    public bool AllowsClasses { get; set; } = true;
}

public sealed class MembershipCreateViewModel
{
    [Range(1, int.MaxValue), Display(Name = "Hội viên")]
    public int MemberId { get; set; }
    [Range(1, int.MaxValue), Display(Name = "Gói tập")]
    public int PlanId { get; set; }
    [DataType(DataType.Date), Display(Name = "Ngày bắt đầu")]
    public DateTime StartDate { get; set; } = DateTime.Today;
    [Range(0, double.MaxValue), Display(Name = "Thanh toán ban đầu")]
    public decimal InitialPayment { get; set; }
    [Display(Name = "Phương thức")]
    public string? PaymentMethod { get; set; }
    [StringLength(100), Display(Name = "Mã tham chiếu")]
    public string? TransactionReference { get; set; }
    public IReadOnlyList<SelectOption> Members { get; set; } = [];
    public IReadOnlyList<PlanListItem> Plans { get; set; } = [];
}

public sealed class PaymentCreateViewModel
{
    public long InvoiceId { get; set; }
    public string InvoiceCode { get; set; } = string.Empty;
    public string MemberName { get; set; } = string.Empty;
    public decimal Remaining { get; set; }
    [Range(1, double.MaxValue), Display(Name = "Số tiền")]
    public decimal Amount { get; set; }
    [Required, Display(Name = "Phương thức")]
    public string PaymentMethod { get; set; } = "CASH";
    [StringLength(100), Display(Name = "Mã tham chiếu")]
    public string? TransactionReference { get; set; }
}

public sealed class MembershipIndexViewModel
{
    public IReadOnlyList<MembershipListItem> Items { get; init; } = [];
    public string? Notice { get; init; }
}
