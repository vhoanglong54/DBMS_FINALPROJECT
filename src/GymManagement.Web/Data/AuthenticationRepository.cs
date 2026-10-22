using System.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class AuthenticationRepository(ISqlConnectionFactory connectionFactory)
    : IAuthenticationRepository
{
    public async Task<AuthenticatedUser?> FindByUsernameAsync(
        string username,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.sp_AuthenticateUser", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@Username", SqlDbType.VarChar, 50).Value = username;

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(
            CommandBehavior.SingleRow,
            cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AuthenticatedUser(
            reader.GetInt32(reader.GetOrdinal("UserId")),
            reader.GetString(reader.GetOrdinal("Username")),
            (byte[])reader["PasswordHash"],
            (byte[])reader["PasswordSalt"],
            reader.GetInt32(reader.GetOrdinal("PasswordIterations")),
            reader.GetBoolean(reader.GetOrdinal("MustChangePassword")),
            reader.GetByte(reader.GetOrdinal("FailedLoginCount")),
            reader.IsDBNull(reader.GetOrdinal("LockedUntil"))
                ? null
                : reader.GetDateTime(reader.GetOrdinal("LockedUntil")),
            reader.GetString(reader.GetOrdinal("RoleCode")),
            reader.GetString(reader.GetOrdinal("RoleName")),
            reader.IsDBNull(reader.GetOrdinal("EmployeeId"))
                ? null
                : reader.GetInt32(reader.GetOrdinal("EmployeeId")),
            reader.GetString(reader.GetOrdinal("DisplayName")));
    }

    public Task RecordFailedLoginAsync(int userId, CancellationToken cancellationToken) =>
        ExecuteUserProcedureAsync("dbo.sp_RecordFailedLogin", userId, cancellationToken);

    public Task RecordSuccessfulLoginAsync(int userId, CancellationToken cancellationToken) =>
        ExecuteUserProcedureAsync("dbo.sp_RecordSuccessfulLogin", userId, cancellationToken);

    public async Task ChangePasswordAsync(
        int userId,
        byte[] passwordHash,
        byte[] passwordSalt,
        int passwordIterations,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand("dbo.sp_ChangePassword", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@UserId", SqlDbType.Int).Value = userId;
        command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 64).Value = passwordHash;
        command.Parameters.Add("@PasswordSalt", SqlDbType.VarBinary, 32).Value = passwordSalt;
        command.Parameters.Add("@PasswordIterations", SqlDbType.Int).Value = passwordIterations;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task ExecuteUserProcedureAsync(
        string procedureName,
        int userId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 15
        };
        command.Parameters.Add("@UserId", SqlDbType.Int).Value = userId;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
