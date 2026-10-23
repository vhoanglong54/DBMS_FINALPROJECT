[CmdletBinding()]
param(
    [string]$Server = '.\SQLEXPRESS',

    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,63}$')]
    [string]$DatabaseName = 'GymManagementDB',

    [switch]$DropExisting,
    [switch]$SkipTests,
    [switch]$SecurityOnly,
    [switch]$UpdateLogicOnly,
    [switch]$CreateDemoLogins,

    [string]$AdminPassword = 'CHANGE_ME_Admin',
    [string]$ReceptionPassword = 'CHANGE_ME_Reception',
    [string]$TrainerPassword = 'CHANGE_ME_Trainer',
    [string]$AccountantPassword = 'CHANGE_ME_Accountant'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sqlcmd = Get-Command sqlcmd -ErrorAction Stop
$root = Split-Path -Parent $PSScriptRoot

if ($DatabaseName -in @('master', 'model', 'msdb', 'tempdb')) {
    throw 'Không được dùng tên system database.'
}

if ($CreateDemoLogins -and @($AdminPassword, $ReceptionPassword, $TrainerPassword, $AccountantPassword).Where({ $_ -like 'CHANGE_ME*' }).Count -gt 0) {
    throw 'Khi bật CreateDemoLogins, phải truyền đủ bốn mật khẩu không phải placeholder.'
}

if ($SecurityOnly -and $DropExisting) {
    throw 'Không thể dùng SecurityOnly cùng DropExisting.'
}

if ($UpdateLogicOnly -and ($DropExisting -or $SecurityOnly)) {
    throw 'UpdateLogicOnly không dùng cùng DropExisting hoặc SecurityOnly.'
}

if ($SecurityOnly -or $UpdateLogicOnly) {
    & $sqlcmd.Source -S $Server -E -b -r 1 -d master -Q "IF DB_ID(N'$DatabaseName') IS NULL THROW 51000, N'Database chưa tồn tại.', 1;"
    if ($LASTEXITCODE -ne 0) { throw "Database $DatabaseName chưa tồn tại." }
}

if ($DropExisting) {
    $dropQuery = "IF DB_ID(N'$DatabaseName') IS NOT NULL BEGIN ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$DatabaseName]; END;"
    & $sqlcmd.Source -S $Server -E -b -r 1 -d master -Q $dropQuery
    if ($LASTEXITCODE -ne 0) { throw "Không thể xóa database kiểm thử $DatabaseName." }
}

$scripts = @(
    'database\00_create_database.sql',
    'database\01_schema.sql',
    'database\02a_membership_constraints.sql',
    'database\02b_operations_constraints.sql',
    'database\07a_membership_functions.sql',
    'database\07b_operations_functions.sql',
    'database\03a_membership_triggers.sql',
    'database\03b_operations_triggers.sql',
    'database\04a_membership_views.sql',
    'database\04b_operations_views.sql',
    'database\04c_tv4_reporting_views.sql',
    'database\05a_membership_indexes.sql',
    'database\05b_operations_indexes.sql',
    'database\06a_membership_procedures.sql',
    'database\06b_operations_procedures.sql',
    'database\06c_tv4_reporting_procedures.sql',
    'database\08_security.sql',
    'database\08a_membership_security_grants.sql',
    'database\08b_operations_security_grants.sql',
    'database\08c_tv4_reporting_security_grants.sql',
    'database\09_seed_demo.sql',
    'database\09b_operations_seed_demo.sql'
)

if ($SecurityOnly) {
    $scripts = @('database\08_security.sql')
}

if ($UpdateLogicOnly) {
    $scripts = @(
        'database\07a_membership_functions.sql',
        'database\07b_operations_functions.sql',
        'database\04b_operations_views.sql',
        'database\04c_tv4_reporting_views.sql',
        'database\06a_membership_procedures.sql',
        'database\06b_operations_procedures.sql',
        'database\08_security.sql',
        'database\08a_membership_security_grants.sql',
        'database\08b_operations_security_grants.sql',
        'database\08c_tv4_reporting_security_grants.sql'
    )
}

if (-not $SkipTests -and -not $SecurityOnly -and -not $UpdateLogicOnly) {
    $scripts += @(
        'database\10_smoke_tests.sql',
        'database\10a_membership_smoke_tests.sql',
        'database\10b_operations_smoke_tests.sql',
        'database\10c_rubric_verification.sql'
    )
}

$variables = @(
    "DatabaseName=$DatabaseName",
    "CreateDemoLogins=$([int]$CreateDemoLogins.IsPresent)",
    'AdminLogin=gym_admin_login',
    'ReceptionLogin=gym_reception_login',
    'TrainerLogin=gym_trainer_login',
    'AccountantLogin=gym_accountant_login',
    "AdminPassword=$AdminPassword",
    "ReceptionPassword=$ReceptionPassword",
    "TrainerPassword=$TrainerPassword",
    "AccountantPassword=$AccountantPassword"
)

foreach ($relativePath in $scripts) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Thiếu script bắt buộc: $relativePath" }
    Write-Host "[$DatabaseName] $relativePath" -ForegroundColor Cyan
    & $sqlcmd.Source -S $Server -E -b -r 1 -i $path -v $variables -f 65001
    if ($LASTEXITCODE -ne 0) { throw "Script thất bại: $relativePath (exit $LASTEXITCODE)." }
}

if ($SecurityOnly) {
    Write-Host "Database $DatabaseName đã cập nhật các đối tượng bảo mật; không chạy lại schema hoặc seed." -ForegroundColor Green
}
elseif ($UpdateLogicOnly) {
    Write-Host "Database $DatabaseName đã cập nhật function, view, procedure và quyền; không chạy lại schema hoặc seed." -ForegroundColor Green
}
else {
    Write-Host "Database $DatabaseName đã được cài đặt và kiểm thử thành công." -ForegroundColor Green
}
