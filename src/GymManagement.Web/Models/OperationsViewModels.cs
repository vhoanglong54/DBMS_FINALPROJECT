using System.ComponentModel.DataAnnotations;

namespace GymManagement.Web.Models;

public sealed record RoomRow(int Id, string Code, string Name, short Capacity, string? Location, bool IsActive);
public sealed record ClassTypeRow(int Id, string Code, string Name, string? Description, short Duration, string Difficulty, bool IsActive);
public sealed record TrainerOption(int Id, string Name);
public sealed record SessionRow(long Id, int ClassId, string ClassName, int RoomId, string RoomName, int TrainerId, string TrainerName,
    DateTime StartAt, DateTime EndAt, short Capacity, int Booked, int SeatsLeft, string Status);
public sealed record BookingRow(long Id, int MemberId, string MemberCode, string MemberName, string Status, DateTime BookedAt, DateTime? CancelledAt, string? Reason);
public sealed record CheckInRow(long Id, int MemberId, string MemberCode, string MemberName, string EmployeeName, string? ClassName, long? SessionId, DateTime? SessionStart, DateTime CheckedAt, string Method);

public sealed class RoomEditViewModel
{
    public int? Id { get; set; }
    [Required, StringLength(20), Display(Name = "Mã phòng")] public string Code { get; set; } = string.Empty;
    [Required, StringLength(100), Display(Name = "Tên phòng")] public string Name { get; set; } = string.Empty;
    [Range(1, 500), Display(Name = "Sức chứa")] public short Capacity { get; set; } = 20;
    [StringLength(200), Display(Name = "Vị trí")] public string? Location { get; set; }
}

public sealed class ClassTypeEditViewModel
{
    public int? Id { get; set; }
    [Required, StringLength(20), Display(Name = "Mã loại lớp")] public string Code { get; set; } = string.Empty;
    [Required, StringLength(120), Display(Name = "Tên lớp")] public string Name { get; set; } = string.Empty;
    [StringLength(500), Display(Name = "Mô tả")] public string? Description { get; set; }
    [Range(15, 240), Display(Name = "Thời lượng mặc định (phút)")] public short Duration { get; set; } = 60;
    [Required, Display(Name = "Độ khó")] public string Difficulty { get; set; } = "ALL_LEVELS";
}

public sealed class SessionCreateViewModel
{
    [Range(1, int.MaxValue), Display(Name = "Loại lớp")] public int ClassId { get; set; }
    [Range(1, int.MaxValue), Display(Name = "Phòng")] public int RoomId { get; set; }
    [Range(1, int.MaxValue), Display(Name = "Huấn luyện viên")] public int TrainerId { get; set; }
    [Display(Name = "Bắt đầu")] public DateTime StartAt { get; set; } = DateTime.Today.AddDays(1).AddHours(18);
    [Display(Name = "Kết thúc")] public DateTime EndAt { get; set; } = DateTime.Today.AddDays(1).AddHours(19);
    [Range(1, 500), Display(Name = "Sức chứa")] public short? Capacity { get; set; }
    [StringLength(500), Display(Name = "Ghi chú")] public string? Note { get; set; }
    public IReadOnlyList<ClassTypeRow> Classes { get; set; } = [];
    public IReadOnlyList<RoomRow> Rooms { get; set; } = [];
    public IReadOnlyList<TrainerOption> Trainers { get; set; } = [];
}

public sealed class OperationsIndexViewModel
{
    public IReadOnlyList<RoomRow> Rooms { get; init; } = [];
    public IReadOnlyList<ClassTypeRow> Classes { get; init; } = [];
    public IReadOnlyList<SessionRow> Sessions { get; init; } = [];
}
public sealed class SessionDetailsViewModel { public required SessionRow Session { get; init; } public IReadOnlyList<BookingRow> Bookings { get; init; } = []; }
public sealed class CheckInViewModel { public int MemberId { get; set; } public long? SessionId { get; set; } public string Method { get; set; } = "FRONT_DESK"; public IReadOnlyList<CheckInRow> History { get; set; } = []; }
