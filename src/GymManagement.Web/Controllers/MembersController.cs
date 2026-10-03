using GymManagement.Web.Authorization;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

namespace GymManagement.Web.Controllers;

[Authorize]
public class MembersController(ISqlConnectionFactory connectionFactory) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        var members = new List<dynamic>();

        try
        {
            await using var connection = connectionFactory.CreateConnection();
            await using var command = new SqlCommand("SELECT * FROM dbo.HoiVien", connection);
            
            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken))
            {
                members.Add(new
                {
                    Id = reader["MemberId"] != DBNull.Value ? reader.GetValue(reader.GetOrdinal("MemberId")) : 0,
                    FullName = reader["FullName"]?.ToString() ?? "",
                    Phone = reader["Phone"]?.ToString() ?? "",
                    Email = reader["Email"] == DBNull.Value ? "" : reader["Email"]?.ToString() ?? "",
                    DateOfBirth = reader.IsDBNull(reader.GetOrdinal("DateOfBirth")) ? DateTime.MinValue : reader.GetDateTime(reader.GetOrdinal("DateOfBirth")),
                    Gender = reader["Gender"]?.ToString() ?? ""
                });
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Lỗi đọc CSDL: " + ex.Message);
        }

        return View(members);
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id, CancellationToken cancellationToken)
    {
        dynamic? member = null;
        try
        {
            await using var connection = connectionFactory.CreateConnection();
            
            await using var command = new SqlCommand("SELECT * FROM dbo.HoiVien WHERE MemberId = @Id", (SqlConnection)connection);
            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(CommandBehavior.SingleRow, cancellationToken);

            if (await reader.ReadAsync(cancellationToken))
            {
                member = new
                {
                    Id = reader.GetValue(reader.GetOrdinal("MemberId")),
                    FullName = reader["FullName"]?.ToString() ?? "",
                    Phone = reader["Phone"]?.ToString() ?? "",
                    Email = reader["Email"] == DBNull.Value ? "" : reader["Email"]?.ToString() ?? "",
                    DateOfBirth = reader.IsDBNull(reader.GetOrdinal("DateOfBirth")) ? DateTime.MinValue : reader.GetDateTime(reader.GetOrdinal("DateOfBirth")),
                    Gender = reader["Gender"]?.ToString() ?? ""
                };
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Lỗi chi tiết: " + ex.Message);
        }

        if (member == null)
        {
            return NotFound();
        }

        return View(member);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View(new MemberViewModel { DateOfBirth = new DateTime(2000, 1, 1) });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(MemberViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            await using var connection = connectionFactory.CreateConnection();
            await using var command = new SqlCommand("dbo.sp_ThemHoiVien", (SqlConnection)connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            
            command.Parameters.AddWithValue("@FullName", model.FullName);
            command.Parameters.AddWithValue("@Phone", model.Phone);
            command.Parameters.AddWithValue("@Email", string.IsNullOrWhiteSpace(model.Email) ? DBNull.Value : model.Email);
            command.Parameters.AddWithValue("@DateOfBirth", model.DateOfBirth);
            command.Parameters.AddWithValue("@Gender", model.Gender);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();

            return RedirectToAction(nameof(Index));
        }
        catch (SqlException ex)
        {
            if (ex.Number == 2601)
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
            else
                ModelState.AddModelError("", "Lỗi CSDL: " + ex.Message);
            
            return View(model);
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        try
        {
            await using var connection = (SqlConnection)connectionFactory.CreateConnection();
            await connection.OpenAsync(cancellationToken);

            // Mở Transaction thực hiện xóa dọn dẹp theo đúng thứ tự phân cấp từ lá (con sâu nhất) về gốc (cha)
            await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(cancellationToken);

            try
            {
                // Bước 1: Xóa bảng ThanhToan trước (vì tham chiếu tới HoaDon)
                using (var cmd1 = new SqlCommand("DELETE FROM dbo.ThanhToan WHERE InvoiceId IN (SELECT InvoiceId FROM dbo.HoaDon WHERE MemberId = @Id OR MembershipId IN (SELECT MembershipId FROM dbo.DangKyGoi WHERE MemberId = @Id))", connection, transaction))
                {
                    cmd1.Parameters.AddWithValue("@Id", id);
                    try { await cmd1.ExecuteNonQueryAsync(cancellationToken); } catch { }
                }

                // Bước 2: Xóa bảng HoaDon (vì tham chiếu tới DangKyGoi qua MembershipId)
                using (var cmd2 = new SqlCommand("DELETE FROM dbo.HoaDon WHERE MemberId = @Id OR MembershipId IN (SELECT MembershipId FROM dbo.DangKyGoi WHERE MemberId = @Id)", connection, transaction))
                {
                    cmd2.Parameters.AddWithValue("@Id", id);
                    try { await cmd2.ExecuteNonQueryAsync(cancellationToken); } catch { }
                }

                // Bước 3: Sau khi đã sạch HoaDon và ThanhToan, tiến hành xóa bảng DangKyGoi (Gói tập)
                using (var cmd3 = new SqlCommand("DELETE FROM dbo.DangKyGoi WHERE MemberId = @Id", connection, transaction))
                {
                    cmd3.Parameters.AddWithValue("@Id", id);
                    try { await cmd3.ExecuteNonQueryAsync(cancellationToken); } catch { }
                }

                // Bước 4: Cuối cùng mới thực hiện xóa hội viên chính trong bảng HoiVien
                using (var cmd4 = new SqlCommand("DELETE FROM dbo.HoiVien WHERE MemberId = @Id", connection, transaction))
                {
                    cmd4.Parameters.AddWithValue("@Id", id);
                    await cmd4.ExecuteNonQueryAsync(cancellationToken);
                }

                // Xác nhận hoàn tất Transaction
                await transaction.CommitAsync(cancellationToken);
            }
            catch
            {
                // Hoàn tác nếu có lỗi phát sinh
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = "Không thể xóa hội viên này! Chi tiết lỗi: " + ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}