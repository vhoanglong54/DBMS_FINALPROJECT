using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public interface ISqlConnectionFactory
{
    SqlConnection CreateConnection();
}
