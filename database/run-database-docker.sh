#!/usr/bin/env bash
set -euo pipefail

container_name="${SQLSERVER_CONTAINER:-gym-sqlserver}"
database_name="${1:-GymManagementDemo}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database_dir="$root_dir/database"
container_sql_dir="/tmp/gym-management-database"
sqlcmd_path="/opt/mssql-tools18/bin/sqlcmd"

if [[ ! "$database_name" =~ ^[A-Za-z][A-Za-z0-9_]{0,63}$ ]]; then
    printf 'Tên database không hợp lệ: %s\n' "$database_name" >&2
    printf 'Dùng chữ cái đầu tiên, sau đó chỉ chữ cái, số hoặc dấu gạch dưới.\n' >&2
    exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
    printf 'Không tìm thấy Docker CLI. Hãy mở Docker Desktop rồi thử lại.\n' >&2
    exit 2
fi

if [[ "$(docker inspect --format '{{.State.Running}}' "$container_name" 2>/dev/null || true)" != "true" ]]; then
    printf 'Container %s chưa chạy. Kiểm tra bằng: docker ps -a --filter name=%s\n' "$container_name" "$container_name" >&2
    exit 2
fi

read -r -s -p 'Nhập mật khẩu sa đã đặt khi tạo container: ' sa_password
printf '\n'
if [[ -z "$sa_password" ]]; then
    printf 'Mật khẩu không được để trống.\n' >&2
    exit 2
fi

sqlcmd=(docker exec "$container_name" "$sqlcmd_path" -S localhost -U sa -P "$sa_password" -C -b -r 1)

printf 'Đang chờ SQL Server sẵn sàng'
ready=false
for _ in {1..60}; do
    if "${sqlcmd[@]}" -Q 'SELECT 1' >/dev/null 2>&1; then
        ready=true
        break
    fi
    printf '.'
    sleep 2
done
printf '\n'

if [[ "$ready" != true ]]; then
    printf 'SQL Server chưa sẵn sàng hoặc mật khẩu sa không đúng. Xem log: docker logs %s\n' "$container_name" >&2
    exit 1
fi

database_state=$("${sqlcmd[@]}" -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'$database_name') IS NULL THEN 'MISSING' ELSE 'EXISTS' END;" | tr -d '[:space:]')
if [[ "$database_state" != "MISSING" ]]; then
    printf 'Database %s đã tồn tại; dừng để tránh ghi đè dữ liệu. Hãy chọn tên database mới.\n' "$database_name" >&2
    exit 1
fi

docker exec "$container_name" mkdir -p "$container_sql_dir"
docker cp "$database_dir/." "$container_name:$container_sql_dir/" >/dev/null

scripts=(
    '00_create_database.sql'
    '01_schema.sql'
    '02a_membership_constraints.sql'
    '02b_operations_constraints.sql'
    '07a_membership_functions.sql'
    '07b_operations_functions.sql'
    '03a_membership_triggers.sql'
    '03b_operations_triggers.sql'
    '04a_membership_views.sql'
    '04b_operations_views.sql'
    '04c_tv4_reporting_views.sql'
    '05a_membership_indexes.sql'
    '05b_operations_indexes.sql'
    '06a_membership_procedures.sql'
    '06b_operations_procedures.sql'
    '06c_tv4_reporting_procedures.sql'
    '08_security.sql'
    '08a_membership_security_grants.sql'
    '08b_operations_security_grants.sql'
    '08c_tv4_reporting_security_grants.sql'
    '09_seed_demo.sql'
    '09b_operations_seed_demo.sql'
)

for script in "${scripts[@]}"; do
    script_path="$container_sql_dir/$script"
    if ! docker exec "$container_name" test -f "$script_path"; then
        printf 'Thiếu script bắt buộc: %s\n' "$script" >&2
        exit 1
    fi

    printf '[%s] %s\n' "$database_name" "$script"
    "${sqlcmd[@]}" -i "$script_path" -v \
        "DatabaseName=$database_name" \
        'CreateDemoLogins=0' \
        'AdminLogin=gym_admin_login' \
        'ReceptionLogin=gym_reception_login' \
        'TrainerLogin=gym_trainer_login' \
        'AccountantLogin=gym_accountant_login' \
        'AdminPassword=CHANGE_ME_Admin' \
        'ReceptionPassword=CHANGE_ME_Reception' \
        'TrainerPassword=CHANGE_ME_Trainer' \
        'AccountantPassword=CHANGE_ME_Accountant'
done

connection_string="Server=localhost,1433;Database=$database_name;User ID=sa;Password=$sa_password;Encrypt=True;TrustServerCertificate=True"
dotnet user-secrets --project "$root_dir/src/GymManagement.Web" set 'ConnectionStrings:GymDb' "$connection_string" >/dev/null
unset sa_password connection_string

printf '\nĐã tạo database %s và lưu connection string vào User Secrets của ứng dụng.\n' "$database_name"
printf 'Khởi động lại web app bằng: dotnet run --project src/GymManagement.Web\n'
