using System.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class SqlMemberRepository(ISqlConnectionFactory connectionFactory) : IMemberRepository
{
    public async Task<IReadOnlyList<MemberListItem>> ListAsync(string? search, bool includeInactive, CancellationToken cancellationToken)
    {
        var result = new List<MemberListItem>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_HoiVien_DanhSach");
        command.Parameters.Add("@Search", SqlDbType.NVarChar, 120).Value = (object?)search ?? DBNull.Value;
        command.Parameters.Add("@IncludeInactive", SqlDbType.Bit).Value = includeInactive;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
            result.Add(new(reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetString(6), reader.GetDateTime(3),
                reader.IsDBNull(4) ? null : reader.GetString(4), reader.GetBoolean(14)));
        return result;
    }

    public async Task<MemberDetailsViewModel?> GetAsync(int id, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_HoiVien_ChiTiet");
        command.Parameters.Add("@MemberId", SqlDbType.Int).Value = id;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) return null;
        var member = new MemberEditViewModel
        {
            Id = reader.GetInt32(0),
            Code = reader.GetString(1),
            FullName = reader.GetString(2),
            DateOfBirth = reader.GetDateTime(3),
            Gender = reader.IsDBNull(4) ? null : reader.GetString(4),
            Phone = reader.GetString(5),
            Email = reader.IsDBNull(6) ? null : reader.GetString(6),
            Address = reader.IsDBNull(7) ? null : reader.GetString(7),
            EmergencyContact = reader.IsDBNull(8) ? null : reader.GetString(8),
            MedicalNote = reader.IsDBNull(9) ? null : reader.GetString(9),
            HeightCm = reader.IsDBNull(10) ? null : reader.GetInt32(10),
            WeightKg = reader.IsDBNull(11) ? null : reader.GetInt32(11),
            PreferredWorkoutTime = reader.IsDBNull(12) ? null : reader.GetString(12),
            IsActive = reader.GetBoolean(14)
        };
        var memberships = new List<MemberMembershipRow>();
        if (await reader.NextResultAsync(cancellationToken))
            while (await reader.ReadAsync(cancellationToken))
                memberships.Add(new(reader.GetInt64(0), reader.GetString(1), reader.GetDateTime(2),
                    reader.GetDateTime(3), reader.GetDecimal(4), reader.GetString(5),
                    reader.IsDBNull(6) ? null : reader.GetString(6)));
        return new MemberDetailsViewModel { Member = member, Memberships = memberships };
    }

    public async Task<int> SaveAsync(MemberEditViewModel member, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_HoiVien_Luu");
        Add(command, "@MemberId", SqlDbType.Int, member.Id);
        Add(command, "@FullName", SqlDbType.NVarChar, member.FullName, 120);
        Add(command, "@Phone", SqlDbType.VarChar, member.Phone, 15);
        Add(command, "@Email", SqlDbType.VarChar, member.Email, 254);
        Add(command, "@DateOfBirth", SqlDbType.Date, member.DateOfBirth.Date);
        Add(command, "@Gender", SqlDbType.VarChar, member.Gender, 10);
        Add(command, "@Address", SqlDbType.NVarChar, member.Address, 300);
        Add(command, "@EmergencyContact", SqlDbType.NVarChar, member.EmergencyContact, 150);
        Add(command, "@MedicalNote", SqlDbType.NVarChar, member.MedicalNote, 1000);
        Add(command, "@ChieuCao", SqlDbType.Int, member.HeightCm);
        Add(command, "@CanNang", SqlDbType.Int, member.WeightKg);
        Add(command, "@ThoiGianTap", SqlDbType.NVarChar, member.PreferredWorkoutTime, 50);
        var output = command.Parameters.Add("@SavedMemberId", SqlDbType.Int);
        output.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (int)output.Value;
    }

    public async Task SetActiveAsync(int id, bool isActive, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_HoiVien_SetActive");
        command.Parameters.Add("@MemberId", SqlDbType.Int).Value = id;
        command.Parameters.Add("@IsActive", SqlDbType.Bit).Value = isActive;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) => new(name, connection)
    { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };

    private static void Add(SqlCommand command, string name, SqlDbType type, object? value, int size = 0)
    {
        var parameter = size > 0 ? command.Parameters.Add(name, type, size) : command.Parameters.Add(name, type);
        parameter.Value = value ?? DBNull.Value;
    }
}
