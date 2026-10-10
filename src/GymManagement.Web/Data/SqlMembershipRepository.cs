using System.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class SqlMembershipRepository(ISqlConnectionFactory connectionFactory) : IMembershipRepository
{
    public async Task<IReadOnlyList<PlanListItem>> ListPlansAsync(
        bool includeInactive,
        CancellationToken cancellationToken)
    {
        var plans = new List<PlanListItem>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_GoiTap_DanhSach");
        Add(command, "@IncludeInactive", SqlDbType.Bit, includeInactive);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            plans.Add(new PlanListItem(
                reader.GetInt32(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetString(3),
                reader.GetInt16(4),
                reader.GetDecimal(5),
                reader.GetByte(6),
                reader.GetBoolean(7),
                reader.GetBoolean(8)));
        }

        return plans;
    }

    public async Task<int> SavePlanAsync(
        PlanEditViewModel model,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_GoiTap_Luu");
        Add(command, "@PlanId", SqlDbType.Int, model.Id);
        Add(command, "@PlanCode", SqlDbType.VarChar, model.Code, 20);
        Add(command, "@PlanName", SqlDbType.NVarChar, model.Name, 120);
        Add(command, "@DurationDays", SqlDbType.SmallInt, model.DurationDays);
        AddDecimal(command, "@Price", model.Price);
        Add(command, "@MaxCheckInsPerDay", SqlDbType.TinyInt, model.MaxCheckInsPerDay);
        Add(command, "@AllowsClasses", SqlDbType.Bit, model.AllowsClasses);
        Add(command, "@Description", SqlDbType.NVarChar, model.Description, 500);
        var output = command.Parameters.Add("@SavedPlanId", SqlDbType.Int);
        output.Direction = ParameterDirection.Output;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (int)output.Value;
    }

    public Task SetPlanActiveAsync(int id, bool active, CancellationToken cancellationToken) =>
        ExecuteAsync(
            "dbo.sp_GoiTap_SetActive",
            command =>
            {
                Add(command, "@PlanId", SqlDbType.Int, id);
                Add(command, "@IsActive", SqlDbType.Bit, active);
            },
            cancellationToken);

    public async Task<IReadOnlyList<SelectOption>> ListMembersAsync(
        CancellationToken cancellationToken)
    {
        var members = new List<SelectOption>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_HoiVien_DanhSach");
        Add(command, "@Search", SqlDbType.NVarChar, null, 120);
        Add(command, "@IncludeInactive", SqlDbType.Bit, false);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            members.Add(new SelectOption(
                reader.GetInt32(0),
                $"{reader.GetString(1)} — {reader.GetString(2)}"));
        }

        return members;
    }

    public async Task<IReadOnlyList<MembershipListItem>> ListMembershipsAsync(
        CancellationToken cancellationToken)
    {
        var memberships = new List<MembershipListItem>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_DangKyGoi_DanhSach");
        Add(command, "@MemberId", SqlDbType.Int, null);

        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            memberships.Add(new MembershipListItem(
                reader.GetInt64(0),
                reader.GetInt32(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetInt32(4),
                reader.GetString(5),
                reader.GetDateTime(6),
                reader.GetDateTime(7),
                reader.GetDecimal(8),
                reader.GetString(9),
                reader.IsDBNull(10) ? null : reader.GetInt64(10),
                reader.IsDBNull(11) ? null : reader.GetString(11),
                reader.IsDBNull(12) ? null : reader.GetDecimal(12),
                reader.IsDBNull(13) ? null : reader.GetDecimal(13),
                reader.IsDBNull(14) ? null : reader.GetString(14)));
        }

        return memberships;
    }

    public async Task<(long membershipId, long invoiceId)> CreateMembershipAsync(
        MembershipCreateViewModel model,
        int employeeId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_DangKyGoiTapMoi");
        Add(command, "@MemberId", SqlDbType.Int, model.MemberId);
        Add(command, "@PlanId", SqlDbType.Int, model.PlanId);
        Add(command, "@EmployeeId", SqlDbType.Int, employeeId);
        Add(command, "@StartDate", SqlDbType.Date, model.StartDate.Date);
        AddDecimal(command, "@InitialPayment", model.InitialPayment);
        Add(command, "@PaymentMethod", SqlDbType.VarChar, model.PaymentMethod, 20);
        Add(command, "@TransactionReference", SqlDbType.VarChar, model.TransactionReference, 100);

        var membershipId = command.Parameters.Add("@MembershipId", SqlDbType.BigInt);
        membershipId.Direction = ParameterDirection.Output;
        var invoiceId = command.Parameters.Add("@InvoiceId", SqlDbType.BigInt);
        invoiceId.Direction = ParameterDirection.Output;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return ((long)membershipId.Value, (long)invoiceId.Value);
    }

    public async Task AddPaymentAsync(
        PaymentCreateViewModel model,
        int employeeId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, "dbo.sp_ThanhToan_Them");
        Add(command, "@InvoiceId", SqlDbType.BigInt, model.InvoiceId);
        Add(command, "@EmployeeId", SqlDbType.Int, employeeId);
        AddDecimal(command, "@Amount", model.Amount);
        Add(command, "@PaymentMethod", SqlDbType.VarChar, model.PaymentMethod, 20);
        Add(command, "@TransactionReference", SqlDbType.VarChar, model.TransactionReference, 100);
        var paymentId = command.Parameters.Add("@PaymentId", SqlDbType.BigInt);
        paymentId.Direction = ParameterDirection.Output;

        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public Task CancelMembershipAsync(
        long id,
        string reason,
        CancellationToken cancellationToken) =>
        ExecuteAsync(
            "dbo.sp_HuyGoiTap",
            command =>
            {
                Add(command, "@MembershipId", SqlDbType.BigInt, id);
                Add(command, "@Reason", SqlDbType.NVarChar, reason, 500);
            },
            cancellationToken);

    private async Task ExecuteAsync(
        string procedureName,
        Action<SqlCommand> configure,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = CreateProcedure(connection, procedureName);
        configure(command);
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static SqlCommand CreateProcedure(SqlConnection connection, string name) => new(name, connection)
    {
        CommandType = CommandType.StoredProcedure,
        CommandTimeout = 30
    };

    private static void Add(
        SqlCommand command,
        string name,
        SqlDbType type,
        object? value,
        int size = 0)
    {
        var parameter = size > 0
            ? command.Parameters.Add(name, type, size)
            : command.Parameters.Add(name, type);
        parameter.Value = value ?? DBNull.Value;
    }

    private static void AddDecimal(SqlCommand command, string name, decimal value)
    {
        var parameter = command.Parameters.Add(name, SqlDbType.Decimal);
        parameter.Precision = 18;
        parameter.Scale = 2;
        parameter.Value = value;
    }
}
