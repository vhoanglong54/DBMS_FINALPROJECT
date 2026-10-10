using System.Data;
using GymManagement.Web.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Services;

public sealed class SqlGymReportingRepository(ISqlConnectionFactory connectionFactory) : IGymReportingRepository
{
    public async Task<(int active, IReadOnlyList<ExpiringMembership> expiring)> GetMembershipSummaryAsync(CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = Procedure(connection, "dbo.sp_TV4_DashboardHoiVien");
        var expiring = new List<ExpiringMembership>();
        int active;
        await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
        {
            active = await reader.ReadAsync(cancellationToken) && !reader.IsDBNull(0) ? reader.GetInt32(0) : 0;
            if (await reader.NextResultAsync(cancellationToken))
                while (await reader.ReadAsync(cancellationToken))
                    expiring.Add(new(reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetString(3), reader.GetDateTime(4), reader.GetInt32(5)));
        }
        return (active, expiring);
    }

    public Task<IReadOnlyList<DailyRevenue>> GetRevenueAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken) =>
        ReadAsync("dbo.sp_TV4_BaoCaoDoanhThu", fromDate, throughDate, r => new DailyRevenue(r.GetDateTime(0), r.GetDecimal(1), r.GetInt32(2)), cancellationToken);

    public Task<IReadOnlyList<ClassSessionReport>> GetClassesAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken) =>
        ReadAsync("dbo.sp_TV4_BaoCaoCongSuatLop", fromDate, throughDate, r => new ClassSessionReport(
            r.GetInt64(0), r.GetString(1), r.GetString(2), r.GetString(3), r.GetDateTime(4), r.GetDateTime(5),
            r.GetInt16(6), r.GetInt32(7), r.GetInt32(8), r.GetString(9)), cancellationToken);

    public Task<IReadOnlyList<AttendanceReport>> GetAttendanceAsync(DateTime fromDate, DateTime throughDate, CancellationToken cancellationToken) =>
        ReadAsync("dbo.sp_TV4_BaoCaoDiemDanh", fromDate, throughDate, r => new AttendanceReport(
            r.GetInt64(0), r.GetInt32(1), r.GetString(2), r.GetString(3), r.GetString(4),
            r.IsDBNull(5) ? null : r.GetString(5), r.GetDateTime(8), r.GetString(9)), cancellationToken);

    public async Task<MemberSearchViewModel> SearchMembersAsync(string? query, string? status, int page, int pageSize, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = Procedure(connection, "dbo.sp_TV4_TimKiemHoiVien");
        command.Parameters.Add("@Query", SqlDbType.NVarChar, 120).Value = (object?)query ?? DBNull.Value;
        command.Parameters.Add("@Status", SqlDbType.VarChar, 20).Value = (object?)status ?? DBNull.Value;
        command.Parameters.Add("@Page", SqlDbType.Int).Value = page;
        command.Parameters.Add("@PageSize", SqlDbType.Int).Value = pageSize;
        var total = command.Parameters.Add("@TotalCount", SqlDbType.Int);
        total.Direction = ParameterDirection.Output;
        var members = new List<MemberSearchRow>();
        await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            while (await reader.ReadAsync(cancellationToken))
                members.Add(new(reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetString(3),
                    reader.IsDBNull(4) ? null : reader.GetString(4), reader.GetString(5),
                    reader.IsDBNull(6) ? null : reader.GetDateTime(6), reader.IsDBNull(7) ? null : reader.GetDateTime(7)));
        var totalCount = total.Value is int count ? count : 0;
        var lastPage = Math.Max(1, (int)Math.Ceiling(totalCount / (double)pageSize));
        if (page > lastPage)
            return await SearchMembersAsync(query, status, lastPage, pageSize, cancellationToken);

        return new MemberSearchViewModel
        {
            Query = query,
            Status = status,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            Members = members
        };
    }

    private async Task<IReadOnlyList<T>> ReadAsync<T>(string procedureName, DateTime fromDate, DateTime throughDate, Func<SqlDataReader, T> map, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = Procedure(connection, procedureName);
        command.Parameters.Add("@FromDate", SqlDbType.Date).Value = fromDate.Date;
        command.Parameters.Add("@ToDate", SqlDbType.Date).Value = throughDate.Date;
        var result = new List<T>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) result.Add(map(reader));
        return result;
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) => new(name, connection)
    {
        CommandType = CommandType.StoredProcedure,
        CommandTimeout = 30
    };
}
