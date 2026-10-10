namespace GymManagement.Web.Presentation;

/// <summary>
/// Converts canonical database codes into consistent Vietnamese labels for the UI.
/// The database keeps stable English codes; presentation concerns stay outside SQL.
/// </summary>
public static class DisplayLabels
{
    public static string Status(string? value) => Normalize(value) switch
    {
        "ACTIVE" => "Đang hoạt động",
        "INACTIVE" => "Đã ngừng",
        "PENDING" => "Chờ xử lý",
        "SUSPENDED" => "Tạm dừng",
        "CANCELLED" => "Đã hủy",
        "EXPIRED" => "Hết hạn",
        "NO_MEMBERSHIP" => "Chưa có gói",
        "SCHEDULED" => "Đã lên lịch",
        "IN_PROGRESS" => "Đang diễn ra",
        "COMPLETED" => "Hoàn tất",
        "FULL" => "Đã đủ chỗ",
        "CONFIRMED" => "Đã xác nhận",
        "WAITLISTED" => "Hàng chờ",
        "ATTENDED" => "Đã tham gia",
        "NO_SHOW" => "Vắng mặt",
        "UNPAID" => "Chưa thanh toán",
        "PARTIALLY_PAID" => "Thanh toán một phần",
        "PAID" => "Đã thanh toán",
        "FAILED" => "Thất bại",
        "REFUNDED" => "Đã hoàn tiền",
        { Length: > 0 } normalized => normalized,
        _ => "—"
    };

    public static string StatusCss(string? value) => Normalize(value) switch
    {
        "ACTIVE" or "OPEN" or "CONFIRMED" or "COMPLETED" or "PAID" or "ATTENDED" => "status-active",
        "PENDING" or "PARTIALLY_PAID" or "WAITLISTED" or "SUSPENDED" or "SCHEDULED" or "IN_PROGRESS" => "status-pending",
        "INACTIVE" or "EXPIRED" or "CANCELLED" or "FULL" or "FAILED" or "NO_SHOW" => "status-inactive",
        _ => "status-neutral"
    };

    public static string CheckInMethod(string? value) => Normalize(value) switch
    {
        "BARCODE" => "Mã vạch",
        "KIOSK" => "Kiosk",
        "FRONT_DESK" => "Lễ tân",
        { Length: > 0 } normalized => normalized,
        _ => "—"
    };

    private static string Normalize(string? value) => value?.Trim().ToUpperInvariant() ?? string.Empty;
}
