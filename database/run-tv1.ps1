[CmdletBinding()]
param(
    [Parameter()]
    [string]$Server = '.\SQLEXPRESS',

    [Parameter()]
    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$DatabaseName = 'GymManagementDB'
)

$ErrorActionPreference = 'Stop'
$scriptDirectory = $PSScriptRoot
$sqlcmd = Get-Command sqlcmd -ErrorAction Stop

$scripts = @(
    '00_create_database.sql',
    '01_schema.sql',
    '08_security.sql',
    '09_seed_demo.sql',
    '10_smoke_tests.sql'
)

$sqlVariables = @(
    "DatabaseName=$DatabaseName",
    'CreateDemoLogins=0',
    'AdminLogin=gym_admin_login',
    'ReceptionLogin=gym_reception_login',
    'TrainerLogin=gym_trainer_login',
    'AccountantLogin=gym_accountant_login',
    'AdminPassword=CHANGE_ME_Admin',
    'ReceptionPassword=CHANGE_ME_Reception',
    'TrainerPassword=CHANGE_ME_Trainer',
    'AccountantPassword=CHANGE_ME_Accountant'
)

foreach ($scriptName in $scripts) {
    $scriptPath = Join-Path $scriptDirectory $scriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Không tìm thấy script bắt buộc: $scriptPath"
    }

    Write-Host "Running $scriptName on $Server / $DatabaseName..."
    & $sqlcmd.Source -S $Server -E -b -r 1 -i $scriptPath -v $sqlVariables
    if ($LASTEXITCODE -ne 0) {
        throw "Script $scriptName thất bại với exit code $LASTEXITCODE."
    }
}

Write-Host "TV1 database setup and smoke tests completed successfully." -ForegroundColor Green
