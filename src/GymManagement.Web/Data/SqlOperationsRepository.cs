using System.Data;
using GymManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace GymManagement.Web.Data;

public sealed class SqlOperationsRepository(ISqlConnectionFactory connectionFactory) : IOperationsRepository
{
    public async Task<IReadOnlyList<RoomRow>> RoomsAsync(
        bool includeInactive,
        CancellationToken cancellationToken)
    {
        var rooms = new List<RoomRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_PhongTap_DanhSach");
        Add(command, "@IncludeInactive", SqlDbType.Bit, includeInactive);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rooms.Add(new RoomRow(
                reader.GetInt32(0), reader.GetString(1), reader.GetString(2),
                reader.GetInt16(3), reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.GetBoolean(5)));
        }
        return rooms;
    }

    public async Task<int> SaveRoomAsync(
        RoomEditViewModel model,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_PhongTap_Upsert");
        Add(command, "@RoomId", SqlDbType.Int, model.Id);
        Add(command, "@RoomCode", SqlDbType.VarChar, model.Code, 20);
        Add(command, "@RoomName", SqlDbType.NVarChar, model.Name, 100);
        Add(command, "@Capacity", SqlDbType.SmallInt, model.Capacity);
        Add(command, "@Location", SqlDbType.NVarChar, model.Location, 200);
        var output = command.Parameters.Add("@NewRoomId", SqlDbType.Int);
        output.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (int)output.Value;
    }

    public Task SetRoomActiveAsync(int id, bool active, CancellationToken cancellationToken) =>
        ExecuteAsync("dbo.sp_PhongTap_SetActive", command =>
        {
            Add(command, "@RoomId", SqlDbType.Int, id);
            Add(command, "@IsActive", SqlDbType.Bit, active);
        }, cancellationToken);

    public async Task<IReadOnlyList<ClassTypeRow>> ClassesAsync(
        bool includeInactive,
        CancellationToken cancellationToken)
    {
        var classes = new List<ClassTypeRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_LopTap_DanhSach");
        Add(command, "@IncludeInactive", SqlDbType.Bit, includeInactive);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            classes.Add(new ClassTypeRow(
                reader.GetInt32(0), reader.GetString(1), reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetString(3), reader.GetInt16(4),
                reader.GetString(5), reader.GetBoolean(6)));
        }
        return classes;
    }

    public async Task<int> SaveClassAsync(
        ClassTypeEditViewModel model,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_LopTap_Upsert");
        Add(command, "@ClassId", SqlDbType.Int, model.Id);
        Add(command, "@ClassCode", SqlDbType.VarChar, model.Code, 20);
        Add(command, "@ClassName", SqlDbType.NVarChar, model.Name, 120);
        Add(command, "@Description", SqlDbType.NVarChar, model.Description, 500);
        Add(command, "@DefaultDurationMinutes", SqlDbType.SmallInt, model.Duration);
        Add(command, "@DifficultyLevel", SqlDbType.VarChar, model.Difficulty, 20);
        var output = command.Parameters.Add("@NewClassId", SqlDbType.Int);
        output.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (int)output.Value;
    }

    public Task SetClassActiveAsync(int id, bool active, CancellationToken cancellationToken) =>
        ExecuteAsync("dbo.sp_LopTap_SetActive", command =>
        {
            Add(command, "@ClassId", SqlDbType.Int, id);
            Add(command, "@IsActive", SqlDbType.Bit, active);
        }, cancellationToken);

    public async Task<IReadOnlyList<TrainerOption>> TrainersAsync(
        CancellationToken cancellationToken)
    {
        var trainers = new List<TrainerOption>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_NhanVien_DanhSachHLV");
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
            trainers.Add(new TrainerOption(reader.GetInt32(0), reader.GetString(1)));
        return trainers;
    }

    public async Task<IReadOnlyList<SessionRow>> SessionsAsync(
        DateTime from,
        DateTime through,
        CancellationToken cancellationToken)
    {
        var sessions = new List<SessionRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_LichLop_DanhSach");
        Add(command, "@TuNgay", SqlDbType.Date, from.Date);
        Add(command, "@DenNgay", SqlDbType.Date, through.Date);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            sessions.Add(new SessionRow(
                reader.GetInt64(0), reader.GetInt32(1), reader.GetString(2),
                reader.GetInt32(3), reader.GetString(4), reader.GetInt32(5),
                reader.GetString(6), reader.GetDateTime(7), reader.GetDateTime(8),
                reader.GetInt16(9), reader.GetInt32(10), reader.GetInt32(11),
                reader.GetString(12)));
        }
        return sessions;
    }

    public async Task<long> CreateSessionAsync(
        SessionCreateViewModel model,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_LichLop_TaoLich");
        Add(command, "@ClassId", SqlDbType.Int, model.ClassId);
        Add(command, "@RoomId", SqlDbType.Int, model.RoomId);
        Add(command, "@TrainerId", SqlDbType.Int, model.TrainerId);
        Add(command, "@StartAt", SqlDbType.DateTime2, model.StartAt);
        Add(command, "@EndAt", SqlDbType.DateTime2, model.EndAt);
        Add(command, "@Capacity", SqlDbType.SmallInt, model.Capacity);
        Add(command, "@Note", SqlDbType.NVarChar, model.Note, 500);
        var output = command.Parameters.Add("@NewSessionId", SqlDbType.BigInt);
        output.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (long)output.Value;
    }

    public Task CancelSessionAsync(long id, string reason, CancellationToken cancellationToken) =>
        ExecuteAsync("dbo.sp_LichLop_HuyLich", command =>
        {
            Add(command, "@SessionId", SqlDbType.BigInt, id);
            Add(command, "@Reason", SqlDbType.NVarChar, reason, 500);
        }, cancellationToken);

    public async Task<IReadOnlyList<BookingRow>> BookingsAsync(
        long sessionId,
        CancellationToken cancellationToken)
    {
        var bookings = new List<BookingRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_DatLop_DanhSachTheoBuoi");
        Add(command, "@SessionId", SqlDbType.BigInt, sessionId);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            bookings.Add(new BookingRow(
                reader.GetInt64(0), reader.GetInt32(1), reader.GetString(2),
                reader.GetString(3), reader.GetString(4), reader.GetDateTime(5),
                reader.IsDBNull(6) ? null : reader.GetDateTime(6),
                reader.IsDBNull(7) ? null : reader.GetString(7)));
        }
        return bookings;
    }

    public async Task<(long id, string status)> BookAsync(
        int memberId,
        long sessionId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_DatLop_DatCho");
        Add(command, "@MemberId", SqlDbType.Int, memberId);
        Add(command, "@SessionId", SqlDbType.BigInt, sessionId);
        var bookingId = command.Parameters.Add("@NewBookingId", SqlDbType.BigInt);
        bookingId.Direction = ParameterDirection.Output;
        var status = command.Parameters.Add("@ResultStatus", SqlDbType.VarChar, 20);
        status.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return ((long)bookingId.Value, (string)status.Value);
    }

    public Task CancelBookingAsync(long id, string reason, CancellationToken cancellationToken) =>
        ExecuteAsync("dbo.sp_DatLop_HuyCho", command =>
        {
            Add(command, "@BookingId", SqlDbType.BigInt, id);
            Add(command, "@Reason", SqlDbType.NVarChar, reason, 500);
        }, cancellationToken);

    public async Task<long> CheckInAsync(
        int memberId,
        int employeeId,
        long? sessionId,
        string method,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_CheckIn_GhiNhan");
        Add(command, "@MemberId", SqlDbType.Int, memberId);
        Add(command, "@EmployeeId", SqlDbType.Int, employeeId);
        Add(command, "@SessionId", SqlDbType.BigInt, sessionId);
        Add(command, "@CheckInMethod", SqlDbType.VarChar, method, 20);
        var checkInId = command.Parameters.Add("@NewCheckInId", SqlDbType.BigInt);
        checkInId.Direction = ParameterDirection.Output;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return (long)checkInId.Value;
    }

    public async Task<IReadOnlyList<CheckInRow>> CheckInHistoryAsync(
        int? memberId,
        CancellationToken cancellationToken)
    {
        var history = new List<CheckInRow>();
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, "dbo.sp_CheckIn_LichSu");
        Add(command, "@MemberId", SqlDbType.Int, memberId);
        Add(command, "@Top", SqlDbType.Int, 100);
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            history.Add(new CheckInRow(
                reader.GetInt64(0), reader.GetInt32(1), reader.GetString(2),
                reader.GetString(3), reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetInt64(6),
                reader.IsDBNull(7) ? null : reader.GetDateTime(7),
                reader.GetDateTime(8), reader.GetString(9)));
        }
        return history;
    }

    private async Task ExecuteAsync(
        string procedureName,
        Action<SqlCommand> configure,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Procedure(connection, procedureName);
        configure(command);
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static SqlCommand Procedure(SqlConnection connection, string name) => new(name, connection)
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
}
