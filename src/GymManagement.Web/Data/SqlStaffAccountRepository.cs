using System.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class SqlStaffAccountRepository(ISqlConnectionFactory connectionFactory) : IStaffAccountRepository
{
    public async Task<string> SuggestEmployeeCodeAsync(
        int actorUserId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.sp_StaffAccount_SuggestCode", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@ActorUserId", SqlDbType.Int).Value = actorUserId;

        await connection.OpenAsync(cancellationToken);
        return (string?)await command.ExecuteScalarAsync(cancellationToken)
            ?? throw new InvalidOperationException("Không nhận được mã nhân viên gợi ý.");
    }

    public async Task<IReadOnlyList<StaffAccountRow>> ListAsync(
        int actorUserId,
        CancellationToken cancellationToken)
    {
        var result = new List<StaffAccountRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.sp_StaffAccount_List", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@ActorUserId", SqlDbType.Int).Value = actorUserId;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new StaffAccountRow(
                reader.GetString(reader.GetOrdinal("EmployeeCode")),
                reader.GetString(reader.GetOrdinal("FullName")),
                reader.GetString(reader.GetOrdinal("EmployeeType")),
                reader.GetString(reader.GetOrdinal("Username")),
                reader.GetBoolean(reader.GetOrdinal("UserIsActive"))));
        }
        return result;
    }

    public async Task CreateAsync(StaffAccountCreateCommand account, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.sp_StaffAccount_Create", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@ActorUserId", SqlDbType.Int).Value = account.ActorUserId;
        command.Parameters.Add("@EmployeeCode", SqlDbType.VarChar, 20).Value = account.EmployeeCode;
        command.Parameters.Add("@FullName", SqlDbType.NVarChar, 120).Value = account.FullName;
        command.Parameters.Add("@Phone", SqlDbType.VarChar, 15).Value = account.Phone;
        command.Parameters.Add("@Email", SqlDbType.VarChar, 254).Value =
            (object?)account.Email ?? DBNull.Value;
        command.Parameters.Add("@HireDate", SqlDbType.Date).Value = account.HireDate.Date;
        command.Parameters.Add("@EmployeeType", SqlDbType.VarChar, 20).Value = account.EmployeeType;
        command.Parameters.Add("@Username", SqlDbType.VarChar, 50).Value = account.Username;
        command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 64).Value = account.PasswordHash;
        command.Parameters.Add("@PasswordSalt", SqlDbType.VarBinary, 32).Value = account.PasswordSalt;
        command.Parameters.Add("@PasswordIterations", SqlDbType.Int).Value = account.PasswordIterations;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
