using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class SqlConnectionFactory(IConfiguration configuration) : ISqlConnectionFactory
{
    private readonly string _connectionString = configuration.GetConnectionString("GymDb")
        ?? throw new InvalidOperationException(
            "Thiếu ConnectionStrings:GymDb. Hãy cấu hình bằng User Secrets hoặc biến môi trường.");

    public SqlConnection CreateConnection()
    {
        if (string.IsNullOrWhiteSpace(_connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:GymDb đang rỗng. Xem README để cấu hình an toàn.");
        }

        return new SqlConnection(_connectionString);
    }
}
