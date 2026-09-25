using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace GymManagement.Web.Health;

public sealed class DatabaseHealthCheck(Data.ISqlConnectionFactory connectionFactory) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = connectionFactory.CreateConnection();
            await connection.OpenAsync(cancellationToken);
            return HealthCheckResult.Healthy("SQL Server connected.");
        }
        catch (Exception exception)
        {
            return HealthCheckResult.Unhealthy("Không thể kết nối SQL Server.", exception);
        }
    }
}
